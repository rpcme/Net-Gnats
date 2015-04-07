package Net::Gnats::Field;
use strictures;

=head1 NAME

Net::Gnats::Field

=head1 DESCRIPTION

Base class for a PR's metadata

In a given session, for a given field, this should have to be run once
and stashed somewhere for reuse.

=head1 EXAMPLES

Construct an empty field

 my $f = Net::Gnats::Field->new;

Initialize from server

 my $f = Net::Gnats::Field->new( name => 'myfield' )->initialize($session);

Manual initialization

 my $f = Net::Gnats::Field
   ->new( name => 'myfield',
          description => 'description',
          type => type,
          default => default,
          flags => flags,
          validators => validators );

=cut

sub new {
  my ( $class, %o ) = @_;
  return bless {}, $class if not %o;
  return bless \%o, $class;
}

sub name {
  my ( $self, $value ) = @_;
  $self->{name} = $value if defined $value;
  $self->{name};
}

sub description {
  my ( $self, $value ) = @_;
  $self->{description} = $value if defined $value;
  $self->{description};
}

sub type {
  my ( $self, $value ) = @_;
  $self->{type} = $value if defined $value;
  $self->{type};
}

sub default {
  my ( $self, $value ) = @_;
  $self->{default} = $value if defined $value;
  $self->{default};
}

sub flags {
  my ( $self, $value ) = @_;
  $self->{flags} = $value if defined $value;
  $self->{flags};
}

sub validators {
  my ( $self, $value ) = @_;
  $self->{validators} = $value if defined $value;
  $self->{validators};
}

=head1 METHODS

=head2 initialize

=cut

sub initialize {
  my ( $self ) = @_;
}

=head2 instance

Creates an instance of this meta field.  Represents a literal field in a PR.

=cut

sub instance { ... }

1;
