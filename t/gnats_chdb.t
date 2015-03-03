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
                     "210 CODE_OK\r\n",
                     "350 Admin\r\n",
                     "422 CODE_NO_ACCESS\r\n",
                     "GARBAGE faibfiaog7abviibovibusvidbu\r\n",
                     "417 CODE_INVALID_DATABASE\r\n",
                   );

my $g = Net::Gnats->new();
is( $g->gnatsd_connect, 1 );

is( $g->login('foo', 'bar', 'baz'), 1,     '200 Login OK' );
is( $g->login('foo', 'bar', 'baz'), undef, 'ERROR 422 BAD USERNAME PASSWORD' );
is( $g->login('foo', 'bar', 'baz'), undef, 'ERROR UNK GARBAGE' );
is( $g->login('foo', 'bar', 'baz'), undef, 'ERROR 417 BAD DATABASE');

