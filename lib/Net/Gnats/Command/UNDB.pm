package Net::Gnats::Command::UNDB;
use parent 'Net::Gnats::Command';
use strictures;
use Net::Gnats::Constants qw(CODE_OK CODE_GNATS_NOT_LOCKED CODE_CMD_ERROR);

=head1 NAME

Net::Gnats::Command::UNDB

=head1 DESCRIPTION

Unlocks the database. Any session may steal a database lock; no
checking of any sort is done.

=head1 RESPONSES

The possible responses are:

200 (CODE_OK) The lock has been removed.

432 (CODE_GNATS_NOT_LOCKED) The database was not locked.

440 (CODE_CMD_ERROR) One or more arguments were supplied to the
command.

6xx (internal error) The database lock could not be removed, usually
because of permissions or other filesystem-related issues.

=cut

my $c = 'UNDB';

sub new {
  my ( $class, %options ) = @_;

  my $self = bless {}, $class;
  return $self;
}

1;
