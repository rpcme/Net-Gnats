package Net::Gnats::Session;
use v5.10.00;
use strictures;
use IO::Socket::INET;
use Net::Gnats::Command qw(user quit);
use Net::Gnats::Constants qw(LF CODE_GREETING CODE_PR_READY CODE_INFORMATION);

$| = 1;

=head1 NAME

Net::Gnats::Session

=head1 DESCRIPTION

Represents a specific connection to Gnats.

=cut

sub new {
  my ($class, %o ) = @_;
  return bless {}, $class if not %o;
  return bless \%o, $class;
}

my $trace = 1;

BEGIN {
  $trace = 1 if defined $ENV{GNATSD_TRACE};
}

=head1 ACCESSORS

=head2 name

The name is a combination of database and username, a friendly handle.

It does not mean anything to GNATS.

=cut

sub name {
  my $self = shift;
  return $self->hostname . '-' . $self->username;
}

=head2 hostname

The hostname of the Gnats daemon process.

Default: localhost

=cut

sub hostname {
  my ( $self, $value ) = @_;
  $self->{hostname} = $value if defined $value;
  $self->{hostname} = 'localhost' if not defined $self->{hostname};
  $self->{hostname};
}

sub is_connected {
  my ( $self ) = @_;
  $self->{connected} = 0 if not defined $self->{connected};
  $self->{connected};
}


sub is_authenticated {
  my ( $self ) = @_;
  $self->{authenticated} = 0 if not defined $self->{authenticated};
  $self->{authenticated};
}

=head2 password

The password for the user connecting to the Gnats daemon process.

Most commands require authentication.

=cut

sub password {
  my ( $self, $value ) = @_;
  $self->{password} = $value if defined $value;
  $self->{password};
}

=head2 port

The port of the Gnats daemon process.

Default: 1529

=cut

sub port {
  my ( $self, $value ) = @_;
  $self->{port} = $value if defined $value;
  $self->{port} = 1529 if not defined $self->{port};
  $self->{port};
}

=head2 skip_version

Set skip_version to override Gnats version checking. By default,
Net::Gnats supports v4 only.

You use this at your own risk.

=cut

sub skip_version { shift->{skip_version} = 1; }

=head2 username

The user connecting to the Gnats daemon process.

Most commands require authentication.

=cut

sub username {
  my ( $self, $value ) = @_;
  $self->{username} = $value if defined $value;
  $self->{username};
}

=head2 version

The Gnats daemon process version.  The version will only be set after connecting.

=cut

sub version { return shift->{version} }

=head1 METHODS


=head2 authenticate

=cut

sub authenticate {
  my ( $self ) = @_;
  my $c = Net::Gnats::Command->user( username => $self->username,
                                     password => $self->password );
  $self->issue( $c );
  _trace('AUTH: ' . $c->is_ok);
  $self->{authenticated} = 1 if $c->is_ok;
}

=head2 gconnect

Connects to Gnats.  If the username and password is set, it will
attempt authentication.

Connecting an already connected session infers reconnect.

=cut

sub gconnect {
  my ( $self ) = @_;
  my ( $sock, $iaddr, $paddr, $proto );

  _trace ('disconnecting sock if it exists');
  $self->disconnect if defined $self->{gsock};

  _trace ('constructing socket');
  _trace ('host: ' . $self->hostname);
  _trace ('port: ' . $self->port);

  $self->{gsock} = IO::Socket::INET->new( PeerAddr => $self->hostname,
                                          PeerPort => $self->port,
                                          Proto    => 'tcp');

  return $self if not defined $self->{gsock};

  my $response = $self->_read;

  _trace('Connection response: ' . $response->as_string);

  return $self if $response->code != CODE_GREETING;

  _trace('Is Connected.');
  $self->{connected} = 1;

  # Grab the gnatsd version
  $self->gnatsd_version( $response->as_string );

#    warn "? Error: GNATS Daemon version $self->{gnatsdVersion} at $self->{hostAddr} $self->{hostPort} is not supported by Net::Gnats" . LF;
  return $self if not $self->check_gnatsd_version;

  return $self if not defined $self->{username} or
    not defined $self->{password};

  $self->authenticate;

  return $self;
}

=head2 disconnect

Disconnects from the current session, either authenticated or not.

=cut

sub disconnect {
  my ( $self ) = @_;
  $self->issue( Net::Gnats::Command->quit );
}

=head2 issue

Issues a command using a Command object.  The Command object is
returned to the caller.

The Command object composes a Response, whose value(s) carry error
codes and the literal values retrived from Gnats.

=cut

sub issue {
  my ( $self, $command ) = @_;
  $command->response( $self->_run( $command->as_string ) );
  return $command;
}

=head2 run

Runs a RAW command using this session.  Returns RAW output.

=cut


# PRIVATE METHODS HERE - DO NOT EXPORT

sub gnatsd_version {
  my ($self, $value) = @_;
  if (defined $value) {
    $value =~ s/.*(\d+.\d+.\d+).*/$1/;
    $self->{version} = $1;
  }
  return $self->{version};
}

# "legally" use v4 daemon only
sub check_gnatsd_version {
  my ($self) = @_;
  my $rmajor = 4;
  my $min_minor = 1;
  return 1 if $self->skip_version;

  my ($majorv, $minorv, $patchv) = split /\./, $self->version;

  return 0 if $majorv != $rmajor;
  return 0 if $minorv < $min_minor;
  return 1;
}


sub _run {
  my ( $self, $cmd ) = @_;

  #$self->_clear_error();

  _trace('SENDING: [' . $cmd . ']');

  $self->{gsock}->print( $cmd . LF );

  return $self->_read;
}

sub _read {
  my ( $self ) = @_;
  my $response = Net::Gnats::Response->new(type => 0);

  until ( $response->is_finished == 1 ) {
    my $line = $self->_read_clean($self->{gsock}->getline);
    _trace('RECV: [' . $line . ']');
    $response->raw( $line );
  }
  return $response;
}


sub _read_clean {
  my ( $self, $line ) = @_;
  if ( not defined $line ) { return; }

  $line =~ s/\r|\n//gsm;
#  $line =~ s/^[.][.]/./gsm;
  return $line;
}

sub _read_decompose {
  my ( $self, $raw ) = @_;
  my @result = $raw =~ /^(\d\d\d)([- ]?)(.*$)/sxm;
  return \@result;
}

sub _read_has_more {
  my ( $self, $parts ) = @_;
  debug('_read_has_more');
  if ( @{$parts}[0] ) {
    debug('_read_has_more: has code');
    if ( @{$parts}[1] eq q{-} ) {
      debug('_read_has_more: has continuation dash');
      return 1;
    }
    elsif ( @{$parts}[0] >= CODE_PR_READY and @{$parts}[0] < CODE_INFORMATION) {
      debug('_read_has_more: has following information');
      return 1;
    }
    debug('_read_has_more: does not pass');
    return; # does not pass 'continue' criteria
  }
  debug('_read_has_more: no code, multiline read');
  return 1; # no code, infer multiline read
}


sub _extract_list_content {
  my ( $self, $response ) = @_;
  my @lines = split /CRLF/sxm, $response;
  return @lines;
}

sub _trace {
  my ( $message ) = @_;
  return if $trace == 0;
  print 'TRACE: [' . $message . ']' . LF;
  return;
}

1;
