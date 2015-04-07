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
                     "350 Text\r\n",
                     "350 Enum\r\n",
                     "350-Text\r\n",
                     "350 Enum\r\n",
                     "600 CODE_CMD_ERROR\r\n",
                     "440 CODE_CMD_ERROR\r\n",
                     "431 CODE_GNATS_LOCKED\r\n",
                   );

my $g = Net::Gnats->new();
$g->gnatsd_connect;

is $g->get_field_type, 0,     'field not passed';
is @{$g->get_field_type('Release')}[0], 'Text',     'isa text field';
is @{$g->get_field_type('Class')}[0],   'Enum',     'isa enum field';
is_deeply $g->get_field_type(['Release','Class']), ['Text', 'Enum'];

is( $g->get_field_type, 0, 'ERROR 600 Can lock database' );
is( $g->get_field_type, 0, 'CODE_CMD_ERROR');
is( $g->get_field_type, 0, 'CODE_CMD_ERROR');

done_testing();
