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
                     "211 CODE_SEND_PR\r\n",
                     "210 CODE_OK\r\n",
                   );

my $g = Net::Gnats->new();
$g->gnatsd_connect;

# should checkout OK
is $g->check_pr(pr1(), 'initial'), 1,     'initial PR checks';

done_testing();


sub pr1 {
  return <<PR1;
To: bugs
CC:
Subject: Your product sucks
From: riche\@cpan.org
Reply-To: riche\@cpan.org
X-Send-Pr-Version: Net::Gnats-5

> Synopsis: A great synopsis
> Priority: high
PR1
}

# CHEK fails because state enum value is unknown
# CODE_INVALID_ENUM
sub pr2 {
return <<PR2;
To: bugs
CC:
Subject: Your product sucks
From: riche\@cpan.org
Reply-To: riche\@cpan.org
X-Send-Pr-Version: Net::Gnats-5

>State: unknown
PR2
}

# This PR, we should get two errors back -
# one for State
# one for Priority
# Result:
# 411-There is a bad value `unknown' for the field `State'.
# 411 There is a bad value `unknown' for the field `Priority'.
# 403 Errors found checking PR text.

sub pr3 {
  return <<PR3;
To: bugs
CC:
Subject: Your product sucks
From: rich\@richelberger.com
Reply-To: rich\@richelberger.com
X-Send-Pr-Version: Net::Gnats-5

>Number: 1
>State: unknown
>Priority: unknown
PR3
}
