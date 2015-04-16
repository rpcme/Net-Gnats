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
                     "210 CODE_OK\r\n",           # Single
                     # cmd does not get defined
                     "210 CODE_OK\r\n",           # Mult 1
                     "210 CODE_OK\r\n",           # Mult 1
                   );

my $g = Net::Gnats::Session->new;
$g->gconnect;

my $c1 = Net::Gnats::Command->expr( expressions => ['Priority="High"'] );
my $c2 = Net::Gnats::Command->expr;

is $c1->as_string, 'EXPR Priority="High"';
is $c2->as_string, undef;

is $g->issue($c1)->is_ok, 1, 'Command is OK';
is $g->issue($c2)->is_ok, 0, 'Command is NOT OK';

## Legacy
# No expressions, undef
#is $g->expr, undef, 'must have a query expression';

# Bad expression
#is $g->expr('bad'), undef, 'Bad expression';

# Single expression
#is $g->expr('expr1'), 1, 'Single expression ok';

# Multiple expression
#is $g->expr('expr1','expr2'), 1, 'Multiple expression ok';


done_testing();

