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
                     "415 CODE_INVALID_EXPR\r\n",
                     "200 CODE_OK\r\n",           # Single
                     "200 CODE_OK\r\n",           # Mult 1
                     "200 CODE_OK\r\n",           # Mult 1
                   );

my $g = Net::Gnats->new();
$g->gnatsd_connect;

# No expressions, undef
is $g->expr, undef, 'must have a query expression';

# Bad expression
is $g->expr('bad'), undef, 'Bad expression';

# Single expression
is $g->expr('expr1'), 1, 'Single expression ok';

# Multiple expression
is $g->expr('expr1','expr2'), 1, 'Multiple expression ok';

# Todo: which expressions are bad?

done_testing();

