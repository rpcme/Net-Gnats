use strict;
use warnings;
use Test::More;
use Net::Gnats;

my $g = Net::Gnats->new;

isa_ok(Net::Gnats->new, 'Net::Gnats');

is( $g->_isCodeOK('200'), 1 );
is( $g->_isCodeOK('300'), 1 );
is( $g->_isCodeOK('3'), 0 );
is( $g->_isCodeOK(undef), 0 );

done_testing;
