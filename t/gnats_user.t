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
                     "422 CODE_NO_ACCESS\r\n",
                     "200 CODE_OK\r\n",
                   );

my $g = Net::Gnats->new();
$g->gnatsd_connect;

is $g->cmd_user, undef, 'Must have 2 arguments';
is $g->cmd_user("user"), undef, 'Must have 2 arguments';
is $g->cmd_user("user", "badpass"), undef, 'ERROR 422 No Access';
is $g->cmd_user("user", "goodpass"), undef, 'CODE_OK';

done_testing();
