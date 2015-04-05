package Net::Gnats::Command::APPN;
use parent 'Net::Gnats::Command';
use strictures;
use Net::Gnats::Constants qw(CODE_OK CODE_NONEXISTENT_PR CODE_INVALID_FIELD_NAME
                             CODE_UNREADABLE_PR CODE_GNATS_LOCKED CODE_LOCKED_PR
                             CODE_INVALID_FIELD_CONTENTS);

=head1 NAME

Net::Gnats::Command::APPN

=head1 DESCRIPTION

Appends to or replaces the contents of field in PR with the supplied
text. The command returns a 201 (CODE_SEND_TEXT) response; the
client should then transmit the new field contents using the
standard PR quoting mechanism. After the server has read the new
contents, it then attempts to make the requested change to the PR.

=head1 RESPONSES

The possible responses are:

200 (CODE_OK) The PR field was successfully changed.

400 (CODE_NONEXISTENT_PR) The PR specified does not exist.

410 (CODE_INVALID_FIELD_NAME) The specified field does not exist.

402 (CODE_UNREADABLE_PR) The PR could not be read.

431 (CODE_GNATS_LOCKED) The database has been locked, and no PRs may
be updated until the lock is cleared.

430 (CODE_LOCKED_PR) The PR is locked, and may not be altered until
    the lock is cleared.

413 (CODE_INVALID_FIELD_CONTENTS) The supplied (or resulting) field
    contents are not valid for the field.

6xx (internal error) An internal error occurred, usually because of
permission or other filesystem-related problems. The PR may or may
not have been altered.

=cut
  

my $c = 'APPN';

sub new {
  my ( $class, %options ) = @_;

  my $self = bless {}, $class;
  return $self;
}

1;
