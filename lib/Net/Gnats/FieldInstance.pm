package Net::Gnats::FieldInstance;
use strictures;

sub new {
  my ($class, %options) = @_;
  return bless \%options, $class;
}

sub name {
  my ($self) = @_;
  $self->{name} = $self->schema->name if not defined $self->{value};
  $self->{name};
}

sub value {
  my ($self, $value) = @_;
  $self->{value} = $self->schema->default if not defined $self->{value};
  $self->{value} = $value if defined $value;
  $self->{value};
}

sub schema { return shift->{schema} }

1;
