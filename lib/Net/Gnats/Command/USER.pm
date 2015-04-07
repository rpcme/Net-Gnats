package Net::Gnats::Command::USER;
use parent 'Net::Gnats::Command';
use strictures;
use Net::Gnats::Constants qw(CODE_INFORMATION CODE_NO_ACCESS CODE_OK);

=head1 NAME

Net::Gnats::Command::USER

=head1 DESCRIPTION

Specifies the userid and password for database access. Either both a
username and password must be specified, or they both may be
omitted; in the latter case, the current access level is returned.

=head1 PROTOCOL

 USER <User ID> <Password>

=head1 RESPONSES

The possible server responses are:

350 (CODE_INFORMATION) The current access level is specified.

422 (CODE_NO_ACCESS) A matching username and password could not be
found.

200 (CODE_OK) A matching username and password was found, and the
login was successful.

=cut

my $c = 'USER';

sub new {
  my ( $class, %options ) = @_;

  my $self = bless \%options, $class;
  return $self;
}

sub as_string {
  my ( $self ) = @_;
  return  $c . ' ' . $self->{username} . ' ' . $self->{password};
}

sub is_ok {
  my ($self) = @_;
  return 0 if $self->response->code == CODE_NO_ACCESS;
  return 1;
}

1;
