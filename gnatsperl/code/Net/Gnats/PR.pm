package Net::Gnats::PR;

require 5.005_62;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::Gnats ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.02';




#******************************************************************************
# Sub: new
# Description: Constructor
# Args: hash (parameter list) 
# Returns: self
#******************************************************************************
sub new 
{   
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless($self, $class);

    $self->{number} = undef;
    $self->{fields} = undef;

    return $self;
}


#the only field we'll track specifically
sub setNumber { 
    my $self = shift; 
    $self->{number} = shift; 
}
sub getNumber { 
    my $self = shift; 
    return $self->{number};
}


sub setField {
    my $self = shift; 
    my $field = shift; 
    my $value = shift;
    $self->{fields}->{$field}=$value;
}
sub getField {
    my $self = shift;
    my $field = shift;
    return $self->{fields}->{$field};
}

sub getKeys {
    my $self = shift;
    return keys(%{$self->{fields}});
}

sub asHash {
    my $self = shift;
    return %{$self->{fields}}; #XXX Deep copy?
}

sub asString {
    my $self = shift;
    my $stringRep="";

    if (defined $self->getNumber() ) { # number first if exists
        $stringRep.=">Number: ".$self->getNumber()."\n";
    }
    foreach my $key (keys %{$self->{fields}}) {
        $stringRep .=">$key: ".$self->{fields}->{$key}."\n";
    }
    return $stringRep;
}

sub setFromString {
    my $self = shift;
    my $PRstring = shift;


    my @byFields = split /^>/m, $PRstring;
    
    my $containsNumber = grep (/^Number/, @byFields);

    #get rid of lines  precedeing Number
    if ($containsNumber) {
        while ($byFields[0] !~ /^Number/ ) {
            #print "Dropping line |".$byFields[0]."|\n";
            shift @byFields;
        }
    }
    
    foreach my $line (@byFields) {
        #extract field name and value
       if ($line =~ /^(\S*)\:(\s|\n)*(.*)\X*$/ms) {
            my $field = $1;
            my $val = $3;
                #get rid of trailing cr/lf
            if ($val =~ /(.*)\015\012$/ms) {
                $val = $1;
            }
            #print "setting |$field| with |$val|\n";
            if ($field eq 'Number') {  #XXX TODO don't hard code
                $self->setNumber($val);
            } else {
                $self->setField($field, $val);
            }
        }    
    }        
}
    




# preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Net::Gnats - Perl interface to GNU Gnats daemon

=head1 SYNOPSIS

  use Net::Gnats;
  my $g = Net::Gnats->new();
  $g->connect();
  my @dbNames = $g->getDBNames();
  $g->login("default","somedeveloper","password");
  my $PRtwo = $g->getPRByNumber(2);
  print $PRtwo->asString();
  my $newPR = Net::Gnats::PR->new();
  $newPR->setField("Submitter-Id","developer");
  $g->submitPR($newPR);
  $g->disconnect();


=head1 ABSTRACT

Net::Gnats provides a perl interface to the gnatsd command set.  Although 
most of the gnatsd command are present and can be explicitly called through
Net::Gnats, common gnats tasks can be accompished through some methods 
which simplify the process (especially querying the database, editing bugs,
etc). 

The current version of Net::Gnats (as well as related information) is 
available at http://gnatsperl.sourceforge.net/

=head1 COMMON TASKS


=head2 VIEWING DATABASES

Fetching database names is the only action that can be done on a Gnats 
object before logging in via the login() method.  

  my $g = Net::Gnats->new();
  $g->connect();
  my @dbNames = $g->getDBNames();

Note that getDBNames() is different than listDatabases(), which requires 
logging in first and gets a little more info than just names.

 
=head2 LOGGING IN TO A DATABASE

The Gnats object has to be logged into a database to perform almost all
actions.  

  my $g = Net::Gnats->new();
  $g->connect();
  $g->login("default","myusername","mypassword");


=head2 SUBMITTING A NEW PR

The Net::Gnats::PR object acts as a container object to store information
about a PR (new or otherwise).  A new PR is submitted to gnatsperl by 
constructing a PR object.

  my $newPR = Net::Gnats::PR->new();
  $newPR->setField("Submitter-Id","developer");
  $newPR->setField("Originator","Doctor Wifflechumps");
  $newPR->setField("Organization","GNU");
  $newPR->setField("Synopsis","Some bug from perlgnats");
  $newPR->setField("Confidential","no");
  $newPR->setField("Severity","serious");
  $newPR->setField("Priority","low");
  $newPR->setField("Category","gnatsperl");
  $newPR->setField("Class","sw-bug");
  $newPR->setField("Description","Something terrible happened");
  $newPR->setField("How-To-Repeat","Like this.  Like this.");
  $newPR->setField("Fix","Who knows");
  $g->submitPR($newPR);

Obviously, fields are dependent on a specific gnats installation, since 
Gnats administrators can rename fields and add constraints.  There are some
methods in Net::Gnats to discover field names and constraints, all described
below. 

Instead of setting each field of the PR individually, the setFromString()
method is available.  The string that is passed to it must be formatted
in the way Gnats handles the PRs.  This is useful when handling a Gnats
email submission ($newPR->setFromString($email)) or when reading a PR file
directly from the database.  See Net::Gnats::PR for more details.


=head2 QUERYING THE PR DATABASE

  my @prNums = $g->query('Number>"12"', "Category=\"$thisCat\"");
  print "Found ". join(":",@prNums)." matching PRs \n";

Pass a list  of query expressions to query().  A list of PR numbers of 
matching PRs is returned.  You can then pull out each PR as described next.


=head2 FETCHING A PR

  my $prnum = 23;  
  my $PR = $g->getPRByNumber($prnum);
  print $PR->getField('synopsis');
  print $PR->asString();

The method getPRByNumber() will return a Net::Gnats::PR object corresponding
to the PR num that was passed to it.  The getField() and asString() methods
are documented in Net::Gnats::PR, but I will note here that asString() 
returns a string in the proper Gnats format, and can therefore be submitted 
directly to Gnats via email or saved to the db directory for instance.  Also,
$newPR->setFromString( $oldPR->asString() ) works fine and will result in 
a duplicate of the original PR object.


=head1 HANDLING ERRORS

Most methods will return undef if a major error is encountered.  

The most recent error codes and messages which Net::Gnats encounters while
communcating with gnatsd are stored, and can be accessed with the 
getErrorCode() and getErrorMessage() methods.   


=head1 METHOD DESCRIPTIONS


=head2 new()

Constructor, optionally taking one or two arguments of hostname and port 
of the target gnats server.  If not supplied, the hostname defaults to
localhost and the port to 1529.

=head2 connect()

Connects to the gnats server.  No arguments.  Returns true if successfully
connected, false otherwise.


=head2 disconnect()

Issues the QUIT command to the Gnats server, therby closing the connection.

=head2 getDBNames()

Issues the DBLS command, and returns a list of database names in the gnats
server.  Unlike listDatabases, one does not need to use the logn method 
before using this method.

=head2 listDatabases()

Issues the LIST DATABASES command, and returns a list of hashrefs with keys
'name', 'desc', and 'path'.  

=head2 listCategories()

Issues the LIST CATEGORIES command, and returns a list of hashrefs with keys
'name', 'desc', 'contact', and '?'.  

=head2 listSubmitters()

Issues the LIST SUBMITTERS command, and returns a list of hashrefs with keys
'name', 'desc', 'contract', '?', and 'responsible'.  

=head2 listRepsonsible()

Issues the LIST RESPONSIBLE command, and returns a list of hashrefs with keys
'name', 'realname', and 'email'.  

=head2 listStates()

Issues the LIST STATES command, and returns a list of hashrefs with keys
'name', 'type', and 'desc'.  

=head2 listClasses()

Issues the LIST CLASSES command, and returns a list of hashrefs with keys
'name', and 'desc'.  

=head2 listFieldNames()

Issues the LIST FIELDNAMES command, and returns a list of hashrefs with key
'name'.

=head2 listInitialInputFields()

Issues the LIST INITIALINPUTFIELDS command, and returns a list of hashrefs 
with key 'name'.

=head2 getFieldType()

Expects a fieldname as sole argument, and issues the FTYP command.  Returns
text response or undef if error.

=head2 getFieldTypeInfo()

Expects a fieldname and property as arguments, and issues the FTYPINFO 
command.  Returns text response or undef if error.

=head2 getFieldDesc()

Expects a fieldname as sole argument, and issues the FDSC command.  Returns
text response or undef if error.

=head2 getFieldFlags()

Expects a fieldname as sole argument, and issues the FIELDFLAGS command.  
Returns text response or undef if error.

=head2 getFieldValidators()

Expects a fieldname as sole argument, and issues the FVLD command.  Returns 
text response or undef if error.

=head2 validateField()

Expects a fieldname and a proposed value for that field as argument, and 
issues the VFLD command.  Returns true if propose value is acceptable, false
otherwise.  

=head2 getFieldDefault()

Expects a fieldname as sole argument, and issues the INPUTDEFAULT command.  
Returns text response or undef if error.

=head2 resetServer()

Issues the RSET command, returns true if successful, false otherwise.

=head2 lockMainDatabase()

Issues the LKDB command, returns true if successful, false otherwise.

=head2 unlockMainDatabase()

Issues the UNDB command, returns true if successful, false otherwise.

=head2 lockPR()

Expects a PR number and user name as arguments, and issues the LOCK 
command.  Returns true if PR is successfully locked, false otherwise.  

=head2 unlockPR()

Expects a PR number a sole argument, and issues the UNLK command.  Returns 
true if PR is successfully unlocked, false otherwise.  

=head2 deletePR()

Expects a PR number a sole argument, and issues the DELETE command.  Returns 
true if PR is successfully deleted, false otherwise.  

=head2 checkPR()

Expects the text representation of a PR (see COMMON TASKS above) as input 
and issues the CHEK initial command.  Returns true if the given PR is a
valid entry, false otherwise.

=head2 setWorkingEmail()

Expects an email address as sole argument, and issues the EDITADDR command.  
Returns true if email successfully set, false otherwise.  

=head2 replaceField()

Expects a PR number, a fieldname, and a replacement value as arguments, and
issues the REPL command.  Returns true if field successfully replaced, 
false otherwise.

=head2 appendToField()

Expects a PR number, a fieldname, and a append value as arguments, and
issues the APPN command.  Returns true if field successfully appended to, 
false otherwise.

=head2 submitPR()

Expect a Gnats::PR object as sole argument, and issues the SUMB command.  
Returns true if PR successfully submitted, false otherwise.

=head2 getPRByNumber()

Expects a number as sole argument.  Returns a Gnats::PR object.

=head2 query()

Expects one or more query expressions as argument(s).  Returns a list of
PR numbers.

=head2 login()
 
Expects a database name, user name, and password as arguments and issues the 
CHDB command.  Returns true if successfully logged in, false otherwise


=head1 BUGS

Bug reports are very welcome.  Please submit to the project page 
(noted below).


=head1 AUTHOR

Mike Hoolehan, <lt>mike@sycamore.us<gt>
Project hosted at sourceforge, at http://gnatsperl.sourceforge.net



=head1 COPYRIGHT

Copyright (c) 1997-2001, Mike Hoolehan. All Rights Reserved.
This module is free software. It may be used, redistributed,
and/or modified under the same terms as Perl itself.


=cut

