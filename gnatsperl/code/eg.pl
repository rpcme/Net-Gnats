#!/usr/bin/perl -w

use strict;

use Net::Gnats;

main();

sub main{
    my $g = Net::Gnats->new();
    print "Connecting\n";
    $g->connect();
    print "getting DB names\n";
    my @dbNames = $g->getDBNames();
    print "driver found these dbs " .join(":",@dbNames) . "\n";
    print "Logging in\n";
    $g->login("default","mike","mike");

    

    print "Listing DBs\n";
    my @dbs = $g->listDatabases();
    foreach my $db (@dbs) {
        print $db->{name}."|";
        print $db->{desc}."|";
        print $db->{path};
        print "\n";
    }
    
    print "Listing Categories\n";
    @dbs = $g->listCategories();
    foreach my $db (@dbs) {
        print $db->{name}."|";
        print $db->{desc}."|";
        print $db->{contact}."|";
        print $db->{something} if defined $db->{something};
        print "\n";
    }
    
    #print "Making new PR\n";
    my $newPR = Net::Gnats::PR->new();
    $newPR->setField("Submitter-Id","developer");
    $newPR->setField("Originator","mike");
    $newPR->setField("Organization","Sycamore");
    $newPR->setField("Synopsis","Some bug from perlgnats");
    $newPR->setField("Confidential","no");
    $newPR->setField("Severity","serious");
    $newPR->setField("Priority","low");
    $newPR->setField("Category","MBZ");
    $newPR->setField("Class","sw-bug");
    $newPR->setField("Quarter","first");
    $newPR->setField("Release","mbz.2.1");
    $newPR->setField("Environment","Any");
    $newPR->setField("Description","Something bad happened");
    $newPR->setField("How-To-Repeat","I dunno");
    $newPR->setField("Fix","Beats me");
    #$g->submitPR($newPR);


    print "Searching for all PRs\n";
    my @bugsNums = $g->query('Number>"12"');
    print "Found ". join(":",@bugsNums)."\n";     
 

    print "Getting a PR\n";
    my $PRtwo = $g->getPRByNumber(2);
    #print $PRtwo->asString();
    



    print "Disconnecting\n";
    $g->disconnect();
}
