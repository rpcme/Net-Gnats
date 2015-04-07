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
                     "350 ':' ';'\r\n",
                     "350 ':' ';'\r\n",
                     "600 CODE_CMD_ERROR\r\n",
                     "440 CODE_CMD_ERROR\r\n",
                     "431 CODE_GNATS_LOCKED\r\n",
                   );

my $g = Net::Gnats->new();
$g->gnatsd_connect;

is $g->get_field_type_info, 0,     'Not enough args';
is $g->get_field_type_info('field'), q{':' ';'},     'OK';
is $g->get_field_type_info('field','myprop'),  q{':' ';'},     'OK';
is $g->get_field_type_info, 0, 'ERROR 600 Unknown';
is $g->get_field_type_info, 0, 'CODE_CMD_ERROR';
is $g->get_field_type_info, 0, 'CODE_CMD_ERROR';

done_testing();
