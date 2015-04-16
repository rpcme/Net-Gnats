use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Net::Gnats;

use File::Basename;
use lib dirname(__FILE__);
use Net::Gnats::TestData::Gtdata qw(connect_standard);

my $module = Test::MockObject::Extends->new('IO::Socket::INET');
$module->fake_new( 'IO::Socket::INET' );
$module->set_true( 'print' );
$module->set_series( 'getline',
                     @{ connect_standard() },
                     # rset, qfmt, expr
                     "210 CODE_OK\r\n",
                     "210 CODE_OK\r\n",
                     #"210 CODE_OK\r\n",
                     "220 No PRs Matched\r\n",
                     # rset, qfmt, expr
                     "210 CODE_OK\r\n",
                     "210 CODE_OK\r\n",
                     #"210 CODE_OK\r\n",
                     "418 Invalid query format\r\n",
                     # rset, qfmt, expr
                     "210 CODE_OK\r\n",
                     "210 CODE_OK\r\n",
                     #"210 CODE_OK\r\n",
                     "300 PRs follow.\r\n",
                     ">Number:         45\r\n",
                     ".\r\n",
                     # rset, qfmt, expr
                     "210 CODE_OK\r\n",
                     "210 CODE_OK\r\n",
                     #"210 CODE_OK\r\n",
                     "300 PRs follow.\r\n",
                     ">Number:         45\r\n",
                     ">Number:         46\r\n",
                     ".\r\n",
                   );

my $g = Net::Gnats->new();
$g->gnatsd_connect;

is $g->query, 0, 'No PRs Matched';
is $g->query, 0, 'Invalid query format';
is_deeply $g->query, [45], 'One PR';
is_deeply $g->query, [45,46], 'Two PRs';

done_testing();
