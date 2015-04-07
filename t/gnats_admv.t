use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Net::Gnats;
use Net::Gnats::Command::ADMV;

my $module = Test::MockObject::Extends->new('IO::Socket::INET');
$module->fake_new( 'IO::Socket::INET' );
$module->set_true( 'print' );
$module->set_series( 'getline',
                     "200 my.gnatsd.com GNATS server 4.1.0 ready.\r\n",
                   );

my $g = Net::Gnats->new();
is($g->gnatsd_connect, 1);

isa_ok my $a = Net::Gnats::Command::ADMV->new, 'Net::Gnats::Command::ADMV';
isa_ok my $b = Net::Gnats::Command::ADMV->new( field => 'foo',
                                               key => 'bar'), 'Net::Gnats::Command::ADMV';

is $b->as_string, 'ADMV foo bar';

done_testing;
