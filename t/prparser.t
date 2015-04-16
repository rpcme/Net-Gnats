use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Net::Gnats;
use Net::Gnats::PR qw(deserialize parse_line);

my $p = Net::Gnats::PR->new;

isa_ok($p, 'Net::Gnats::PR');

my @known = qw(Field Severity);

# header types
is_deeply parse_line('From: Doctor Wifflechumps', \@known), ['From','Doctor Wifflechumps'];
is_deeply parse_line('Reply-To: Doctor Wifflechumps', \@known), ['Reply-To','Doctor Wifflechumps'];
is_deeply parse_line('To: bugs', \@known), ['To', 'bugs'];
is_deeply parse_line('Cc:', \@known), ['Cc',''];
is_deeply parse_line('Subject: Some bug from perlgnats', \@known), ['Subject','Some bug from perlgnats'];
is_deeply parse_line('X-Send-Pr-Version: Net::Gnats-0.07 ($Id: PR.pm,v 1.3 2014/08/14 13:32:27 thacker Exp $)', \@known),
  ['X-Send-Pr-Version', 'Net::Gnats-0.07 ($Id: PR.pm,v 1.3 2014/08/14 13:32:27 thacker Exp $)'];

# main pr types
is_deeply parse_line('>Field: value', \@known), ['Field','value'];
is_deeply parse_line('>Field:    value', \@known), ['Field', 'value'];
is_deeply parse_line(">Field: 123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!" , \@known), ['Field', "123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!123456789!"];

is_deeply parse_line('>Field:    value        ', \@known), ['Field',  'value'];
is_deeply parse_line('a multiline line', \@known), [ undef, 'a multiline line' ];
is_deeply parse_line('', \@known), [ undef, ''];
is_deeply parse_line('>Unknown: value'      , \@known), [undef, '>Unknown: value'];
is_deeply parse_line('     multiline with initial spaces', \@known), [undef, '     multiline with initial spaces'];

my @run1 = ();
push @run1, @{ conn() }, @{ schema1() }, @{ querprep() }, @{ pr1() };

my $module = Test::MockObject::Extends->new('IO::Socket::INET');
$module->fake_new( 'IO::Socket::INET' );
$module->set_true( 'print' );
$module->set_series( 'getline', @run1 );

my $g = Net::Gnats->new();
$g->gnatsd_connect;
isa_ok my $pr = $g->get_pr_by_number('45'), 'Net::Gnats::PR';
is $pr->getNumber, '45';
is $pr->getField('Confidential'), 'yes';

done_testing;

sub conn {
  return [ "200 my.gnatsd.com GNATS server 4.1.0 ready.\r\n",
           "351-The current user access level is:\r\n",
           "350 admin\r\n",
         ];
}

# emulate receiving schema
sub schema1 {
  #fieldnames
  return [
          "301 List follows.\r\n",
          "Number\r\n",
          "Notify-List\r\n",
          "Category\r\n",
          "Synopsis\r\n",
          "Confidential\r\n",
          "Severity\r\n",
          "Priority\r\n",
          "Responsible\r\n",
          "State\r\n",
          "Class\r\n",
          "Submitter-Id\r\n",
          "Arrival-Date\r\n",
          "Closed-Date\r\n",
          "Last-Modified\r\n",
          "Originator\r\n",
          "Release\r\n",
          "Organization\r\n",
          "Environment\r\n",
          "Description\r\n",
          "How-To-Repeat\r\n",
          "Fix\r\n",
          "Release-Note\r\n",
          "Audit-Trail\r\n",
          "Unformatted\r\n",
          ".\r\n",

          #initialrequired
          "301 List follows.\r\n",
          ".\r\n",

          #initialinput
          "301 List follows.\r\n",
          "Submitter-Id\r\n",
          "Notify-List\r\n",
          "Originator\r\n",
          "Organization\r\n",
          "Synopsis\r\n",
          "Confidential\r\n",
          "Severity\r\n",
          "Priority\r\n",
          "Category\r\n",
          "Class\r\n",
          "Release\r\n",
          "Environment\r\n",
          "Description\r\n",
          "How-To-Repeat\r\n",
          "Fix\r\n",
          ".\r\n",

          #ftyp
          "350-Integer\r\n",
          "350-Text\r\n",
          "350-Enum\r\n",
          "350-Text\r\n",
          "350-Enum\r\n",
          "350-Enum\r\n",
          "350-Enum\r\n",
          "350-Enum\r\n",
          "350-Enum\r\n",
          "350-Enum\r\n",
          "350-Enum\r\n",
          "350-Date\r\n",
          "350-Date\r\n",
          "350-Date\r\n",
          "350-Text\r\n",
          "350-Text\r\n",
          "350-MultiText\r\n",
          "350-MultiText\r\n",
          "350-MultiText\r\n",
          "350-MultiText\r\n",
          "350-MultiText\r\n",
          "350-MultiText\r\n",
          "350-MultiText\r\n",
          "350 MultiText\r\n",

          #fdsc
          "350-PR Number\r\n",
          "350-Addresses to notify of significant PR changes\r\n",
          "350-What area does this PR fall into?\r\n",
          "350-One-line summary of the PR\r\n",
          "350-Yes/no flag indicating if the PR contents are confidential\r\n",
          "350-How severe is the PR?\r\n",
          "350-How critical is it that the PR be fixed?\r\n",
          "350-The user responsible for the PR\r\n",
          "350-The current state of the PR\r\n",
          "350-The type of bug\r\n",
          "350-Site-specific identification of the PR author\r\n",
          "350-Arrival date of the PR\r\n",
          "350-Date when the PR was closed\r\n",
          "350-Last modification date of the PR\r\n",
          "350-Name of the PR author\r\n",
          "350-Release number or tag\r\n",
          "350-Organization of PR author\r\n",
          "350-Machine, OS, target, libraries\r\n",
          "350-Precise description of the problem\r\n",
          "350-Code/input/activities to reproduce the problem\r\n",
          "350-How to correct or work around the problem, if known\r\n",
          "350-\r\n",
          "350-Log of specific changes to the PR\r\n",
          "350 Miscellaneous text that was not parsed properly\r\n",

          #inputdefault
          "350--1\r\n",
          "350-\r\n",
          "350-pending\r\n",
          "350-\r\n",
          "350-yes\r\n",
          "350-\r\n",
          "350-\r\n",
          "350-\r\n",
          "350-open\r\n",
          "350-sw-bug\r\n",
          "350-unknown\r\n",
          "350-\r\n",
          "350-\r\n",
          "350-\r\n",
          "350-\r\n",
          "350-\r\n",
          "350-\r\n",
          "350-\r\n",
          "350-\r\n",
          "350-\r\n",
          "350-\nUnknown\r\n",
          "350-\r\n",
          "350-\r\n",
          "350 \r\n",

          #fieldflags
          "350-readonly \r\n",
          "350-textsearch \r\n",
          "350-textsearch \r\n",
          "350-textsearch \r\n",
          "350-textsearch \r\n",
          "350-textsearch \r\n",
          "350-textsearch \r\n",
          "350-textsearch allowAnyValue requireChangeReason \r\n",
          "350-textsearch requireChangeReason \r\n",
          "350-textsearch \r\n",
          "350-textsearch \r\n",
          "350-readonly \r\n",
          "350-readonly \r\n",
          "350-readonly \r\n",
          "350-textsearch \r\n",
          "350-textsearch \r\n",
          "350-\r\n",
          "350-\r\n",
          "350-\r\n",
          "350-\r\n",
          "350-\r\n",
          "350-\r\n",
          "350-\r\n",
          "350 \r\n",];
}

# quer runs rset, qfmt, expr
# assume expr not set here.
sub querprep {
  return ["210 CODE_OK\r\n",
          "210 CODE_OK\r\n",];
}

sub pr1 {
  return ["300 PRs follow.\r\n",
          "From: Doctor Wifflechumps\r\n",
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
          ">Originator:     Doctor Wifflechumps\r\n",
          ">Release:        \r\n",
          ">Fix:\r\n",
          ">Unformatted:\r\n",
          "\r\n",
          ".\r\n",];
}

#Number Notify-List Category Synopsis Confidential Severity Priority Responsible State Class Submitter-Id Arrival-Date Closed-Date Last-Modified Originator Release Organization Environment Description How-To-Repeat Fix Release-Note Audit-Trail Unformatted
