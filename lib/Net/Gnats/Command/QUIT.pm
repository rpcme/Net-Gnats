package Net::Gnats::Command::QUIT;
use parent 'Net::Gnats::Command';
use strictures;
use Net::Gnats::Constants qw(CODE_CLOSING);

=head1 NAME

QUIT

=head1 DESCRIPTION

Requests that the connection be closed.

The QUIT command has the dubious distinction of being the only
command that cannot fail.

=head1 RESPONSES

Possible responses:
201 (CODE_CLOSING) Normal exit.

=cut

my $c = 'QUIT';

sub new {
  my ( $class, %options ) = @_;

  my $self = bless {}, $class;
  return $self;
}

sub send_command {
  my ( $self ) = @_;
  $self->{RESPONSE} = $self->SUPER::send_command($c);
  return $self;
}


1;
