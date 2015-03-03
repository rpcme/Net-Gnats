use strict;
use warnings;
use Test::More;
use Net::Gnats::PR;

plan tests => 17;

my $p = Net::Gnats::PR->new(1); # fake the obj, no need

isa_ok($p, 'Net::Gnats::PR');

my @known = qw(Field Severity);

my $r1 = $p->parse_line('>Field: value', \@known);
is( @{ $r1 }[0], 'Field');
is( @{ $r1 }[1], 'value');

my $r2 = $p->parse_line('>Field:    value'      , \@known);
is( @{ $r2 }[0], 'Field');
is( @{ $r2 }[1], 'value');

my $r3 = $p->parse_line(">Field: 123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!" , \@known);
is( @{ $r3 }[0], 'Field');
is( @{ $r3 }[1], "123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!");

my $r4 = $p->parse_line('>Field:    value        '      , \@known);
is( @{ $r4 }[0], 'Field');
is( @{ $r4 }[1], 'value');

my $r5 = $p->parse_line('a multiline line', \@known);
is( @{ $r5 }[0], undef);
is( @{ $r5 }[1], 'a multiline line');

my $r6 = $p->parse_line('', \@known);
is( @{ $r6 }[0], undef);
is( @{ $r6 }[1], '');

my $r7 = $p->parse_line('>Unknown: value'      , \@known);
is( @{ $r7 }[0], undef);
is( @{ $r7 }[1], '>Unknown: value');

my $r8 = $p->parse_line('     multiline with initial spaces', \@known);
is( @{ $r8 }[0], undef);
is( @{ $r8 }[1], '     multiline with initial spaces');

done_testing;
