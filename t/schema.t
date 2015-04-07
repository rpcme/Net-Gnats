use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Net::Gnats;
use Net::Gnats::Schema;
use Net::Gnats::Session;

my $module = Test::MockObject::Extends->new('IO::Socket::INET');
$module->fake_new( 'IO::Socket::INET' );
$module->set_true( 'print' );
$module->set_series( 'getline',
                     "200 my.gnatsd.com GNATS server 4.1.0 ready.\r\n",
                     "301 List follows.\r\n",
                     "Field1\r\n",
                     "Field2\r\n",
                     ".\r\n",
                     "350-Text\r\n",
                     "350 Enum\r\n",
                     "350-Description field1\r\n",
                     "350 Description field2\r\n",
                     "350-DEF_FIELD1\r\n",
                     "350 DEF_FIELD2\r\n",
                     "350-\r\n",
                     "350 textsearch\r\n",
                   );

my $g = Net::Gnats->new();
$g->gnatsd_connect;

# initialize new schema
isa_ok my $s = Net::Gnats::Schema->new( $g->session ), 'Net::Gnats::Schema';

is $s->field('Field1')->name, 'Field1';
is $s->field('Field1')->description, 'Description field1';
is $s->field('Field1')->type, 'Text';
is $s->field('Field1')->default, 'DEF_FIELD1';
is $s->field('Field1')->flags, '';

is $s->field('Field2')->name, 'Field2';
is $s->field('Field2')->description, 'Description field2';
is $s->field('Field2')->type, 'Enum';
is $s->field('Field2')->default, 'DEF_FIELD2';
is $s->field('Field2')->flags, 'textsearch';

done_testing();
