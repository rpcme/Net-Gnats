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
                     "440 CODE_CMD_ERROR\r\n",
                     "210 PR 1 unlocked.\r\n",
                     "433 CODE_PR_NOT_LOCKED\r\n",
                     "666 THE_EVIL_ERROR\r\n",
                   );

my $g = Net::Gnats->new();
$g->gnatsd_connect;

# this method just requires and ID when in fact it _should_ be a PR
# instance.

my $p = 1;

is $g->unlock_pr, 0, 'must pass a pr';
is $g->unlock_pr($p), 0, '440 CODE_CMD_ERROR';
is $g->unlock_pr($p), 1, '210 CODE_OK';
is $g->unlock_pr($p), 0, '433 CODE_PR_NOT_LOCKED';
is $g->unlock_pr($p), 0, '6xx (internal error)';

done_testing();
