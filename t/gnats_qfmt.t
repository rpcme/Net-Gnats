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
                     "210 CODE_OK\r\n",
                     "210 CODE_OK\r\n",
                     "210 CODE_OK\r\n",
                     "440 CODE_CMD_ERROR\r\n",
                     "418 CODE_INVALID_QUERY_FORMAT\r\n",
                   );

my $g = Net::Gnats->new();

is $g->gnatsd_connect, 1;
is $g->qfmt, 1, 'defaults to STANDARD';
is $g->qfmt('full'), 1, 'FULL is OK';
is $g->qfmt('summary'), 1, 'SUMMARY is OK';
is $g->qfmt(''), undef, 'HIT CODE_CMD_ERROR';
is $g->qfmt('%R%E%DEGFHF'), undef, 'bogus format error';

done_testing();

