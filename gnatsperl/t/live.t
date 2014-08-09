use strict;
use warnings;
use Test::More;

# LIVE TESTS ONLY, MAINTAINER MODE ONLY
unless ( $ENV{'GNATS_MAINTAINER'} ) {
  plan skip_all => "Live tests by default are skipped, maintainer only.";
}
else {
  plan tests => 10;
}

use Net::Gnats;

my $conn1 = {
             server   => 'localhost',
             port     => '1529',
             username => '',
             password => '',
             db       => 'default'
            };

$conn1 = ovr_def($conn1);

my $g = Net::Gnats->new($conn1->{server},
                        $conn1->{port});
my $connected;

is($g->gnatsd_connect, 1, "Connect is OK");

is($g->login($conn1->{db},
             $conn1->{username},
             $conn1->{password}), 1, "Login is OK");

ok(defined $g->listDatabases(), "Can list databases from gnatsd");
ok($g->get_dbnames, 'get_dbnames');
ok($g->list_databases, 'list_databases');
ok($g->list_categories, 'list_categories');
ok($g->list_submitters, 'list_submitters');
ok($g->list_responsible, 'list_responsible');
ok($g->list_states, 'list_states');

ok($g->disconnect, 'Logout of gnats');

done_testing();

sub ovr_def {
  my ($settings) = @_;

  return $settings if not defined $ENV{GNATSDB};

  my ($server, $port, $db, $username, $password) = split /:/, $ENV{GNATSDB};
  $settings->{server}   = length $server   ? $server   : $settings->{server};
  $settings->{port}     = length $port     ? $port     : $settings->{port};
  $settings->{db}       = length $db       ? $db       : $settings->{db};
  $settings->{username} = length $username ? $username : $settings->{username};
  $settings->{password} = length $password ? $password : $settings->{password};
  return $settings;
}

