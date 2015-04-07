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
                     "350 Description for field\r\n",
                     "350-Description for field1\r\n",
                     "350 Description for field2\r\n",
                     "600 CODE_CMD_ERROR\r\n",
                     "440 CODE_CMD_ERROR\r\n",
                     "431 CODE_GNATS_LOCKED\r\n",
                   );

my $g = Net::Gnats->new();
$g->gnatsd_connect;

is_deeply $g->get_field_desc('field'), ['Description for field'], 'Single field';
is_deeply $g->get_field_desc(['field1','field2']), ['Description for field1','Description for field2'], 'Multi field';
is $g->get_field_desc, 0, 'ERROR 600';
is $g->get_field_desc, 0, 'CODE_CMD_ERROR';
is $g->get_field_desc, 0, 'CODE_CMD_ERROR';

done_testing();
