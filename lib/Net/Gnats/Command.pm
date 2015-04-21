package Net::Gnats::Command;
use utf8;
use strictures;

BEGIN {
  $Net::Gnats::VERSION = '0.16';
}
use vars qw($VERSION);

use Net::Gnats::Response;
use Net::Gnats::Command::ADMV;
use Net::Gnats::Command::APPN;
use Net::Gnats::Command::CHDB;
use Net::Gnats::Command::CHEK;
use Net::Gnats::Command::DBLS;
use Net::Gnats::Command::DBDESC;
use Net::Gnats::Command::DELETE;
use Net::Gnats::Command::EDIT;
use Net::Gnats::Command::EDITADDR;
use Net::Gnats::Command::EXPR;
use Net::Gnats::Command::FDSC;
use Net::Gnats::Command::FIELDFLAGS;
use Net::Gnats::Command::FTYP;
use Net::Gnats::Command::FTYPINFO;
use Net::Gnats::Command::FVLD;
use Net::Gnats::Command::INPUTDEFAULT;
use Net::Gnats::Command::LIST;
use Net::Gnats::Command::LKDB;
use Net::Gnats::Command::LOCK;
use Net::Gnats::Command::QFMT;
use Net::Gnats::Command::QUER;
use Net::Gnats::Command::REPL;
use Net::Gnats::Command::RSET;
use Net::Gnats::Command::SUBM;
use Net::Gnats::Command::UNDB;
use Net::Gnats::Command::UNLK;
use Net::Gnats::Command::USER;
use Net::Gnats::Command::VFLD;
use Net::Gnats::Command::QUIT;

=head1 NAME

Net::Gnats::Command

Encapsulates all Gnats Daemon commands and their command processing
codes.

This module implements the factory pattern for retrieving specific
commands.

=cut

our @EXPORT_OK =
  qw(admv appn chdb chek dbdesc dbls delete_pr edit editaddr expr fdsc
     fieldflags ftyp ftypinfo fvld inputdefault list lkdb lock_pr qfmt
     quer quit repl rset subm undb unlk user vfld);

sub admv          { shift; return Net::Gnats::Command::ADMV->new( @_ ); }
sub appn          { shift; return Net::Gnats::Command::APPN->new( @_ ); }
sub chdb          { shift; return Net::Gnats::Command::CHDB->new( @_ ); }
sub chek          { shift; return Net::Gnats::Command::CHEK->new( @_ ); }
sub dbls          { shift; return Net::Gnats::Command::DBLS->new( @_ ); }
sub dbdesc        { shift; return Net::Gnats::Command::DBDESC->new( @_ ); }
sub delete_pr    { shift; return Net::Gnats::Command::DELETE->new( @_ ); }
sub edit          { shift; return Net::Gnats::Command::EDIT->new( @_ ); }
sub editaddr     { shift; return Net::Gnats::Command::EDITADDR->new( @_ ); }
sub expr          { shift; return Net::Gnats::Command::EXPR->new( @_ ); }
sub fdsc          { shift; return Net::Gnats::Command::FDSC->new( @_ ); }
sub fieldflags   { shift; return Net::Gnats::Command::FIELDFLAGS->new( @_ ); }
sub ftyp          { shift; return Net::Gnats::Command::FTYP->new( @_ ); }
sub ftypinfo     { shift; return Net::Gnats::Command::FTYPINFO->new( @_ ); }
sub fvld          { shift; return Net::Gnats::Command::FVLD->new( @_ ); }
sub inputdefault { shift; return Net::Gnats::Command::INPUTDEFAULT->new( @_ ); }
sub list          { shift; return Net::Gnats::Command::LIST->new( @_ ); }
sub lkdb          { shift; return Net::Gnats::Command::LKDB->new( @_ ); }
sub lock_pr      { shift; return Net::Gnats::Command::LOCK->new( @_ ); }
sub qfmt          { shift; return Net::Gnats::Command::QFMT->new( @_ ); }
sub quer          { shift; return Net::Gnats::Command::QUER->new( @_ ); }
sub repl          { shift; return Net::Gnats::Command::REPL->new( @_ ); }
sub rset          { shift; return Net::Gnats::Command::RSET->new( @_ ); }
sub subm          { shift; return Net::Gnats::Command::SUBM->new( @_ ); }
sub undb          { shift; return Net::Gnats::Command::UNDB->new( @_ ); }
sub unlk          { shift; return Net::Gnats::Command::UNLK->new( @_ ); }
sub user          { shift; return Net::Gnats::Command::USER->new( @_ ); }
sub vfld          { shift; return Net::Gnats::Command::VFLD->new( @_ ); }
sub quit          { shift; return Net::Gnats::Command::QUIT->new( @_ ); }

sub new {
  my ($class, %options) = @_;

  my $self = bless {}, $class;
  return $self;
}

sub as_string {
  my ( $self ) = @_;
}

sub params { ... }
sub error_codes { ... }
sub success_codes { ... }
sub command { ... }

sub response {
  my ($self, $value) = @_;
  $self->{response} = $value if defined $value;
  return $self->{response};
}

sub requests_multi {
  my $self = shift;
  return $self->{requests_multi};
}

sub from {
  my ( $self, $value ) = @_;
  # identify idx of value
  my @fields = @{ $self->{fields} };
  my ( $index )= grep { $fields[$_] =~ /$value/ } 0..$#fields;
  return @{ $self->response->as_list }[$index];
}

=head2

For commands that must send a serialized PR, or serialized field, after issuing a command.

=cut

sub pr {
  my ( $self, $value ) = @_;
  return Net::Gnats::PR->serialize($self->{pr});
}


sub field {
  my ( $self, $value ) = @_;
  return $self->{field};
}

sub field_change_reason {
  my ( $self, $value ) = @_;
  return $self->{field};
}

1;
