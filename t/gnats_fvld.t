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
                     "301 Valid values follow.\r\n",
                     ".\r\n",
                     "301 Valid values follow.\r\n",
                     "regexp1\r\n",
                     "regexp2\r\n",
                     ".\r\n",
                     "999 GARBAGE\r\n",
                   );

my $g = Net::Gnats->new();
$g->gnatsd_connect;

is $g->get_field_validators, 0, 'field not passed';
is $g->get_field_validators('badfield'), 0, 'unknown field';
is_deeply $g->get_field_validators('goodfield'), [], 'returned array of validators';
is_deeply $g->get_field_validators('goodfield'), ['regexp1','regexp2'], 'returned array of validators';
is $g->get_field_validators('garbage'), 0, 'garbage';

done_testing();
