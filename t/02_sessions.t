use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Net::Gnats::Session;

isa_ok my $g1 = Net::Gnats::Session->new, 'Net::Gnats::Session';
is $g1->hostname('192.168.1.203'), '192.168.1.203';
is $g1->port, 1529;
is $g1->username('madmin'), 'madmin';
is $g1->password('madmin'), 'madmin';

isa_ok $g1->gconnect, 'Net::Gnats::Session';
is $g1->is_connected, 1;
is $g1->is_authenticated, 1;

isa_ok my $g2 = Net::Gnats::Session->new, 'Net::Gnats::Session';
is $g2->hostname, 'localhost';
is $g2->port, 1529;
is $g2->username, undef;
is $g2->password, undef;

isa_ok $g2->gconnect, 'Net::Gnats::Session';
is $g2->is_connected, 0;
is $g2->is_authenticated, 0;


done_testing;
