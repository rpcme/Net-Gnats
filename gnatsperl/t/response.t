use strict;
use warnings;
use Test::More;
use Net::Gnats::Response;

my $g = Net::Gnats::Response->new;

isa_ok(Net::Gnats::Response->new, 'Net::Gnats::Response');
is(Net::Gnats::Response->new->raw, undef, 'raw is undef');
is(Net::Gnats::Response->new->code, undef, 'code is undef');
is(Net::Gnats::Response->new({raw => 'howdy'})->raw, 'howdy', 'raw response set via constr');
is(Net::Gnats::Response->new({code => '42'})->code, '42', 'code set via constr');
is(Net::Gnats::Response->new->raw('howdy'), 'howdy', 'set raw via method');
is(Net::Gnats::Response->new->code('42'), '42', 'set code via method');

# Note gnatsd always responds carriage return - line feed.
# first line of list is always disregarded
is(scalar @{Net::Gnats::Response->new({raw => "one\r\ntwo\r\nthree\r\n"})->as_list}, 2, "num listitems is 2");
is(scalar @{Net::Gnats::Response->new({raw => "ond"})->as_list}, 0, "num listitems is 0");
done_testing;
