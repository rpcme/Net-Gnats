use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Net::Gnats;


use File::Basename;
use lib dirname(__FILE__);
use Net::Gnats::TestData::Gtdata qw(connect_standard);

my $module = Test::MockObject::Extends->new('IO::Socket::INET');
$module->fake_new( 'IO::Socket::INET' );
$module->set_true( 'print' );
$module->set_series( 'getline',
                     @{ connect_standard() },
                     "301 List follows.\r\n",
                     "default\r\n",
                     ".\r\n",
                     "301 List follows.\r\n",
                     "default\r\n",
                     ".\r\n",
                     "301 List follows.\r\n",
                     "default\r\n",
                     ".\r\n",
                     "600 Unauthorized.\r\n",
                     "301 List follows.\r\n",
                     "default\r\n",
                     ".\r\n",
                     "301 List follows.\r\n",
                     "default\r\n",
                     "default2\r\n",
                     ".\r\n",
                   );

my $g = Net::Gnats::Session->new;
$g->gconnect;

my $c1 = Net::Gnats::Command->dbls();
my $c2 = Net::Gnats::Command->dbls('garbage');
my $c3 = Net::Gnats::Command->dbls(garbage => 'garbage');
my $c4_bad = Net::Gnats::Command->dbls();

is $g->issue($c1)->is_ok, 1, 'c1 is OK';
is $g->issue($c2)->is_ok, 1, 'c2 is OK';
is $g->issue($c3)->is_ok, 1, 'c3 is OK';
is $g->issue($c4_bad)->is_ok, 0, 'c4 is not OK';


is_deeply $g->issue($c1)->response->as_list, ['default'], 'c1 list is OK';
is_deeply $g->issue($c1)->response->as_list, ['default', 'default2'], 'c1 list multi is OK';

done_testing();
