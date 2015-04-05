package Net::Gnats::Command::FDSC;
use parent 'Net::Gnats::Command';
use strictures;
use Net::Gnats::Constants qw(CODE_INFORMATION CODE_INVALID_FIELD_NAME);

=head1 NAME

Net::Gnats::Command::FDSC

=head1 DESCRIPTION

Returns a human-readable description of the listed field(s). The possible responses are:

Like the FVLD command, the standard continuation protocol will be
used if multiple fields were specified with the command.

=head1 RESPONSES

350 (CODE_INFORMATION)

The normal response; the supplied text is the field description.

410 (CODE_INVALID_FIELD_NAME)

The specified field does not exist.

=cut

my $c = 'FDSC';

sub new {
  my ( $class, %options ) = @_;

  my $self = bless {}, $class;
  return $self;
}

1;
