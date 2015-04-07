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
# schema setup
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
                     # rset
                     # qfmt
                     # quer
                   );



done_testing();
