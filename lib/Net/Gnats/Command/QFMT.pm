package Net::Gnats::Command::QFMT;
use parent 'Net::Gnats::Command';
use strictures;
use Net::Gnats::Constants qw(CODE_OK CODE_CMD_ERROR CODE_INVALID_QUERY_FORMAT);

=head1 NAME

Net::Gnats::Command::QFMT

=head1 DESCRIPTION

Use the specified query format to format the output of the QUER
command. The query format may be either the name of a query format
known to the server (see Named query definitions), or an actual
query format (see Formatting query-pr output).

=head1 RESPONSES

The possible
responses are:

200 (CODE_OK) The normal response, which indicates that the query
    format is acceptable.

440 (CODE_CMD_ERROR) No query format was supplied.

418 (CODE_INVALID_QUERY_FORMAT) The specified query format does not
    exist, or could not be parsed.

=cut

my $c = 'QFMT';

sub new {
  my ( $class, %options ) = @_;

  my $self = bless {}, $class;
  return $self;
}

1;