#!/tools/perl/5.8.0/sun4u-5.6/bin/perl -w

use strict;

use lib "/home/jims/sf/gnatsperl/gnatsperl/code";
use Net::Gnats;

$Net::Gnats::debugGnatsd = 0;
my $host = "gnats";
my $port = "1530";
my $db   = "yourDB";
my $user = "gnats";
my $pw   = "";

main();

sub showList {
  my $keys = shift;
  foreach my $d (@_) {
    my $s = "";
    foreach my $k (@$keys) {
      printf("%s%s",$s,(defined($d->{$k}) ? $d->{$k} : ""));
      $s = "|";
    }
    print "\n";
  }
}

sub main{

  my $sep = "\n\n************************************************************************\n";
  my $g = Net::Gnats->new($host,$port);
  print "Connecting\n";
  $g->connect() || die;

  print "$sep\ngetting DB names\n";
  my @dbNames = $g->getDBNames();
  print "driver found these dbs " .join(":",@dbNames) . "\n";

  print "$sep\nLogging in to db $db as user $user\n";
  if (! $g->login($db,$user,$pw) ) {
    die $g->getErrorMessage;
  }

  print "$sep\nListing DBs\n";
  showList([qw(name desc path)],$g->listDatabases());

  print "$sep\nListing Categories\n";
  showList([qw(name desc contact something)],$g->listCategories());

  print "$sep\nListing Submitters\n";
  showList([qw(name desc contract something1 responsible)],$g->listSubmitters());

  print "$sep\nListing Responsible\n";
  showList([qw(name realname email)],$g->listResponsible());

  print "$sep\nListing States\n";
  showList([qw(name type desc)],$g->listStates());

  #print "$sep\nListing Classes\n";
  #showList([qw(name desc)],$g->listClasses());

  print "$sep\nMaking new PR\n";
  my $newPR = $g->newPR();
  $g->filloutPR($newPR);
  $newPR->setField("Category","test") if $g->isValidField("Category");
  # My dbconfig has input-default "" for Priority and Severity
  # so I have to set them
  $newPR->setField("Priority","low") if $g->isValidField("Priority");
  $newPR->setField("Severity","non-critical") if $g->isValidField("Severity");
  $newPR->setField("Class","sw-bug") if $g->isValidField("Class");
  # Put in some other info.
  $newPR->setField("Synopsis","Some bug from ".'$Id$ ');
  $newPR->setField("Description","Something bad happened");
  $newPR->setField("How-To-Repeat","I dunno") if $g->isValidField("How-To-Repeat");
  $newPR->setField("Fix","Beats me") if $g->isValidField("Fix");

  $newPR->setField("Responsible","xyzzy");
  $newPR->setField("Originator","broadcom");

  print "$sep\nChecking new PR:\n",$newPR->asString;
  my $checkRC = $g->checkNewPR($newPR->asString());
  if ($checkRC) {
    print "\nCheckNew ok\n";
  } else {
    print "\nCheckNew Failed\n";
    print $g->getErrorCode().": ".$g->getErrorMessage()."\n";
  }

  if ($g->submitPR($newPR)) {
    print "\nSubmitNew ok\n";
  } else {
    print "\nSubmitNew Failed\n";
    print $g->getErrorCode().": ".$g->getErrorMessage()."\n";
  }

  print "$sep\nSearching for all PRs\n";
  #my @bugsNums = $g->query('Number>"12"', 'Category="MBZ"');
  my @bugsNums = $g->query();

  print "Found ",($#bugsNums + 1)," reports: ",join(":",@bugsNums),"\n";

  if ($#bugsNums >= 0 and $bugsNums[0] ne "") {
    # Assume the last one in the list is the new PR.
    my $newPRNum = $bugsNums[$#bugsNums];
    print "$sep\nGetting PR ",$newPRNum,"\n";
    my $pr = $g->getPRByNumber($newPRNum);
    if ($newPRNum == $pr->getField("Number")) {
      print "GetPR ok\n";
    } else {
      print "GetPR Failed\n";
      print $g->getErrorCode().": ".$g->getErrorMessage()."\n";
    }
    $pr->setField('Description','gnatsperl eg.pl modified description');

    print "$sep\nChecking an existing PR ",$pr->getField("Number"),"\n";
    my $check = $g->checkPR($pr->asString);
    if ($check) {
      print "Checked ok\n";
    } else {
      print "Check Failed\n";
      print $g->getErrorCode().": ".$g->getErrorMessage()."\n";
    }

    # replaceField
    print "$sep\nReplacing a field\n";
    if ($g->replaceField($newPRNum,"Synopsis","Test changing of synopsis")) {
      print "\nReplaceField ok\n";
    } else {
      print "\nReplaceField Failed\n";
      print $g->getErrorCode().": ".$g->getErrorMessage()."\n";
    }

  }

  print "$sep\nDisconnecting\n";
  $g->disconnect();

}
