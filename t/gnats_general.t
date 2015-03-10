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
                     "200 CODE_OK\r\n",
                     "600 CODE_CMD_ERROR\r\n",
                     "GARBAGE faibfiaog7abviibovibusvidbu\r\n",
                     "440 CODE_CMD_ERROR\r\n",
                     "431 CODE_GNATS_LOCKED\r\n",
                   );
isa_ok my $g = Net::Gnats->new, 'Net::Gnats';

is $g->gnatsd_connect, 1;

isa_ok $g->new_pr, 'Net::Gnats::PR';

done_testing();
