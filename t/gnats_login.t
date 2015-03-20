use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Net::Gnats;

my $module = Test::MockObject::Extends->new('IO::Socket::INET');
$module->fake_new( 'IO::Socket::INET' );
$module->set_true( 'print' );
$module->set_true( 'close' );
$module->set_series( 'getline',
                     "200 my.gnatsd.com GNATS server 4.1.0 ready.\r\n",
                     "201 CODE_CLOSING\r\n",
                     "200 my.gnatsd.com GNATS server 5.1.0 ready.\r\n",
                     "201 CODE_CLOSING\r\n",
                     "200 my.gnatsd.com GNATS server 5.1.0 ready.\r\n",
                     "201 CODE_CLOSING\r\n",
                     );

my $g = Net::Gnats->new();
is $g->gnatsd_connect, 1;
is $g->disconnect, 1;
is $g->gnatsd_connect, 0;  # unsupported version
is $g->disconnect, 1;
is $g->skip_version_check(1), 1;
is $g->gnatsd_connect, 1;  # version override
is $g->disconnect, 1;

done_testing;
