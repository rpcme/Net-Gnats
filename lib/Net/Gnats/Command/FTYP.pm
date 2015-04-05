package Net::Gnats::Command::FTYP;
use parent 'Net::Gnats::Command';
use strictures;
use Net::Gnats::Constants qw(CODE_INFORMATION CODE_INVALID_FIELD_NAME);

=head1 NAME

Net::Gnats::Command::FTYP

=head1 DESCRIPTION


Describes the type of data held in the field(s) specified with the
command.

If multiple field names were given, multiple response lines will be
sent, one for each field, using the standard continuation protocol;
each response except the last will have a dash - immedately after
the response code.

The currently defined data types are:

Text

A plain text field, containing exactly one line.

MultiText

A text field possibly containing multiple lines of text.

Enum

An enumerated data field; the value is restricted to one entry out
of a list of values associated with the field.

MultiEnum

The field contains one or more enumerated values. Values are
separated with spaces or colons :.

Integer

The field contains an integer value, possibly signed.

Date

The field contains a date.

TextWithRegex

The value in the field must match one or more regular expressions
associated with the field.

=head1 RESPONSES

The possible responses are:

350 (CODE_INFORMATION)

The normal response; the supplied text is the data type.

410 (CODE_INVALID_FIELD_NAME)

The specified field does not exist.

=cut


my $c = 'FTYP';

sub new {
  my ( $class, %options ) = @_;

  my $self = bless {}, $class;
  return $self;
}

1;

