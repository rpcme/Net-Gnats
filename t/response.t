use strict;
use warnings;
use Test::More;
use Net::Gnats::Response;

my $g = Net::Gnats::Response->new;

isa_ok(Net::Gnats::Response->new, 'Net::Gnats::Response');
is(Net::Gnats::Response->new->raw, q{}, 'raw is empty');
is(Net::Gnats::Response->new->code, -1, 'code is neg 1');
is(Net::Gnats::Response->new({raw => 'howdy'})->raw, 'howdy', 'raw response set via constr');
is(Net::Gnats::Response->new({code => '420'})->code, '420', 'code set via constr');
is(Net::Gnats::Response->new({code => '42'})->code, -1, 'code set via constr');
is(Net::Gnats::Response->new->raw('howdy'), 'howdy', 'set raw via method');
is(Net::Gnats::Response->new->code('420'), '420', 'set code via method');

# Note gnatsd always responds carriage return - line feed.
# first line of list is always disregarded
is(scalar @{Net::Gnats::Response->new({raw => "one\r\ntwo\r\nthree\r\n"})->as_list}, 2, "num listitems is 2");
is(scalar @{Net::Gnats::Response->new({raw => "ond"})->as_list}, 0, "num listitems is 0");
done_testing;
