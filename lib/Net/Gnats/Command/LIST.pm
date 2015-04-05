package Net::Gnats::Command::LIST;
use parent 'Net::Gnats::Command';
use strictures;
use Net::Gnats::Constants qw(CODE_TEXT_READY CODE_INVALID_LIST);

=head1 NAME

Net::Gnats::Command::LIST

=head1 DESCRIPTION


Describes various aspects of the database. The lists are returned as
a list of records, one per line. Each line may contain a number of
colon-separated fields.

Possible values for list type include

Categories  : Describes the legal categories for the database.

Submitters  : Describes the set of submitters for the database.

Responsible : Lists the names in the responsible administrative
file, including their full names and email addresses.

States

Lists the states listed in the state administrative file, including
the state type (usually blank for most states; the closed state has
a special type).

FieldNames Lists the entire set of PR fields.

InitialInputFields : Lists the fields that should be present when a
PR is initially entered.

InitialRequiredFields : Lists fields that have to be present and
nonempty when a PR is initially entered (fields containing only
blank characters such as spaces or newlines are considered empty.)

Databases : Lists the set of databases.

=head1 RESPONSES

The possible responses are:

301 (CODE_TEXT_READY) Normal response, followed by the records
making up the list as described above.

416 (CODE_INVALID_LIST) The requested list does not exist.

=cut

my $c = 'LIST';

sub new {
  my ( $class, %options ) = @_;

  my $self = bless {}, $class;
  return $self;
}

1;
