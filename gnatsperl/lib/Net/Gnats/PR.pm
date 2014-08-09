package Net::Gnats::PR;

require 5.005_62;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader qw(AUTOLOAD);
#use Data::Dumper;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::Gnats ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );


# TODO: These came from gnatsweb.pl for the parsepr and unparsepr routines.
# should be done a better way?
my $UNFORMATTED_FIELD = 'Unformatted';
my $SYNOPSIS_FIELD = 'Synopsis';
my $ORIGINATOR_FIELD = 'Originator';
my $attachment_delimiter = "----gnatsweb-attachment----\n";
my $SENDINCLUDE  = 1;   # whether the send command should include the field
our $REVISION = '$Id$'; #'

#******************************************************************************
# Sub: new
# Description: Constructor
# Args: hash (parameter list) 
# Returns: self
#******************************************************************************
sub new 
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless($self, $class);

    $self->{__gnatsObj} = shift;
    $self->{number} = undef;
    $self->{fields} = undef;
    confess "? Error: Must pass Net::Gnats object as first argument to $proto"
      if (not defined $self->{__gnatsObj});
    return $self;
}

sub setField {
    my $self = shift;
    my $field = shift;
    my $value = shift;
    my $reason = shift;
    $self->{fields}->{$field} = $value;
    $self->{fields}->{$field."-Changed-Why"} = $reason
      if (defined($reason)); # TODO: Anyway to find out if requireChangeReason?
}
sub getField {
    my $self = shift;
    my $field = shift;
    return $self->{fields}->{$field};
}
# This is legacy...
sub getNumber {
  return $_[0]->getField("Number");
}
sub getKeys {
    my $self = shift;
    return keys(%{$self->{fields}});
}

sub asHash {
    my $self = shift;
    return %{$self->{fields}} if defined($self->{fields}); #XXX Deep copy?
    return undef;
}

# This return remains, sine it was in the examples.
sub asString {
  my $self = shift;
  return $self->unparse(@_);
}

# Split comma-separated list.
# Commas in quotes are not separators!
sub split_csl
{
  my ($list) = @_;
  
  # Substitute commas in quotes with \002.
  while ($list =~ m~"([^"]*)"~g)
  {
    my $pos = pos($list);
    my $str = $1;
    $str =~ s~,~\002~g;
    $list =~ s~"[^"]*"~"$str"~;
		 pos($list) = $pos;
  }

  my @res;
  foreach my $person (split(/\s*,\s*/, $list))
  {
    $person =~ s/\002/,/g;
    push(@res, $person) if $person;
  }
  return @res;
}

# fix_email_addrs -
#     Trim email addresses as they appear in an email From or Reply-To
#     header into a comma separated list of just the addresses.
#
#     Delete everything inside ()'s and outside <>'s, inclusive.
#
sub fix_email_addrs
{
  my $addrs = shift;
  my @addrs = split_csl ($addrs);
  my @trimmed_addrs;
  my $addr;
  foreach $addr (@addrs)
  {
    $addr =~ s/\(.*\)//;
    $addr =~ s/.*<(.*)>.*/$1/;
    $addr =~ s/^\s+//;
    $addr =~ s/\s+$//;
    push(@trimmed_addrs, $addr);
  }
  $addrs = join(', ', @trimmed_addrs);
  $addrs;
}

sub parse
{
  my $self = shift;
  # 9/18/99 kenstir: This two-liner can almost replace the next 30 or so
  # lines of code, but not quite.  It strips leading spaces from multiline
  # fields.
  #my $prtext = join("\n", @_);
  #my(%fields) = ('envelope' => split /^>(\S*?):\s*/m, $prtext);
  #  my $prtext = join("\n", @_);
  #  my(%fields) = ('envelope' => split /^>(\S*?):(?: *|\n)/m, $prtext);

  my $debug = 0;

  my($hdrmulti) = "envelope";
  my(%fields);
  foreach (@_)
  {
    next if /^300 PRs follow./;
    chomp($_);
    $_ .= "\n";
    if(!/^([>\w\-]+):\s*(.*)\s*$/)
    {
      if($hdrmulti ne "")
      {
        $fields{$hdrmulti} .= $_;
      }
      next;
    }
    my ($hdr, $arg, $ghdr) = ($1, $2, "*not valid*");
    if($hdr =~ /^>(.*)$/)
    {
      $ghdr = $1;
    }

    my $cleanhdr = $ghdr;
    $cleanhdr =~ s/^>([^:]*).*$/$1/;

    if($self->{__gnatsObj}->isValidField($cleanhdr))
    {
      if($self->{__gnatsObj}->getFieldType($cleanhdr) eq 'MultiText')
      {
        $hdrmulti = $ghdr;
        $fields{$ghdr} = "";
      }
      else
      {
        $hdrmulti = "";
        $fields{$ghdr} = $arg;
      }
    }
    elsif($hdrmulti ne "")
    {
      $fields{$hdrmulti} .= $_;
    }

    # Grab a few fields out of the envelope as it flies by
    # 8/25/99 ehl: Grab these fields only out of the envelope, not
    # any other multiline field.
    if($hdrmulti eq "envelope" &&
       ($hdr eq "Reply-To" || $hdr eq "From"))
    {
      $arg = fix_email_addrs($arg); # TODO: Should we really do this?
      $fields{$hdr} = $arg;
      #print "storing, hdr = $hdr, arg = $arg\n";
    }
  }

  # 5/8/99 kenstir: To get the reporter's email address, only
  # $fields{'Reply-to'} is consulted.  Initialized it from the 'From'
  # header if it's not set, then discard the 'From' header.
  $fields{'Reply-To'} = $fields{'Reply-To'} || $fields{'From'};
  delete $fields{'From'};

  # Ensure that the pseudo-fields are initialized to avoid perl warnings.
  $fields{'X-GNATS-Notify'} ||= '';

  # 3/30/99 kenstir: For some reason Unformatted always ends up with an
  # extra newline here.
  $fields{$UNFORMATTED_FIELD} ||= ''; # Default to empty value
  $fields{$UNFORMATTED_FIELD} =~ s/\n$//;

  # Decode attachments stored in Unformatted field.
  my $any_attachments = 0;
  if (can_do_mime()) {
    my(@attachments) = split(/$attachment_delimiter/, $fields{$UNFORMATTED_FIELD});
    # First element is any random text which precedes delimited attachments.
    $fields{$UNFORMATTED_FIELD} = shift(@attachments);
    foreach my $attachment (@attachments) {
      warn "att=>$attachment<=\n" if $debug;
      $any_attachments = 1;
      # Strip leading spaces on each line of the attachment
      $attachment =~ s/^[ ]//mg;
      add_decoded_attachment_to_pr(\%fields, decode_attachment($attachment));
    }
  }

  #return %fields;
  foreach my $field (keys %fields) {
    $fields{$field} =~ s/\r// if defined($fields{$field});
    $self->setField($field,$fields{$field})
  }

}


# Return true if module MIME::Base64 is available.  If available, it's
# loaded the first time this sub is called.
my $can_do_mime = 0;
sub can_do_mime {

  return $can_do_mime if (defined($can_do_mime));

  eval 'use MIME::Base64;';
  if ($@) {
    warn "NOTE: Can't use file upload feature without MIME::Base64 module\n";
      $can_do_mime = 0;
  } else {
    $can_do_mime = 1;
  }
  $can_do_mime;
}

# unparse -
#     Turn PR fields hash into a multi-line string.
#
#     The $purpose arg controls how things are done.  The possible values
#     are:
#         'gnatsd'  - PR will be filed using gnatsd; proper '.' escaping done
#         'send'    - PR will be field using gnatsd, and is an initial PR.
#         'test'    - we're being called from the regression tests
sub unparse
{
  #my($purpose, %fields) = @_;
  my $self = shift;
  my $purpose = shift;
  $purpose ||= 'gnatsd';
  my($tmp, $text);
  my $debug = 0;

  # First create or reconstruct the Unformatted field containing the
  # attachments, if any.
  my %fields = %{$self->{fields}};
  $fields{$UNFORMATTED_FIELD} ||= ''; # Default to empty.
  warn "unparsepr 1 =>$fields{$UNFORMATTED_FIELD}<=\n" if $debug;
  my $array_ref = $fields{'attachments'};
  foreach my $hash_ref (@$array_ref) {
    my $attachment_data = $$hash_ref{'original_attachment'};
    # Deleted attachments leave empty hashes behind.
    next unless defined($attachment_data);
    $fields{$UNFORMATTED_FIELD} .= $attachment_delimiter . $attachment_data . "\n";
  }
  warn "unparsepr 2 =>$fields{$UNFORMATTED_FIELD}<=\n" if $debug;

  # Reconstruct the text of the PR into $text.
  # Build the envelope if necessary.
  if (exists $fields{'envelope'}) {
    $text = $fields{'envelope'};
  } else {
    $text = "To: bugs
CC:
Subject: $fields{$SYNOPSIS_FIELD}
From: $fields{$ORIGINATOR_FIELD}
Reply-To: $fields{$ORIGINATOR_FIELD}
X-Send-Pr-Version: Net::Gnats-$Net::Gnats::VERSION ($REVISION)

";
  }

  foreach ($self->{__gnatsObj}->listFieldNames())
  {
    next if /^.$/;
    next if (not defined($fields{$_})); # Don't send fields that aren't defined.
    # Do include Unformatted field in 'send' operation, even though
    # it's excluded.  We need it to hold the file attachment.
    # XXX ??? !!! FIXME
    if(($purpose eq 'send')
       && (! ($self->{__gnatsObj}->getFieldTypeInfo ($_, 'flags') & $SENDINCLUDE))
       && ($_ ne $UNFORMATTED_FIELD))
    {
      next;
    }
    $fields{$_} ||= ''; # Default to empty
    if($self->{__gnatsObj}->getFieldType($_) eq 'MultiText')
    {
      # Lines which begin with a '.' need to be escaped by another '.'
      # if we're feeding it to gnatsd.
      $tmp = $fields{$_};
      $tmp =~ s/\r//;
      $tmp =~ s/^[.]/../gm
            if ($purpose ne 'test');
      chomp($tmp);
      $tmp .= "\n" if ($tmp ne ""); # Make sure it ends with newline.
      $text .= sprintf(">$_:\n%s", $tmp);
    }
    else
    {
      # Format string derived from gnats/pr.c.
      $text .= sprintf("%-16s %s\n", ">$_:", $fields{$_});
    }
    if (exists ($fields{$_."-Changed-Why"}))
    {
      # Lines which begin with a '.' need to be escaped by another '.'
      # if we're feeding it to gnatsd.
      $tmp = $fields{$_."-Changed-Why"};
      $tmp =~ s/^[.]/../gm
            if ($purpose ne 'test');
      $text .= sprintf(">$_-Changed-Why:\n%s\n", $tmp);
    }
  }
  $text =~ s/\r//;
  return $text;
}


# preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Net::Gnats::PR - Represents a Gnats PR.

=head1 SYNOPSIS

  use Net::Gnats;
  my $g = Net::Gnats->new();
  $g->connect();
  my @dbNames = $g->getDBNames();
  $g->login("default","somedeveloper","password");
  my $PRtwo = $g->getPRByNumber(2);
  print $PRtwo->asString();
  my $newPR = Net::Gnats::PR->new();
  $newPR->setField("Submitter-Id","developer");
  $g->submitPR($newPR);
  $g->disconnect();


=head1 DESCRIPTION

Net::Gnats::PR models a GNU Gnats PR (Problem Report).  The module allows
proper formatting and parsing of PRs through an object oriented interface.

The current version of Net::Gnats (as well as related information) is 
available at http://gnatsperl.sourceforge.net/

=head1 COMMON TASKS


=head2 CREATING A NEW PR

The Net::Gnats::PR object acts as a container object to store information
about a PR (new or otherwise).  A new PR is submitted to gnatsperl by 
constructing a PR object.

  my $newPR = Net::Gnats::PR->new();
  $newPR->setField("Submitter-Id","developer");
  $newPR->setField("Originator","Doctor Wifflechumps");
  $newPR->setField("Organization","GNU");
  $newPR->setField("Synopsis","Some bug from perlgnats");
  $newPR->setField("Confidential","no");
  $newPR->setField("Severity","serious");
  $newPR->setField("Priority","low");
  $newPR->setField("Category","gnatsperl");
  $newPR->setField("Class","sw-bug");
  $newPR->setField("Description","Something terrible happened");
  $newPR->setField("How-To-Repeat","Like this.  Like this.");
  $newPR->setField("Fix","Who knows");

Obviously, fields are dependent on a specific gnats installation, since 
Gnats administrators can rename fields and add constraints.  


=head2 CREATING A NEW PR OBJECT FROM A PREFORMATTED PR STRING 

Instead of setting each field of the PR individually, the setFromString()
method is available.  The string that is passed to it must be formatted
in the way Gnats handles the PRs (i.e. the '>Field: Value' format.  You can
see this more clearly by looking at the PR files of your Gnats installation).
This is useful when handling a Gnats email submission 
($newPR->setFromString($email)) or when reading a PR file directly from the 
database.  


=head1 METHOD DESCRIPTIONS


=head2 new()

Constructor, no arguments.

=head2 setField()

Sets a gnats field value.  Expects two arguments: the field name followed by
the field value.

=head2 getField()

Returns the string value of a PR field.

=head2 getNumber()

Returns the gnats PR number. In previous versions of gnatsperl the Number field was
explicitly known to Net::Gnats::PR.  This method remains for backwards compatibility.

=head2 asHash()

Returns the PR formatted as a hash.  The returned hash contains field names
as keys, and the corresponding field values as hash values.

=head2 getKeys()

Returns the list of PR fields contained in the object.  


=head2 asString()

Returns the PR object formatted as a Gnats recongizable string.  The result
is suitable for submitting to Gnats.

=head2 setFromString()

Parses a Gnats formatted PR and sets the object's fields accordingly.





=head1 BUGS

Bug reports are very welcome.  Please submit to the project page 
(noted below).


=head1 AUTHOR

Mike Hoolehan, <lt>mike@sycamore.us<gt>
Project hosted at sourceforge, at http://gnatsperl.sourceforge.net



=head1 COPYRIGHT

Copyright (c) 1997-2001, Mike Hoolehan. All Rights Reserved.
This module is free software. It may be used, redistributed,
and/or modified under the same terms as Perl itself.


=cut

