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
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.02';




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
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Net::Gnats - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Net::Gnats;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Net::Gnats, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.


=head1 AUTHOR

A. U. Thor, a.u.thor@a.galaxy.far.far.away

=head1 SEE ALSO

perl(1).

=cut
