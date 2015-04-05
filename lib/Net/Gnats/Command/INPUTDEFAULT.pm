package Net::Gnats::Command::INPUTDEFAULT;
use parent 'Net::Gnats::Command';
use strictures;
use Net::Gnats::Constants qw(CODE_INFORMATION CODE_INVALID_FIELD_NAME);

=head1 NAME

Net::Gnats::Command::INPUTDEFAULT

=head1 DESCRIPTION

Like the FDSC and FTYP commands, multiple field names may be listed
with the command, and a response line will be returned for each one
in the order that the fields appear on the command line.

=head1 RESPONSES

Returns the suggested default value for a field when a PR is
initially created. The possible responses are either 410
(CODE_INVALID_FIELD_NAME), meaning that the specified field is
invalid or nonexistent, or 350 (CODE_INFORMATION) which contains the
default value for the field.

=cut

my $c = 'INPUTDEFAULT';

sub new {
  my ( $class, %options ) = @_;

  my $self = bless {}, $class;
  return $self;
}

1;
