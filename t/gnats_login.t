use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Net::Gnats;

use File::Basename;
use lib dirname(__FILE__);
use Net::Gnats::TestData::Gtdata qw(connect_standard conn_bad user schema1);

Net::Gnats->verbose(1);
Net::Gnats->verbose_level(1);

my $module = Test::MockObject::Extends->new('IO::Socket::INET');
$module->fake_new( 'IO::Socket::INET' );
$module->set_true( 'print' );
$module->set_true( 'close' );
$module->set_series( 'getline',
                     @{ connect_standard() },
                     "201 CODE_CLOSING\r\n",
                     @{ conn_bad() },
                     "201 CODE_CLOSING\r\n",
                     @{ conn_bad() },
                     @{ user() },
                     @{ schema1() },
                     "201 CODE_CLOSING\r\n",
                     );

my $g1 = Net::Gnats->new();
is $g1->gnatsd_connect, 1;
is $g1->disconnect, 1;

my $g2 = Net::Gnats->new();
is $g2->gnatsd_connect, 0;  # unsupported version

my $g3 = Net::Gnats->new();
is $g3->skip_version_check(1), 1;
is $g3->gnatsd_connect, 1;  # version override
is $g3->disconnect, 1;

done_testing;
