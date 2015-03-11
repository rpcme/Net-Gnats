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
                     "301 CODE_TEXT_READY\r\n",
                     "db1:db1 desc:/path/to/db1\r",
                     "db2:db2 desc:/path/to/db2\r",
                     ".\r\n",
                     "301 CODE_TEXT_READY\r\n",
                     "cat1:cat1 desc:joe:mark\r",
                     ".\r\n",
                     "301 CODE_TEXT_READY\r\n",
                     "sub1:Sub long name:my contract:2:jimmy:joe, bob\r",
                     ".\r\n",
                     "301 CODE_TEXT_READY\r\n",
                     "bob:Bobby Boy:bobby\@whodunit.gov\r",
                     ".\r\n",
                     "301 CODE_TEXT_READY\r\n",
                     "closed::really closed",
                     "analyzed:deeply:This was analyzed deeply.\r",
                     ".\r\n",
                     "301 CODE_TEXT_READY\r\n",
                     "field1\r",
                     "field2\r",
                     ".\r\n",
                     "301 CODE_TEXT_READY\r\n",
                     "field1\r",
                     "field2\r",
                     ".\r\n",
                   );

my $g = Net::Gnats->new();
$g->gnatsd_connect;
my $dbs = [
           { name => 'db1',
             desc => 'db1 desc',
             path => '/path/to/db1',
           },
           { name => 'db2',
             desc => 'db2 desc',
             path => '/path/to/db2',
           },
          ];

is_deeply $g->list_databases, $dbs, 'list_databases';

my $cat1 = [
           { name => 'cat1',
             desc => 'cat1 desc',
             contact => 'joe',
             notify => 'mark',
           },];

is_deeply $g->list_categories, $cat1,     'list_categories';

my $sub1 = [
            { name => 'sub1',
              desc => 'Sub long name',
              contract => 'my contract',
              response => '2',
              contact => 'jimmy',
              othernotify => 'joe, bob',
            },
           ];

is_deeply $g->list_submitters, $sub1,     'list_submitters';
my $resp1 = [
             { name => 'bob',
               realname => 'Bobby Boy',
               email => 'bobby@whodunit.gov',
             },
            ];
is_deeply  $g->list_responsible, $resp1, 'list_responsible';

my $s1 = [
          { name => 'closed',
            type => '',
            desc => 'really closed',
          },
          { name => 'analyzed',
            type => 'deeply',
            desc => 'This was analyzed deeply.',
          },
         ];
is_deeply $g->list_states, $s1, 'list_states';

my $lfn = ['field1', 'field2'];
is_deeply $g->list_fieldnames, $lfn, 'list_fieldnames';

my $lii = ['field1', 'field2'];
is_deeply $g->list_inputfields_initial, $lii, 'list_inputfields_initial';

done_testing();
