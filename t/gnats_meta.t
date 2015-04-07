use strict;
use warnings;
use Test::More;
use Test::MockObject;
use Test::MockObject::Extends;
use Net::Gnats;
use File::Basename;
use lib dirname(__FILE__);
use Gtdata;

my @dataset = qw(getline);
push @dataset, @{ Gtdata::connect() };
push @dataset, @{ Gtdata::list_inputfields_initial_1() };
push @dataset, @{ Gtdata::list_inputfields_required_1() };
push @dataset, @{ Gtdata::list_fieldnames_1() };
push @dataset, @{ Gtdata::list_ftyp_1() };
push @dataset, @{ Gtdata::list_fdsc_1() };
push @dataset, @{ Gtdata::list_inputdefault_1() };
push @dataset, @{ Gtdata::list_fieldflags_1() };
push @dataset, @{ Gtdata::list_fvld_1() };

my $module = Test::MockObject::Extends->new('IO::Socket::INET');
$module->fake_new( 'IO::Socket::INET' );
$module->set_true( 'print' );
$module->set_series( @dataset );

my $g = Net::Gnats->new();
$g->gnatsd_connect;

$g->init_db_meta;
#is_deeply $g->init_db_meta->{f_initial},
#  Gtdata::list_inputfields_initial_1(),'can_initialize';
done_testing();
