package Net::Gnats::Command::FDSC;
use parent 'Net::Gnats::Command';
use strictures;
use Net::Gnats::Constants qw(CODE_INFORMATION CODE_INVALID_FIELD_NAME);

=head1 NAME

Net::Gnats::Command::FDSC

=head1 DESCRIPTION

Returns a human-readable description of the listed field(s). The possible responses are:

Like the FVLD command, the standard continuation protocol will be
used if multiple fields were specified with the command.

=head1 PROTOCOL

 FDSC [fields...]

=head1 RESPONSES

350 (CODE_INFORMATION)

The normal response; the supplied text is the field description.

410 (CODE_INVALID_FIELD_NAME)

The specified field does not exist.

=cut

my $c = 'FDSC';

sub new {
  my ( $class, %options ) = @_;
  my $self = bless \%options, $class;
  $self->{requests_multi} = 0;
  if (ref $self->{fields} eq 'ARRAY') {
    $self->{requests_multi} = 1 if scalar @{ $self->{fields} } > 1;
  }
  else {
    $self->{fields} = [ $self->{fields} ];
  }
  return $self;
}

sub as_string {
  my ($self) = @_;
  return $c . ' ' . join ( ' ', @{$self->{fields}} );
}

# this command can take multiple fields, each getting their own response.
# so, we check that 'everything' is okay by looking at the parent response.
sub is_ok {
  my $self = shift;
  if ( $self->{requests_multi} == 0 and
       $self->response->code == CODE_INFORMATION) {
    return 1;
  }
  return 0;
}

1;
