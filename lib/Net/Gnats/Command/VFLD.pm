package Net::Gnats::Command::VFLD;
use parent 'Net::Gnats::Command';
use strictures;
use Net::Gnats::Constants qw(CODE_SEND_TEXT CODE_INVALID_FIELD_NAME);

=head1 NAME

Net::Gnats::Command::VFLD

=head1 DESCRIPTION

VFLD can be used to validate a given value for a field in the
database. The client issues the VFLD command with the name of the
field to validate as an argument. The server will either respond
with 212 (CODE_SEND_TEXT), or 410 (CODE_INVALID_FIELD_NAME) if the
specified field does not exist.

Once the 212 response is received from the server, the client should
then send the line(s) of text to be validated, using the normal
quoting mechanism described for PRs. The final line of text is
followed by a line containing a single period, again as when sending
PR text.

The server will then either respond with 210 (CODE_OK), indicating
that the text is acceptable, or one or more error codes describing
the problems with the field contents.

=head1 PROTOCOL

 VFLD <Field>
 <Field contents>

=head1 RESPONSES

CODE_SEND_TEXT
CODE_INVALID_FIELD_NAME

=cut

my $c = 'VFLD';

sub new {
  my ( $class, %options ) = @_;

  my $self = bless {}, $class;
  return $self;
}

1;
