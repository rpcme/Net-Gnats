use strict;
use warnings;
use Test::More;

# LIVE TESTS ONLY, MAINTAINER MODE ONLY
unless ( $ENV{'GNATS_MAINTAINER'} ) {
  plan skip_all => "Live tests by default are skipped, maintainer only.";
}
else {
  plan tests => 18;
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
ok($g->list_fieldnames, 'list_fieldnames');
ok($g->list_inputfields_initial, 'list_inputfields_initial');

is($g->get_field_typeinfo('Originator'), undef, 'get_field_typeinfo - bad arg');
# Note typeinfo req MultiEnum so if the field's not MultiEnum, you get undef
is($g->get_field_typeinfo('Originator', 'separators'), undef, 'get_field_typeinfo');
# TODO : Find MultiEnum field to test this
#ok($g->get_field_typeinfo('State', 'separators'), 'get_field_typeinfo');

ok(defined $g->get_field_desc('Originator'), 'get_field_desc');
ok(defined $g->get_field_flags('Originator'), 'get_field_flags');

is($g->get_field_type, undef, 'get_field_type - bad arg');
ok(defined $g->get_field_type('Responsible'), 'get_field_type');
ok($g->disconnect, 'Logout of gnats');



# PR Add/Modify/Delete (Basic)
my $pr = $g->newPR;
isa_ok($pr, 'Net::Gnats::PR');

  # my $newPR = $g->newPR();
  # $newPR->setField("Submitter-Id","developer");
  # $newPR->setField("Originator","Doctor Wifflechumps");
  # $newPR->setField("Organization","GNU");
  # $newPR->setField("Synopsis","Some bug from perlgnats");
  # $newPR->setField("Confidential","no");
  # $newPR->setField("Severity","serious");
  # $newPR->setField("Priority","low");
  # $newPR->setField("Category","gnatsperl");
  # $newPR->setField("Class","sw-bug");
  # $newPR->setField("Description","Something terrible happened");
  # $newPR->setField("How-To-Repeat","Like this.  Like this.");
  # $newPR->setField("Fix","Who knows");
  # $g->submitPR($newPR);

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

