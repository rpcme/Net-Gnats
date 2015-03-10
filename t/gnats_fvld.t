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
                     "301 CODE_TEXT_READY\r\n",
                     "regexp1\n",
                     "regexp2\n",
                     ".\r\n",
                     "999 GARBAGE\r\n",
                   );

my $g = Net::Gnats->new();
$g->gnatsd_connect;

is $g->get_field_validators, undef, 'field not passed';
is $g->get_field_validators('badfield'), undef, 'unknown field';
is scalar @{  $g->get_field_validators('goodfield') }, 2, 'returned array of validators';
is $g->get_field_validators('garbage'), undef, 'garbage';

done_testing();
