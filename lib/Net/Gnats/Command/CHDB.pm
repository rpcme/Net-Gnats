package Net::Gnats::Command::CHDB;
use parent 'Net::Gnats::Command';
use strictures;
use Net::Gnats::Constants qw(CODE_OK CODE_NO_ACCESS CODE_INVALID_DATABASE);

=head1 NAME

Net::Gnats::Command::CHDB

=head1 DESCRIPTION

Switches the current database to the name specified in the command.

=head1 RESPONSES

The possible responses are:

422 (CODE_NO_ACCESS)

The user does not have permission to access the requested database.

417 (CODE_INVALID_DATABASE)

The database specified does not exist, or one or more configuration
errors in the database were encountered.

220 (CODE_OK)

The current database is now database. Any operations performed will
now be applied to database.

=cut

my $c = 'CHDB';

sub new {
  my ( $class, %options ) = @_;

  my $self = bless {}, $class;
  return $self;
}

1;
