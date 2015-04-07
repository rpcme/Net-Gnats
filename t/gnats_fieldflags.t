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
                     "350 FLAG\r\n",
                     "350-FLAG1\r\n",
                     "350 FLAG2\r\n",
                     "440 CODE_CMD_ERROR\r\n",
                     "431 CODE_GNATS_LOCKED\r\n",
                   );

my $g = Net::Gnats->new();
$g->gnatsd_connect;

is $g->get_field_flags, 0,     'Not enough args';
is_deeply $g->get_field_flags('field'), ['FLAG'],     'OK';
is_deeply $g->get_field_flags(['field1','field2']), ['FLAG1','FLAG2'], 'OK';
is $g->get_field_flags, 0, '440 CODE_CMD_ERROR';
is $g->get_field_flags, 0, '431 CODE_CMD_ERROR';

done_testing();
