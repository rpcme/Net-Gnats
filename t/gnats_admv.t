use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Net::Gnats;

plan tests => 1;

my $module = Test::MockObject::Extends->new('IO::Socket::INET');
$module->fake_new( 'IO::Socket::INET' );
$module->set_true( 'print' );
$module->set_series( 'getline',
                     "200 my.gnatsd.com GNATS server 4.1.0 ready.\r\n",
                   );

my $g = Net::Gnats->new();
is($g->gnatsd_connect, 1);

done_testing;
