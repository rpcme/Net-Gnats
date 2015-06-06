use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Net::Gnats qw(verbose verbose_level);
use Net::Gnats::Schema;
use Net::Gnats::Session;

Net::Gnats->verbose(1);
Net::Gnats->verbose_level(1);

use File::Basename;
use lib dirname(__FILE__);
use Net::Gnats::TestData::Gtdata qw(connect_standard conn user schema1);

my $module = Test::MockObject::Extends->new('IO::Socket::INET');
$module->fake_new( 'IO::Socket::INET' );
$module->set_true( 'print' );
$module->set_series( 'getline',
                     @{ conn() },
                     @{ user() },
                     "210-Now accessing GNATS database 'default'\r\n",
                     "210 User access level set to 'admin'\r\n",
                     @{ schema1() }
                   );

my $g = Net::Gnats->new();
print "Connecting\n";
$g->gnatsd_connect;
$g->login('default', 'madmin', 'madmin');


# At least one user has implemented 'scopes' which is an extension to the
# default way of naming fields as they are named in the schema.  For example,
#
# Schema        PR
# ----------    ----------
# Originator => Originator
#
# In the case of scopes, a PR field can be 'scoped' with a field 'extension'
#
# Schema        PR
# ----------    -------------
# Originator => Originator{1}
#
# In this case, the 'scoped' field needs to match with the schema name.
#

# Create with no value

my $f1 = $g->current_session
           ->schema
           ->field('Originator')
           ->instance(for_name => 'Originator{1}');

is $f1->name, 'Originator{1}', 'Field name is Originator{1}';
is $f1->schema->name, 'Originator', 'Schema name is Originator';

# Create with value

my $f2 = $g->current_session
           ->schema
           ->field('Originator')
           ->instance(for_name => 'Originator{1}',
                      value    => 'Doctor Wifflechumps');

# Deserialize a PR

my $pr1 = Net::Gnats::PR->deserialize(data => pr1(),
                                      schema => $g->current_session->schema);

my $pr2 = Net::Gnats::PR->deserialize(data => pr2(),
                                      schema => $g->current_session->schema);

my $pr3 = Net::Gnats::PR->deserialize(data => pr3(),
                                      schema => $g->current_session->schema);

# Verify the field
is $pr1->getField('Originator{1}'), 'Doctor Wifflechumps', 'field found';

# Replace a field
# https://github.com/Miniconf/Net-Gnats/issues/1
isa_ok $pr1->get_field( 'Number' ), 'Net::Gnats::FieldInstance';
isa_ok $pr1->get_field( 'Originator{1}' ), 'Net::Gnats::FieldInstance';

isa_ok $pr2->get_field( 'Responsible{1}' ), 'Net::Gnats::FieldInstance';
is     $pr3->get_field( 'Responsible{1}' ), undef;

is_deeply $pr2->get_field_from('Responsible'), [ 'Responsible{1}','Responsible{2}','Responsible{3}']; 

# Modify an existing field


done_testing();

sub pr1 {
  return ["From: Doctor Wifflechumps\r\n",
          "Reply-To: Doctor Wifflechumps\r\n",
          "To: bugs\r\n",
          "Cc:\r\n",
          "Subject: Some bug from perlgnats\r\n",
          "X-Send-Pr-Version: Net::Gnats-0.07 (\$Id: PR.pm,v 1.3 2014/08/14 13:32:27 thacker Exp \$)\r\n",
          "\r\n",
          ">Number:         45\r\n",
          ">Category:       pending\r\n",
          ">Synopsis:       changing you\r\n",
          ">Confidential:   yes\r\n",
          ">Severity:       serious\r\n",
          ">Priority:       medium\r\n",
          ">Responsible:    gnats-admin\r\n",
          ">State:          open\r\n",
          ">Class:          sw-bug\r\n",
          ">Submitter-Id:   unknown\r\n",
          ">Arrival-Date:   Fri Aug 15 17:43:51 +1000 2014\r\n",
          ">Last-Modified:  Fri Aug 15 17:43:51 +1000 2014\r\n",
          ">Originator{1}:  Doctor Wifflechumps\r\n",
          ">Release:        \r\n",
          ">Fix:\r\n",
          ">Unformatted:\r\n",
          "\r\n",];
}

sub pr2 {
  return ["From: Doctor Wifflechumps\r\n",
          "Reply-To: Doctor Wifflechumps\r\n",
          "To: bugs\r\n",
          "Cc:\r\n",
          "Subject: Some bug from perlgnats\r\n",
          "X-Send-Pr-Version: Net::Gnats-0.07 (\$Id: PR.pm,v 1.3 2014/08/14 13:32:27 thacker Exp \$)\r\n",
          "\r\n",
          ">Number:         45\r\n",
          ">Category:       pending\r\n",
          ">Synopsis:       changing you\r\n",
          ">Confidential:   yes\r\n",
          ">Severity:       serious\r\n",
          ">Priority:       medium\r\n",
          ">Responsible{1}: gnats-admin\r\n",
          ">Responsible{2}: gnats-admin\r\n",
          ">Responsible{3}: gnats-admin\r\n",
          ">State:          open\r\n",
          ">Class:          sw-bug\r\n",
          ">Submitter-Id:   unknown\r\n",
          ">Arrival-Date:   Fri Aug 15 17:43:51 +1000 2014\r\n",
          ">Last-Modified:  Fri Aug 15 17:43:51 +1000 2014\r\n",
          ">Originator{1}:  Doctor Wifflechumps\r\n",
          ">Release:        \r\n",
          ">Fix:\r\n",
          ">Unformatted:\r\n",
          "\r\n",];
}

sub pr3 {
  return ["From: Doctor Wifflechumps\r\n",
          "Reply-To: Doctor Wifflechumps\r\n",
          "To: bugs\r\n",
          "Cc:\r\n",
          "Subject: Some bug from perlgnats\r\n",
          "X-Send-Pr-Version: Net::Gnats-0.07 (\$Id: PR.pm,v 1.3 2014/08/14 13:32:27 thacker Exp \$)\r\n",
          "\r\n",
          ">Number:         45\r\n",
          ">Category:       pending\r\n",
          ">Synopsis:       changing you\r\n",
          ">Confidential:   yes\r\n",
          ">Severity:       serious\r\n",
          ">Priority:       medium\r\n",
          ">responsible{1}: gnats-admin\r\n",
          ">State:          open\r\n",
          ">Class:          sw-bug\r\n",
          ">Submitter-Id:   unknown\r\n",
          ">Arrival-Date:   Fri Aug 15 17:43:51 +1000 2014\r\n",
          ">Last-Modified:  Fri Aug 15 17:43:51 +1000 2014\r\n",
          ">Originator{1}:  Doctor Wifflechumps\r\n",
          ">Release:        \r\n",
          ">Fix:\r\n",
          ">Unformatted:\r\n",
          "\r\n",];
}
