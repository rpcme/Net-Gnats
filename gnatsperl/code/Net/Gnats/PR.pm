package Net::Gnats::PR;

require 5.005_62;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

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

    $self->{number} = undef;
    $self->{fields} = undef;

    return $self;
}


#the only field we'll track specifically
sub setNumber { 
    my $self = shift; 
    $self->{number} = shift; 
}
sub getNumber { 
    my $self = shift; 
    return $self->{number};
}


sub setField {
    my $self = shift; 
    my $field = shift; 
    my $value = shift;
    $self->{fields}->{$field}=$value;
}
sub getField {
    my $self = shift;
    my $field = shift;
    return $self->{fields}->{$field};
}

sub getKeys {
    my $self = shift;
    return keys(%{$self->{fields}});
}

sub asHash {
    my $self = shift;
    return %{$self->{fields}}; #XXX Deep copy?
}

sub asString {
    my $self = shift;
    my $stringRep="";

    if (defined $self->getNumber() ) { # number first if exists
        $stringRep.=">Number: ".$self->getNumber()."\n";
    }
    foreach my $key (keys %{$self->{fields}}) {
        $stringRep .=">$key: ".$self->{fields}->{$key}."\n";
    }
    return $stringRep;
}

sub setFromString {
    my $self = shift;
    my $PRstring = shift;


    my @byFields = split /^>/m, $PRstring;
    
    my $containsNumber = grep (/^Number/, @byFields);

    #get rid of lines  precedeing Number
    if ($containsNumber) {
        while ($byFields[0] !~ /^Number/ ) {
            #print "Dropping line |".$byFields[0]."|\n";
            shift @byFields;
        }
    }
    
    foreach my $line (@byFields) {
        #extract field name and value
       if ($line =~ /^(\S*)\:(\s|\n)*(.*)\X*$/ms) {
            my $field = $1;
            my $val = $3;
                #get rid of trailing cr/lf
            if ($val =~ /(.*)\015\012$/ms) {
                $val = $1;
            }
            #print "setting |$field| with |$val|\n";
            if ($field eq 'Number') {  #XXX TODO don't hard code
                $self->setNumber($val);
            } else {
                $self->setField($field, $val);
            }
        }    
    }        
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

=head2 setNumber()

Sets the gnats PR number. This is the only field name explicitly known
to Net::Gnats::PR.  Provide PR number as sole argument.

=head2 getNumber()

Returns the gnats PR number. This is the only field name explicitly known
to Net::Gnats::PR.  

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

