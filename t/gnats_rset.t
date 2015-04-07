use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Net::Gnats;

my $module = Test::MockObject::Extends->new('IO::Socket::INET');
$module->fake_new( 'IO::Socket::INET' );
$module->set_true( 'print' );
$module->set_series( 'getline',
                     "200 my.gnatsd.com GNATS server 4.1.0 ready.\r\n",
                     "210 Reset state.\r\n",
                     "600 unknown\r\n",
                     "440 CODE_CMD_ERROR\r\n",
                   );

my $g = Net::Gnats->new();
$g->gnatsd_connect;

is $g->reset_server, 1, '210 reset';
is $g->reset_server, 0, '600 unknown';
is $g->reset_server, 0, '440 CODE_CMD_ERROR';

done_testing();
