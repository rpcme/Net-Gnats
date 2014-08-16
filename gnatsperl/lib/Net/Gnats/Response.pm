package Net::Gnats::Response;
use 5.010_000;
use utf8;
use strict;
use warnings;
our $VERSION = '0.10';

# see perldoc for documentation
sub new {
  my ($class, $param) = @_;
  my $self = bless {}, $class;
  $self->{raw} = defined $param->{raw} ? $param->{raw} : undef;
  $self->{code} = defined $param->{code} ? $param->{code} : undef;
  return $self;
}

# see perldoc for documentation
sub raw {
  my ($self, $value) = @_;
  if (defined $value) { $self->{raw} = $value; }
  return $self->{raw};
}

# see perldoc for documentation
sub code {
  my ($self, $value) = @_;
  if (defined $value) { $self->{code} = $value; }
  return $self->{code};
}

# see perldoc for documentation
sub as_list {
  my ($self) = @_;
  my $tmp = $self->raw;
  $tmp =~ s/\r//gsxm;
  my @lines = split /\n/sxm, $tmp;
  shift @lines; # first item is the response message

  return \@lines;
}

# see perldoc for documentation
sub as_string {
  my ( $self ) = @_;
  return join "\n", @{ $self->raw };
}

1;

__END__

=encoding utf8

=head1 NAME

Net::Gnats::Response - A Gnats payload class.

=head1 VERSION

0.11

=head1 DESCRIPTION

For dealing with raw responses and error codes returned by
Gnatsd. Enables an easier payload method.

=head1 SYNOPSIS

  use Net::Gnats::Reponse;

  # Compose payload via constructor
  my $response = Net::Gnats::Response->new({ raw => $data,
                                             code => $code});

  # Compose disparately
  my $response = Net::Gnats::Response->new;
  $response->raw($data);
  $response->code($code);

=head1 INCOMPATIBILITIES

None.

=head1 SUBROUTINES/METHODS

=over

=item new()

Constructor for the Response object.

=item raw()

Accessor for raw result data.

=item $response->code()

Accessor for the result code.

=item $response->as_list()

Assumes the Gnatsd payload response is a 'list' and parses it as so.

Returns: Anonymous array of list items.

=item $response->as_string()

=back

=head1 DIAGNOSTICS

None.

=head1 BUGS AND LIMITATIONS

None.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 DEPENDENCIES

None.

=head1 AUTHOR

Richard Elberger, riche@cpan.org

=head1 LICENSE AND COPYRIGHT

License: GPL V3

(c) 2014 Richard Elberger
