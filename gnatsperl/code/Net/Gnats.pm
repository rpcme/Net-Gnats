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
our $VERSION = '0.01';


use strict;
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

    return $self;

}


sub connect {
    my $self = shift;
    my $iaddr;
    my $paddr;
    my $proto;

    #TODO disconnect if already connected

    if (!($iaddr = inet_aton($self->{hostAddr}))) {
        print("Unknown GNATS host '$self->{hostAddr}'");
        exit();
    }
    $paddr = sockaddr_in($self->{hostPort}, $iaddr);
    $proto = getprotobyname('tcp');
    if(!socket(SOCK, PF_INET, SOCK_STREAM, $proto)) {
        warn("gnatsweb: client_init error: $!". print_stacktrace());
        exit();
    }
    if(!connect(SOCK, $paddr))
    {
        warn("gnatsweb: client_init error: $! ;". print_stacktrace());
        exit();
    }
    SOCK->autoflush(1);
    $self->_getGnatsdResponse();
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
    }
    #FIXME what if not ok?
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
    #FIXME what if not ok?
}

sub listSubmitters {
    my $self = shift;
    my @cats = $self->_list("SUBMITTERS", 
                    qw(name desc contract something1 responsible));
    return @cats;
    #FIXME what if not ok?
}

sub listResponsible {
    my $self = shift;
    my @cats = $self->_list("RESPONSIBLE", qw(name realname email));
    return @cats;
    #FIXME what if not ok?
}

sub listStates {
    my $self = shift;
    my @cats = $self->_list("STATES", qw(name type desc));
    return @cats;
    #FIXME what if not ok?
}


sub listClasses {
    my $self = shift;
    my @cats = $self->_list("CLASSES", qw(name desc));
    return @cats;
    #FIXME what if not ok?
}

sub listFieldNames {
    my $self = shift;
    my @cats = $self->_list("FIELDNAMES", qw(name));
    return @cats;
    #FIXME what if not ok?
}

sub listInitialInputFields {
    my $self = shift;
    my @cats = $self->_list("INITIALINPUTFIELDS", qw(name));
    return @cats;
    #FIXME what if not ok?
}

sub getFieldType {
    my $self = shift;
    my $field = shift;
    my $code; my $response;
    ($code, $response) = $self->_doGnatsCmd("FTYP $field");
    return $response; #TODO parse?
    #FIXME what if not ok?
}

sub getFieldTypeInfo { #NOT IMPLEMENTED
    my $self = shift;
    my $field = shift;
}


sub getFieldDesc {
    my $self = shift;
    my $field = shift;
    my $code; my $response;
    ($code, $response) = $self->_doGnatsCmd("FDSC $field");
    return $response; #TODO parse?
    #FIXME what if not ok?
}

sub getFieldFlags {
    my $self = shift;
    my $field = shift;
    my $code; my $response;
    ($code, $response) = $self->_doGnatsCmd("FIELDFLAGS $field");
    return $response; #TODO parse?
    #FIXME what if not ok?
}

sub getFieldValidators {
    my $self = shift;
    my $field = shift;
    my $code; my $response;
    ($code, $response) = $self->_doGnatsCmd("FIELDFLAGS $field");
    if ($self->_isCodeOK($code)) {
        my @validators = $self->_extractListContent($response);
        return @validators;
    }
    #FIXME what if not ok?
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
            return 0;
        } 
    } else {
        return 0;
    }
}

sub getFieldDefault {
    my $self = shift;
    my $field = shift;
    my $code; my $response;
    ($code, $response) = $self->_doGnatsCmd("INPUTDEFAULT $field");
    return $response; #TODO parse?
    #FIXME what if not ok?
}


sub resetServer {
    my $self = shift;
    my $code; my $response;
    ($code, $response) = $self->_doGnatsCmd("RSET");
    if ($self->_isCodeOK($code)) {
        return 1;
    } else {
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
        return 0;
    }
}


sub deletePR { #not impelemented
}

sub checkPR {
}

sub setWorkingEmail {
    my $self = shift;
    my $email = shift;
    my $code; my $response;
    ($code, $response) = $self->_doGnatsCmd("EDITADDR $email");
    if ($self->_isCodeOK($code)) {
        return 1;
    } else {
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
            return 0;
        } 
    } else {
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
            return 0;
        } 
    } else {
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
            return 0;
        }
    } else {
        return 0;
    }
    
    
}




sub getPRByNumber { #tie with EXPR, QFMT, and QUER ??
    my $self = shift;
    my $num = shift;
    my ($code, $response) = $self->_doGnatsCmd("RSET");
    ($code, $response) = $self->_doGnatsCmd("QFMT full");
    ($code, $response) = $self->_doGnatsCmd("QUER $num");

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

sub query { #tie with EXPR, QFMT, and QUER ??
    my $self = shift;
    my @exprs = @_;
   
    my ($code, $response) = $self->_doGnatsCmd("RSET"); #XXX TODO  
    ($code, $response) = $self->_doGnatsCmd("QFMT Number"); #XXX TODO  

    foreach my $expr (@exprs) {
        ($code, $response) = $self->_doGnatsCmd("EXPR $expr"); 
    }


    my @nums;
    ($code, $response) = $self->_doGnatsCmd("QUER");
    if ($self->_isCodeOK($code)) {
        @nums = $self->_extractListContent($response);
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
    }
    #FIXME what if not ok?
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
        return 0;
    } 
}




sub _doGnatsCmd {
    my $self = shift;
    my $cmd = shift;

    print SOCK "$cmd\n";
    my $response = $self->_getGnatsdResponse();
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
        print "COULDN'T PARSE SERVER RESPONSE\n";
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


# preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

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


=head1 DESCRIPTION

Net::Gnats provides a perl interface to the gnatsd command set.  Although 
most of the gnatsd command are present and can be explicitly called through
Net::Gnats, common gnats tasks can be accompished through some methods 
which simplify the process (especially querying the database, editing bugs,
etc). 

=head2 EXPORT

None by default.


=head1 AUTHOR

Mike Hoolehan, mike@sycamore.us

=head1 SEE ALSO

perl(1).

=cut
