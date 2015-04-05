package Net::Gnats::Command::UNLK;
use parent 'Net::Gnats::Command';
use strictures;
use Net::Gnats::Constants qw(CODE_OK CODE_PR_NOT_LOCKED);

=head1 NAME

Net::Gnats::Command::UNLK

=head1 DESCRIPTION


Unlocks PR. Any user may unlock a PR, as no checking is done to
determine if the requesting session owns the lock.

=head1 RESPONSES


The possible responses are:

440 (CODE_CMD_ERROR)

Insufficient or too many arguments were specified to the command.

200 (CODE_OK)

The PR was successfully unlocked.

433 (CODE_PR_NOT_LOCKED)

The PR was not locked.

6xx (internal error)

The PR could not be unlocked, usually because of permission or other
filesystem-related problems.

=cut

my $c = 'UNLK';

sub new {
  my ( $class, %options ) = @_;

  my $self = bless {}, $class;
  return $self;
}

1;
