package Net::Gnats::Command::EDITADDR;
use parent 'Net::Gnats::Command';
use strictures;
use Net::Gnats::Constants qw(CODE_OK CODE_CMD_ERROR);

=head1 NAME

Net::Gnats::Command::EDITADDR

=head1 DESCRIPTION

Sets the e-mail address of the person communicating with gnatsd. The
command requires at least the edit access level.

=head1 PROTOCOL

 EDITADDR [address]

=head1 RESPONSES

The possible responses are:

200 (CODE_OK)
The address was successfully set.

440 (CODE_CMD_ERROR)
Invalid number of arguments were supplied.

=cut


my $c = 'EDITADDR';

sub new {
  my ( $class, %options ) = @_;

  my $self = bless {}, $class;
  return $self;
}

1;
