use strict;
use warnings;
use Test::More;
use Net::Gnats;

my $g = Net::Gnats->new;

isa_ok(Net::Gnats->new, 'Net::Gnats');

is( $g->_is_code_ok('200'), 1 );
is( $g->_is_code_ok('300'), 1 );
is( $g->_is_code_ok('3'), 0 );
is( $g->_is_code_ok(undef), 0 );

done_testing;
