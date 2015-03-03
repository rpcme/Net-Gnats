use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Net::Gnats;

plan tests => 5;

my $module = Test::MockObject::Extends->new('IO::Socket::INET');
$module->fake_new( 'IO::Socket::INET' );
$module->set_true( 'print' );
$module->set_series( 'getline',
                     "200 my.gnatsd.com GNATS server 4.1.0 ready.\r\n",
                     "200 CODE_OK\r\n",
                   );

my $g = Net::Gnats->new();
$g->gnatsd_connect;

is( $g->lock_main_database, 1,     '200 locked' );
is( $g->lock_main_database, undef, 'ERROR 600 Can lock database' );
is( $g->lock_main_database, undef, 'ERROR UNK GARBAGE' );
is( $g->lock_main_database, undef, 'CODE_CMD_ERROR');
is( $g->lock_main_database, undef, 'CODE_CMD_ERROR');

