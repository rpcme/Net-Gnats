package Net::Gnats;

require 5.005_62;
use strict;
use warnings;

require Exporter;
require Net::Gnats::PR;
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
    new	
);
our $VERSION = '0.02';


use strict;
use Carp;
use Socket;
use IO::Handle;


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

    my $host = shift;
    my $port = shift;
    $host = "localhost" if not defined $host;
    $port = "1529" if not defined $port;
    $self->{hostAddr} = $host;
    $self->{hostPort} = $port;
    
    $self->{fieldNames} = undef;
    
    $self->{lastCode} = undef;
    $self->{lastResponse} = undef;
    $self->{errorCode} = undef;
    $self->{errorMessage} = undef;

    return $self;

}


sub connect {
    my $self = shift;
    my $iaddr;
    my $paddr;
    my $proto;

    #TODO disconnect if already connected

    if (!($iaddr = inet_aton($self->{hostAddr}))) {
        carp("Unknown GNATS host '$self->{hostAddr}'");
        return 0;
    }
    $paddr = sockaddr_in($self->{hostPort}, $iaddr);
    $proto = getprotobyname('tcp');
    if(!socket(SOCK, PF_INET, SOCK_STREAM, $proto)) {
        warn("gnatsweb: client_init error: $!");
        return 0;
    }
    if(!connect(SOCK, $paddr))
    {
        warn("gnatsweb: client_init error: $! ;");
        return 0;
    }
    SOCK->autoflush(1);
    $self->_getGnatsdResponse();
    return 1;
}




sub disconnect {
    my $self = shift;
    $self->_doGnatsCmd("QUIT");
    #$self->{connection}->print("QUIT");
    #$self->{connection} = undef;
}
    
sub getDBNames {
    my $self = shift;
    my $code;
    my $response;

    ($code, $response) = $self->_doGnatsCmd("DBLS");
    if ($self->_isCodeOK($code)) {
        return $self->_extractListContent($response);
    } else {
        $self->_markError($code, $response);
        return undef;
    }
    
}


sub listDatabases {
    my $self = shift;
    my @dbs = $self->_list("DATABASES", qw(name desc path));
    return @dbs;
}


sub listCategories {
    my $self = shift;
    my @cats = $self->_list("CATEGORIES", qw(name desc contact something));
    return @cats;
}

sub listSubmitters {
    my $self = shift;
    my @cats = $self->_list("SUBMITTERS", 
                    qw(name desc contract something1 responsible));
    return @cats;
}

sub listResponsible {
    my $self = shift;
    my @cats = $self->_list("RESPONSIBLE", qw(name realname email));
    return @cats;
}

sub listStates {
    my $self = shift;
    my @cats = $self->_list("STATES", qw(name type desc));
    return @cats;
}


sub listClasses {
    my $self = shift;
    my @cats = $self->_list("CLASSES", qw(name desc));
    return @cats;
}

sub listFieldNames {
    my $self = shift;
    my @cats = $self->_list("FIELDNAMES", qw(name));
    return @cats;
}

sub listInitialInputFields {
    my $self = shift;
    my @cats = $self->_list("INITIALINPUTFIELDS", qw(name));
    return @cats;
}

sub getFieldType {
    my $self = shift;
    my $field = shift;
    my $code; my $response;
    ($code, $response) = $self->_doGnatsCmd("FTYP $field");
    if ($self->_isCodeOK($code)) {
        return $response;
    } else {
        $self->_markError($code, $response);
        return undef;
    }
}

sub getFieldTypeInfo { 
    my $self = shift;
    my $field = shift;
    my $property = shift;
    my $code; my $response;
    ($code, $response) = $self->_doGnatsCmd("FTYPINFO $field $property");
    if ($self->_isCodeOK($code)) {
        return $response;
    } else {
        $self->_markError($code, $response);
        return undef;
    }
}


sub getFieldDesc {
    my $self = shift;
    my $field = shift;
    my $code; my $response;
    ($code, $response) = $self->_doGnatsCmd("FDSC $field");
    if ($self->_isCodeOK($code)) {
        return $response;
    } else {
        $self->_markError($code, $response);
        return undef;
    }
}

sub getFieldFlags {
    my $self = shift;
    my $field = shift;
    my $code; my $response;
    ($code, $response) = $self->_doGnatsCmd("FIELDFLAGS $field");
    if ($self->_isCodeOK($code)) {
        return $response;
    } else {
        $self->_markError($code, $response);
        return undef;
    }
}

sub getFieldValidators {
    my $self = shift;
    my $field = shift;
    my $code; my $response;
    ($code, $response) = $self->_doGnatsCmd("FVLD $field");
    if ($self->_isCodeOK($code)) {
        my @validators = $self->_extractListContent($response);
        return @validators;
    } else {
        $self->_markError($code, $response);
        return undef;
    }
}


sub validateField {
    my $self = shift;
    my $field = shift;
    my $input = shift;
    my $code; my $response;
    ($code, $response) = $self->_doGnatsCmd("VFLD $field");
    if ($self->_isCodeOK($code)) {
        ($code, $response) = $self->_doGnatsCmd($input."\n".".");
        if ($self->_isCodeOK($code)) {
            return 1;
        } else {
            $self->_markError($code, $response);
            return 0;
        } 
    } else {
        $self->_markError($code, $response);
        return 0;
    }
}

sub getFieldDefault {
    my $self = shift;
    my $field = shift;
    my $code; my $response;
    ($code, $response) = $self->_doGnatsCmd("INPUTDEFAULT $field");
    if ($self->_isCodeOK($code)) {
        return $response;
    } else {
        $self->_markError($code, $response);
        return undef;
    } 
}


sub resetServer {
    my $self = shift;
    my $code; my $response;
    ($code, $response) = $self->_doGnatsCmd("RSET");
    if ($self->_isCodeOK($code)) {
        return 1;
    } else {
        $self->_markError($code, $response);
        return 0;
    }
}


sub lockMainDatabase {
    my $self = shift;
    my $code; my $response;
    ($code, $response) = $self->_doGnatsCmd("LKDB");
    if ($self->_isCodeOK($code)) {
        return 1;
    } else {
        $self->_markError($code, $response);
        return 0;
    }
}

sub unlockMainDatabase {
    my $self = shift;
    my $code; my $response;
    ($code, $response) = $self->_doGnatsCmd("UNDB");
    if ($self->_isCodeOK($code)) {
        return 1;
    } else {
        $self->_markError($code, $response);
        return 0;
    }
}


sub lockPR {
    my $self = shift;
    my $pr = shift;
    my $user = shift;
    my $code; my $response;
    ($code, $response) = $self->_doGnatsCmd("LOCK $pr $user");
    if ($self->_isCodeOK($code)) {
        return 1;  #XXX extract PR ?
    } else {
        $self->_markError($code, $response);
        return 0;
    }
}

sub unlockPR {
    my $self = shift;
    my $pr = shift;
    my $code; my $response;
    ($code, $response) = $self->_doGnatsCmd("UNLK $pr");
    if ($self->_isCodeOK($code)) {
        return 1;
    } else {
        $self->_markError($code, $response);
        return 0;
    }
}


sub deletePR { 
    my $self = shift;
    my $pr = shift;
    my $code; my $response;
    ($code, $response) = $self->_doGnatsCmd("DELETE $pr");
    if ($self->_isCodeOK($code)) {
        return 1;
    } else {
        $self->_markError($code, $response);
        return 0;
    }
}

sub checkNewPR {
    my $self = shift;
    my $pr = shift;
    my $code; my $response;
    ($code, $response) = $self->_doGnatsCmd("CHEK initial");
    if ($self->_isCodeOK($code)) {
        ($code, $response) = $self->_doGnatsCmd("$pr\n.");
        if ($self->_isCodeOK($code)) {
            return 1;
        } else {
        $self->_markError($code, $response);
        return 0;
        }
    } else {
        $self->_markError($code, $response);
        return 0;
    }
}


sub setWorkingEmail {
    my $self = shift;
    my $email = shift;
    my $code; my $response;
    ($code, $response) = $self->_doGnatsCmd("EDITADDR $email");
    if ($self->_isCodeOK($code)) {
        return 1;
    } else {
        $self->_markError($code, $response);
        return 0;
    }
}


sub replaceField {
    my $self = shift;
    my $pr = shift;
    my $field = shift;
    my $input = shift;
    my $code; my $response;
    ($code, $response) = $self->_doGnatsCmd("REPL $pr $field");
    if ($self->_isCodeOK($code)) {
        ($code, $response) = $self->_doGnatsCmd($input."\n".".");
        if ($self->_isCodeOK($code)) {
            return 1;
        } else {
            $self->_markError($code, $response);
            return 0;
        } 
    } else {
        $self->_markError($code, $response);
        return 0;
    }
}


sub appendToField {
    my $self = shift;
    my $pr = shift;
    my $field = shift;
    my $input = shift;
    my $code; my $response;
    ($code, $response) = $self->_doGnatsCmd("APPN $pr $field");
    if ($self->_isCodeOK($code)) {
        ($code, $response) = $self->_doGnatsCmd($input."\n".".");
        if ($self->_isCodeOK($code)) {
            return 1;
        } else {
            $self->_markError($code, $response);
            return 0;
        } 
    } else {
        $self->_markError($code, $response);
        return 0;
    }
}


sub submitPR {
    my $self = shift;
    my $pr = shift;
    
    my %prHash = $pr->asHash();
    my $prString;
    foreach my $key (keys %prHash) {
        #print "Adding line| >$key: ".$prHash{$key}."\n";
        $prString .= ">$key: ".$prHash{$key}."\n";
    }

    my $code; my $response;
    ($code, $response) = $self->_doGnatsCmd("SUBM");
    if ($self->_isCodeOK($code)) {
        ($code, $response) = $self->_doGnatsCmd($prString."\n".".");
        if ($self->_isCodeOK($code)) {
            return 1;
        } else {
            $self->_markError($code, $response);
            return 0;
        }
    } else {
        $self->_markError($code, $response);
        return 0;
    }
    
    
}




sub getPRByNumber { 
    my $self = shift;
    my $num = shift;

    my ($code, $response) = $self->_doGnatsCmd("RSET");
    if (not $self->_isCodeOK($code)) {
        $self->_markError($code, $response);
        return undef;
    }
    
    ($code, $response) = $self->_doGnatsCmd("QFMT full");
    if (not $self->_isCodeOK($code)) {
        $self->_markError($code, $response);
        return undef;
    }

    ($code, $response) = $self->_doGnatsCmd("QUER $num");
    if (not $self->_isCodeOK($code)) {
        $self->_markError($code, $response);
        return undef;
    }

    my $pr = Net::Gnats::PR->new();
    $pr->setFromString($response);
    
    return $pr; 
}


sub expr {
    my $self = shift;
    my @exprs = @_;

    my ($code, $response);
    foreach my $expr (@exprs) {
        ($code, $response) = $self->_doGnatsCmd("EXPR $expr");
    }
    return $code; #XXX TODO and codes together or abort or something
} 

sub query { 
    my $self = shift;
    my @exprs = @_;
   
    my ($code, $response) = $self->_doGnatsCmd("RSET"); #XXX TODO  
    if (not $self->_isCodeOK($code)) {
        $self->_markError($code, $response);
        return undef;
    }
    
    ($code, $response) = $self->_doGnatsCmd("QFMT Number"); #XXX TODO  
    if (not $self->_isCodeOK($code)) {
        $self->_markError($code, $response);
        return undef;
    }
    
    foreach my $expr (@exprs) {
        ($code, $response) = $self->_doGnatsCmd("EXPR $expr"); 
        if (not $self->_isCodeOK($code)) {
            $self->_markError($code, $response);
            return undef;
        }
    }

    my @nums;
    ($code, $response) = $self->_doGnatsCmd("QUER");
    if ($self->_isCodeOK($code)) {
        @nums = $self->_extractListContent($response);
    } else {
        $self->_markError($code, $response);
        return undef;
    }
    return @nums;
}



sub admv { #???
}




sub _list {
    my $self = shift;
    my $listType = shift;
    my @keyNames = @_;
    my $code;
    my $response;

    ($code, $response) = $self->_doGnatsCmd("LIST $listType");
    if ($self->_isCodeOK($code)) {
        my @rawRows = $self->_extractListContent($response);
        my @rows;
        foreach my $row (@rawRows) {
            push @rows, $self->_convertGnatsRecordToHashRef($row, @keyNames);
        }
        return @rows;
    } else {
        $self->_markError($code, $response);
        return undef;
    }
}



sub _convertGnatsRecordToHashRef {
    my $self = shift;
    my $recString = shift;
    my @keyNames = @_;


    #print "converting $recString\n";
    my $hash;
    my @rec = split /:/, $recString;
    for (my $i=0; $i<scalar(@rec); $i++) {
        $hash->{$keyNames[$i]} = $rec[$i];
    }
    return $hash;
}
    

sub login {
    my $self = shift;
    my $db = shift;
    my $user = shift;
    my $pass = shift;
    
    my $code;
    my $response;

    ($code, $response) = $self->_doGnatsCmd("CHDB $db $user $pass");
    if ($self->_isCodeOK($code)) {
        return 1;
    } else {
        $self->_markError($code, $response);
        return 0;
    } 
}


sub getErrorCode {
    my $self = shift;
    return $self->{errorCode};
}

sub getErrorMessage {
    my $self = shift;
    return $self->{errorMessage};
}



sub _doGnatsCmd {
    my $self = shift;
    my $cmd = shift;
    
    $self->_clearError();  
    #print "sending |$cmd\n|\n";
    print SOCK "$cmd\n";
    my $response = $self->_getGnatsdResponse();
    #print "received |$response|\n";

    my $bugstring="411 There is a bad value";
    <SOCK> if $response =~/^$bugstring/;

    my $code;
    $code = $self->_extractResponseCode($response);
    $self->{lastCode} = $code;
    $self->{lastResponse} = $response;
    
    #print "CODE $code: $response\n";
    return ($code, $response);
    
}

sub _getGnatsdResponse
{   
    my $self = shift;
    my @lines;
    my $isMultiLineResponse = 0;

    while  (1) {
        my $line = <SOCK>;
        
        #print "READ >>$line<<\n";

        #if response code is in 300-399 range, then go until "." line
        if ($line =~ /^3\d\d /) {
            $isMultiLineResponse = 1;
        } elsif ($isMultiLineResponse and $line =~/^\.\r/) {
            push @lines, ".\n";
            last; 
        }

        # Lines which begin with a '.' are escaped by gnatsd with another '.'
        $line =~ s/^\.\././;
        
        push @lines, $line; #add current line to the list of response lines

        # a line that ends "\d\d\d " is a last line
        if ($line =~ /^(\d)\d\d .*/) {
            if ($1!=3) { #unless it's 3xx, then more data is coming
                last;
            }
        }
    }
    my $allLines = join ("", @lines);  
    return $allLines;

}   




sub _extractResponseCode {
    my $self = shift;
    my $response = shift;
    
    my $code;
    
    if ($response =~ /^(\d\d\d)( |-)/s) {
        $code = $1;
    } else {
        warn "Could not parse gnatsd response\n";
        return undef; #FIXME a little better here    
    }
  
    return $code;
}

sub _extractListContent {
    my $self = shift;
    my $response = shift;

    my @lines = split /\r\n/, $response;
    shift @lines; # first item is the response message
    pop @lines; #last item is the "."
    return @lines;
}
    






sub _isCodeOK {
    my $self = shift;
    my $code = shift;

    if (($code =~ /2\d\d/) or ($code =~ /3\d\d/)) {
        return 1;
    } else {
        return 0;
    }
}


sub _clearError {
    my $self = shift;
    $self->{errorCode} = undef;
    $self->{errorMessage} = undef;
}


sub _markError {
    my $self = shift;
    my $code = shift;
    my $msg = shift;
    $self->{errorCode} = $code;
    $self->{errorMessage} = $msg;
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
