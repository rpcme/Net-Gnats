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
                     "410 CODE_INVALID_FIELD_NAME\r\n",
                     "212 CODE_SEND_TEXT\r\n",
                     "210 CODE_OK\r\n",
                   );

my $g = Net::Gnats->new();
$g->gnatsd_connect;

is $g->validate_field, undef, 'req 2 param, got none';
is $g->validate_field('fld'), undef, 'req 2 param, got one';
is $g->validate_field('unk','foo'), undef, 'req 2 param, fld is unknown';
is $g->validate_field('fld','foo'), 1, 'req 2 param, fld is good';

done_testing();
