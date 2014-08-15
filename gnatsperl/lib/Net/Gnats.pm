package Net::Gnats;
use 5.010_000;
use utf8;
use strict;
use warnings;
use Readonly;
use English '-no_match_vars';

require Exporter;
use AutoLoader qw(AUTOLOAD);
use base 'Exporter';
use Carp;
use Socket;
use IO::Handle;
use Net::Gnats::PR;
use Net::Gnats::Response;

our $VERSION = 0.10;
local $| =1 ;

Readonly::Scalar my $CODE_GREETING               => 200;
Readonly::Scalar my $CODE_CLOSING                => 201;
Readonly::Scalar my $CODE_OK                     => 210;
Readonly::Scalar my $CODE_SEND_PR                => 211;
Readonly::Scalar my $CODE_SEND_TEXT              => 212;
Readonly::Scalar my $CODE_NO_PRS_MATCHED         => 220;
Readonly::Scalar my $CODE_NO_ADM_ENTRY           => 221;
Readonly::Scalar my $CODE_PR_READY               => 300;
Readonly::Scalar my $CODE_TEXT_READY             => 301;
Readonly::Scalar my $CODE_INFORMATION            => 350;
Readonly::Scalar my $CODE_INFORMATION_FILLER     => 351;
Readonly::Scalar my $CODE_NONEXISTENT_PR         => 400;
Readonly::Scalar my $CODE_EOF_PR                 => 401;
Readonly::Scalar my $CODE_UNREADABLE_PR          => 402;
Readonly::Scalar my $CODE_INVALID_PR_CONTENTS    => 403;
Readonly::Scalar my $CODE_INVALID_FIELD_NAME     => 410;
Readonly::Scalar my $CODE_INVALID_ENUM           => 411;
Readonly::Scalar my $CODE_INVALID_DATE           => 412;
Readonly::Scalar my $CODE_INVALID_FIELD_CONTENTS => 413;
Readonly::Scalar my $CODE_INVALID_SEARCH_TYPE    => 414;
Readonly::Scalar my $CODE_INVALID_EXPR           => 415;
Readonly::Scalar my $CODE_INVALID_LIST           => 416;
Readonly::Scalar my $CODE_INVALID_DATABASE       => 417;
Readonly::Scalar my $CODE_INVALID_QUERY_FORMAT   => 418;
Readonly::Scalar my $CODE_NO_KERBEROS            => 420;
Readonly::Scalar my $CODE_AUTH_TYPE_UNSUP        => 421;
Readonly::Scalar my $CODE_NO_ACCESS              => 422;
Readonly::Scalar my $CODE_LOCKED_PR              => 430;
Readonly::Scalar my $CODE_GNATS_LOCKED           => 431;
Readonly::Scalar my $CODE_GNATS_NOT_LOCKED       => 432;
Readonly::Scalar my $CODE_PR_NOT_LOCKED          => 433;
Readonly::Scalar my $CODE_INVALID_FTYPE_PROPERTY => 435;
Readonly::Scalar my $CODE_CMD_ERROR              => 440;
Readonly::Scalar my $CODE_WRITE_PR_FAILED        => 450;
Readonly::Scalar my $CODE_ERROR                  => 600;
Readonly::Scalar my $CODE_TIMEOUT                => 610;
Readonly::Scalar my $CODE_NO_GLOBAL_CONFIG       => 620;
Readonly::Scalar my $CODE_INVALID_GLOBAL_CONFIG  => 621;
Readonly::Scalar my $CODE_NO_INDEX               => 630;
Readonly::Scalar my $CODE_FILE_ERROR             => 640;

# bits in fieldinfo(field, flags) has (set=yes not-set=no) whether the
# send command should include the field
Readonly::Scalar my $SENDINCLUDE                 => 1;

# whether change to a field requires reason
Readonly::Scalar my $REASONCHANGE                => 2;

# if set, can't be edited
Readonly::Scalar my $READONLY                    => 4;

# if set, save changes in Audit-Trail
Readonly::Scalar my $AUDITINCLUDE                => 8;

# whether the send command _must_ include this field
Readonly::Scalar my $SENDREQUIRED                => 16;

# The possible values of a server reply type.  $REPLY_CONT means that
# there are more reply lines that will follow, $REPLY_END Is the final
# line.
Readonly::Scalar my $REPLY_CONT                  => 1;
Readonly::Scalar my $REPLY_END                   => 2;

#
# Various PR field names that should probably not be referenced in
# here.
#

# Actually, the majority of uses are probably OK--but we need to map
# internal names to external ones.  (All of these field names
# correspond to internal fields that are likely to be around for a
# long time.)
#

Readonly::Scalar my $CATEGORY_FIELD              => 'Category';
Readonly::Scalar my $SYNOPSIS_FIELD              => 'Synopsis';
Readonly::Scalar my $SUBMITTER_ID_FIELD          => 'Submitter-Id';
Readonly::Scalar my $ORIGINATOR_FIELD            => 'Originator';
Readonly::Scalar my $AUDIT_TRAIL_FIELD           => 'Audit-Trail';
Readonly::Scalar my $RESPONSIBLE_FIELD           => 'Responsible';
Readonly::Scalar my $LAST_MODIFIED_FIELD         => 'Last-Modified';

Readonly::Scalar my $NUMBER_FIELD                => 'builtinfield:Number';
Readonly::Scalar my $STATE_FIELD                 => 'State';
Readonly::Scalar my $UNFORMATTED_FIELD           => 'Unformatted';
Readonly::Scalar my $RELEASE_FIELD               => 'Release';
Readonly::Scalar my $REPLYTO_FIELD               => 'Reply-To';

BEGIN {
  # Create aliases to deprecate 'old' style method calls.
  # These will be removed in the 'future'.
  *getDBNames = \&get_dbnames;
  *listDatabases = \&list_databases;
  *listCategories = \&list_categories;
  *listSubmitters = \&list_submitters;
  *listResponsible = \&list_responsible;
  *listStates = \&list_states;
  *listFieldNames = \&list_fieldnames;
  *listInitialInputFields = \&list_inputfields_initial;
  *getFieldType = \&get_field_type;
  *getFieldTypeInfo = \&get_field_typeinfo;
  *getFieldDesc = \&get_field_desc;
  *getFieldFlags = \&get_field_flags;
  *getFieldValidators = \&get_field_validators;
  *getFieldDefault = \&get_field_default;

  *setWorkingEmail = \&set_workingemail;
  *replaceField = \&truncate_field_content;
  *appendToField = \&append_field_content;

  *validateField = \&validate_field;
  *isValidField = \&is_validfield;

  *checkNewPR = \&check_newpr;

  *lockPR   = \&lock_pr;
  *unlockPR = \&unlock_pr;
  *deletePR = \&delete_pr;
  *checkPR  = \&check_pr;
  *submitPR = \&submit_pr;
  *updatePR = \&update_pr;

  *resetServer = \&reset_server;
}

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::Gnats ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

my $debug_gnatsd = 0;

# There is a bug in gnatsd that seems to happen after submitting
# about 125 new PR's in the same session it starts thinking that
# the submitter-id is not valid anymore, so we restart every so often.
Readonly::Scalar my $MAX_NEW_PRS => 100;

#******************************************************************************
# Sub: new
# Description: Constructor
# Args: hash (parameter list)
# Returns: self
#******************************************************************************
sub new {
    my ( $class, $host, $port ) = @_;
    my $self = bless {}, $class;

    $self->{hostAddr} = $host || 'localhost';
    $self->{hostPort} = $port || '1529';

    $self->{fieldData} = {
                          # Array of fieldnames in same order
                          # returned by list fieldnames.
                          names => [],
                          # Initial Input Fields
                          initial => [],
                          # All the field info.
                          fields => {},
                         };

    $self->{lastCode} = undef;
    $self->{lastResponse} = undef;
    $self->{errorCode} = undef;
    $self->{errorMessage} = undef;
    $self->{accessMode} = undef;
    $self->{gnatsdVersion} = undef;
    $self->{user} = undef;
    $self->{db}   = undef;

    return $self;
}

sub debug_gnatsd {
  $debug_gnatsd = 1;
}

sub gnatsd_connect {
    my ( $self ) = @_;
    my ( $iaddr, $paddr, $proto );

    #TODO disconnect if already connected

    if (!($iaddr = inet_aton($self->{hostAddr}))) {
        carp("Unknown GNATS host '$self->{hostAddr}'");
        return 0;
    }

    $paddr = sockaddr_in($self->{hostPort}, $iaddr);
    $proto = getprotobyname 'tcp' ;
    if ( not socket SOCK, PF_INET, SOCK_STREAM, $proto ) {
      #TODO: RECOVER BETTER HERE
         carp "gnatsweb: client_init error $self->{hostAddr} $self->{hostPort}: $OS_ERROR";
        return 0;
    }

    if ( not connect SOCK, $paddr ) {
      #TODO: RECOVER BETTER HERE
         carp "gnatsweb: client_init error $self->{hostAddr} $self->{hostPort}: $OS_ERROR ;";
        return 0;
    }

    SOCK->autoflush(1);
    my $response = $self->_get_gnatsd_response();
    $self->{lastCode} = $response->code;
    $self->{lastResponse} = $response->as_string;
    _debug('INIT: [' . $response->as_string . ']');

    # Make sure we got a 200 code.
    if ($response->code != $CODE_GREETING) {
      carp "? Error: Unknown gnatsd connection response: $response";
      return 0;
    }

    # Grab the gnatsd version
    if ( $response->raw =~ /\d.\d.\d/sxm ) {
      $self->{gnatsdVersion} = $response->raw;
      $self->{gnatsdVersion} =~ s/.*(\d.\d.\d).*/$1/sxm;
    }
    else {
      # We only know how to talk to gnats4
      warn "? Error: GNATS Daemon version $self->{gnatsdVersion} at $self->{hostAddr} $self->{hostPort} is not supported by Net::Gnats\n";
      return 0;
    }
    $self->{newPRs} = 0;
    return 1;
}

sub disconnect {
    my ( $self ) = @_;
    return $self->_do_gnats_cmd('QUIT');
}

sub get_dbnames {
    my ( $self ) = @_;

    my ($code, $response) = $self->_do_gnats_cmd('DBLS');
    _debug('DBLS CODE: [' . $code . ']');

    if ($self->_is_code_ok($code)) {
        return $self->_extract_list_content($response);
    }

    _debug('DBLS DID NOT PASS IS_CODE_OK');
    $self->_mark_error($code, $response);
    return;
}


sub list_databases {
    return shift->_list('DATABASES',
                        ['name', 'desc', 'path']);
}


sub list_categories {
    return shift->_list('CATEGORIES',
                        ['name', 'desc', 'contact', 'notify']);
}

sub list_submitters {
    return shift->_list('SUBMITTERS',
                        ['name', 'desc', 'contract', 'something1',
                         'responsible']);
}

sub list_responsible {
    return shift->_list('RESPONSIBLE',
                        ['name', 'realname', 'email']);
}

sub list_states {
    return shift->_list('STATES',
                        ['name', 'type', 'desc']);
}

sub list_fieldnames {
  my ( $self ) = @_;
  my ($code, $response) = $self->_do_gnats_cmd('LIST FIELDNAMES');
  return if not $self->_is_code_ok($code);
  return $response;
}

sub list_inputfields_initial {
  my ( $self ) = @_;
  if ($#{$self->{fieldData}->{initial}} < 0) {
    my ($code, $response) = $self->_do_gnats_cmd('LIST INITIALINPUTFIELDS');
    if ($self->_is_code_ok($code)) {
      push @{$self->{fieldData}->{initial}}, $self->_extract_list_content($response);
    } else {
      $self->_mark_error($code, $response);
      return;
    }
  }
  return wantarray ? @{$self->{fieldData}->{initial}} : $self->{fieldData}->{initial};
}

sub get_field_type {
  my ( $self, $field ) = @_;

  if (not defined $field) { return; }



#  if ( defined $self->{fieldData}->{fields}->{$field}->{type} ) {
#    return $self->{fieldData}->{fields}->{$field}->{type};
#  }

  my ($code, $response) = $self->_do_gnats_cmd("FTYP $field");
  if ( $code == $CODE_INVALID_FIELD_NAME ) { return; }

#  if ( ! $self->_is_code_ok($code) ) {
#    $self->_mark_error($code, $response);
#    return;
#  }

#  $response =~ s/^\d+\s+//sxm;
#  chomp $response;
#  $self->{fieldData}->{fields}->{$field}->{type} = $response;

  return $response;
}

sub is_validfield {
  my ( $self, $field ) = @_;

  $self->{validFields}->{$field} = $self->getFieldType($field) ? 1 : 0
    if (not exists($self->{validFields}->{$field}));
  return $self->{validFields}->{$field};
}

sub get_field_typeinfo {
  my ( $self, $field, $property ) = @_;
  if ( not defined $field ) { return; }
  my $type_response = $self->get_field_type($field);
  _debug('FTYP (response): [' . $type_response . ']');
  if ( $type_response ne 'MultiEnum' ) { return; }
  if ( not defined $property ) { $property = 'separators'; }


  my ($code, $response) = $self->_do_gnats_cmd("FTYPINFO $field $property");
  if ( $code == $CODE_INVALID_FTYPE_PROPERTY ) { return; }

  # if (not exists($self->{fieldData}->{fields}->{$field}->{typeInfo})) {
  #   if ($self->_is_code_ok($code)) {
  #     $self->{fieldData}->{fields}->{$field}->{typeInfo} = $response;
  #   } else {
  #     $self->_mark_error($code, $response);
  #     return;
  #   }
  # }
  # return $self->{fieldData}->{fields}->{$field}->{typeInfo};
  return $response;
}

sub get_field_desc {
    my ( $self, $field ) = @_;

    my ($code, $response) = $self->_do_gnats_cmd("FDSC $field");
    if ($self->_is_code_ok($code)) {
        return $response;
    } else {
        $self->_mark_error($code, $response);
        return;
    }
}

sub get_field_flags {
  my ( $self, $field, $flag ) = @_;
  if ( not defined $field ) { return; }

  my ($code, $response) = $self->_do_gnats_cmd("FIELDFLAGS $field");

  if (defined $flag and $response =~ /$flag/sxm) { return 1; }

  return $response;
}

sub get_field_validators {
    my ( $self, $field ) = @_;

    my ($code, $response) = $self->_do_gnats_cmd("FVLD $field");

    if ($self->_is_code_ok($code)) {
        my @validators = $self->_extract_list_content($response);
        return @validators;
    } else {
        $self->_mark_error($code, $response);
        return;
    }
}


sub validate_field {
    my ( $self, $field, $input ) = @_;

    my ($code, $response) = $self->_do_gnats_cmd("VFLD $field");
    if ($self->_is_code_ok($code)) {
        ($code, $response) = $self->_do_gnats_cmd($input."\n".".");
        if ($self->_is_code_ok($code)) {
            return 1;
        } else {
            $self->_mark_error($code, $response);
            return 0;
        }
    } else {
        $self->_mark_error($code, $response);
        return 0;
    }
}

sub get_field_default {
  my ( $self, $field ) = @_;
  my ($code, $response) = $self->_do_gnats_cmd("INPUTDEFAULT $field");
  if (not $self->_is_code_ok($code)) { return }
  return @{ $response }[0];
}


sub reset_server {
  my ( $self ) = @_;

  my ($code, $response) = $self->_do_gnats_cmd('RSET');

  if ( not $self->_is_code_ok($code) ) {
    $self->_mark_error($code, $response);
    return 0;
  }

  return 1;
}


sub lockMainDatabase {
    my ( $self ) = @_;
    my $code; my $response;
    ($code, $response) = $self->_do_gnats_cmd('LKDB');
    if ($self->_is_code_ok($code)) {
        return 1;
    } else {
        $self->_mark_error($code, $response);
        return 0;
    }
}

sub unlockMainDatabase {
    my ( $self ) = @_;
    my $code; my $response;
    ($code, $response) = $self->_do_gnats_cmd('UNDB');
    if ($self->_is_code_ok($code)) {
        return 1;
    } else {
        $self->_mark_error($code, $response);
        return 0;
    }
}

sub lock_pr {
    my ( $self, $pr, $user ) = @_;

    my ($code, $response) = $self->_do_gnats_cmd("LOCK $pr $user");
    if ($self->_is_code_ok($code)) {
        my $prl = $self->newPR();
        $prl->parse(split("\n",$response));
        return $prl;
    } else {
        $self->_mark_error($code, $response);
        return 0;
    }
}

sub unlock_pr {
    my ( $self, $pr ) = @_;

    my ($code, $response) = $self->_do_gnats_cmd("UNLK $pr");
    if ($self->_is_code_ok($code)) {
        return 1;
    } else {
        $self->_mark_error($code, $response);
        return 0;
    }
}

sub delete_pr {
  my ( $self, $pr ) = @_;

  my ($code, $response) = $self->_do_gnats_cmd("DELETE $pr");
  if ($self->_is_code_ok($code)) {
    return 1;
  }
  $self->_mark_error($code, $response);
  return 0;
}

sub check_newpr {
  my ( $self, $pr ) = @_;
  $self->check_pr($pr, 'initial');
  return;
}

sub check_pr {
  my ( $self, $pr, $arg ) = @_;

  my $argument  = defined $arg ? $arg : "";

  my ($code, $response) = $self->_do_gnats_cmd("CHEK $argument");

  if ($self->_is_code_ok($code)) {
    ($code, $response) = $self->_do_gnats_cmd("$pr\n.");
    if ($self->_is_code_ok($code)) {
      return 1;
    }
    # TODO: Should this be handled in _doGnatsCmd?
    # If gnatsd returns a: 401 Couldn't read PR header
    # or if it sends multiple: 411 There is a bad value ... for field ...
    # then it also sends a: 403 Errors found checking PR text
    # So read back that response, but ignore it cause the user
    # would want to see the 401 error
    my @response = split("\n",$response);
    if ($code eq '401' or ($code eq '411' and $#response > 0)) {
      my ($rcode, $rresponse) = $self->_process;
    }
    $self->_mark_error($code, $response);
    return 0;
  }

  $self->_mark_error($code, $response);
  return 0;
}


sub set_workingemail {
    my ( $self, $email ) = @_;

    my ($code, $response) = $self->_do_gnats_cmd("EDITADDR $email");
    if ($self->_is_code_ok($code)) {
        return 1;
    } else {
        $self->_mark_error($code, $response);
        return 0;
    }
}

#
# TODO: "text" fields are limited to 256 characters.  Current gnatsd does
# not correctly truncate, if you enter $input is 257 characters, it will
# replace with an empty field.  We should truncate text $input's correctly.

sub truncate_field_content {
  my ( $self, $pr, $field, $input, $reason ) = @_;
  confess '? Error: pr not passed to replaceField' if not defined $pr;
  confess '? Error: field passed to replaceField' if not defined $field;
  confess '? Error: no input passed to replaceField' if not defined $input;

  # See if this field requires a change reason.
  # TODO: We could just enter the $input, and see if gnatsd says
  #       a reason is required, but I could not figure out how to
  #       abort at that point if no reason was given...
  my $need_reason = $self->getFieldFlags($field, 'requireChangeReason');
  if ($need_reason and (not defined($reason) or $reason eq '')) {
    $self->_mark_error('403', 'No change Reason Specified');
    return(0);
  }

  my ($code, $response) = $self->_do_gnats_cmd("REPL $pr $field");

  if ($self->_is_code_ok($code)) {
    ($code, $response) = $self->_do_gnats_cmd($input."\n" . '.');
    if ($need_reason) {
      #warn "reason=\"$reason\"";
      # TODO: This can choke here if we encounter a PR with a bad field like:
      # _getGnatsdResponse: READ >>411 There is a bad value `unknown' for the field `Category'.
      ($code, $response) = $self->_do_gnats_cmd($reason."\n" . '.')
    }
    if ($self->_is_code_ok($code)) {
      return 1;
    }
    $self->_mark_error($code, $response);
  } else {
    $self->_mark_error($code, $response);
  }
  if ($code eq '640' and $self->restart($code)) {
    return $self->replaceField($pr, $field, $input, $reason);
  }
  return 0;
}

my $restart_time;

sub restart {
  my ( $self, $code ) = @_;

  my $ctime = time;
  if ( defined $restart_time ) {
    if (($ctime - $restart_time) < 5) {
      warn "! ERROR: Restart attempted twice in a row, 640 error must be real!\n";
      return 0;
    }
  }

  warn "
! ERROR: Recieved GNATSD code $code, will now disconnect and reconnect
         to gnatsd, then re-issue the command.  This may cause any
         following commands to behave differently if you depended on
         things like QFMT\n".time."\n";

  $restart_time = $ctime;
  $self->_clear_error();
  $self->disconnect;
  $self->gnatsd_connect;
  return $self->login($self->{db},
                      $self->{user},
                      $self->{pass});
}

sub append_field_content {
    my ( $self, $pr, $field, $input ) = @_;

    confess '? Error: pr not passed to appendField' if not defined $pr;
    confess '? Error: field passed to appendField' if not defined $field;
    confess '? Error: no input passed to appendField' if not defined $input;

    my ($code, $response) = $self->_do_gnats_cmd("APPN $pr $field");

    if ($self->_is_code_ok($code)) {
        ($code, $response) = $self->_do_gnats_cmd($input."\n" . '.');
        if ($self->_is_code_ok($code)) {
            return 1;
        } else {
            $self->_mark_error($code, $response);
        }
    } else {
        $self->_mark_error($code, $response);
    }
    if ($code eq "640" and $self->restart($code)) {
      # TODO: This can potentially be an infinte loop...
      return $self->appendToField($pr,$field,$input);
    }
    return 0;
}

sub submit_pr {
    my ( $self, $pr ) = @_;

    $self->restart('Too Many New PRs') if ($self->{newPRs} > $MAX_NEW_PRS);

    my $prString = $pr->unparse();

    my ($code, $response) = $self->_do_gnats_cmd('SUBM');

    if ($self->_is_code_ok($code)) {
        ($code, $response) = $self->_do_gnats_cmd($prString. "\n" . '.');

        _debug("Gnats::submitPR: code=$code response=$response");
        if ($self->_is_code_ok($code)) {
          $self->{newPRs}++;
          return $response;
        } else {
          $self->_mark_error($code, $response);
        }
    } else {
        $self->_mark_error($code, $response);
    }

    if ($code eq "640") {
      if ($self->restart($code)) {
        # TODO: This can potentially be an infinite loop...
        return $self->submit_pr($pr);
      }
    }
    return 0;
}

##################################################################
#
# Update the PR.
#
# Bit's of this code were grabbed from "gnatsweb.pl".
#
sub update_pr {
  my ( $self, $pr ) = @_;

  my $user         = $self->{user};
  my $prnum        = $pr->getField('Number');
  my $last_modified = $pr->getField('Last-Modified');
  $last_modified ||= ''; # Default to empty

  my $pr_string = $pr->unparse("gnatsd");

  my $code; my $response ; my $st = 0;
  # Lock the PR so we can edit it.
  # Locking it returns the PR contents which we use to see what has changed.

  my $spr = $self->lock_pr($prnum, $user);

  return $st if not defined $spr;

  # See which fields changed.
  my %sprHash = $spr->asHash();
  $sprHash{'Last-Modified'} ||= ''; # Default to empty
  # Make sure modified date is the same!
  my $slast_modified = $spr->getField("Last-Modified");
  $slast_modified ||= ''; # Default to empty

  if ($last_modified ne $slast_modified) {
    $code = '433'; # What code to return?  433=PR_NOT_LOCKED
    $response = "433 Sorry can't edit $prnum, it has been modified by someone else";
  } else {
    my $pr_string = $pr->unparse("gnatsd");
    # Now edit it.
    ($code, $response) = $self->_do_gnats_cmd("EDITADDR $user");
    if ($self->_is_code_ok($code)) {
      ($code, $response) = $self->_do_gnats_cmd("EDIT $prnum");
      if ($self->_is_code_ok($code)) {
        ($code, $response) = $self->_do_gnats_cmd($pr_string . '.');
        if ($self->_is_code_ok($code)) {
          $st = 1; # Everything worked!
        }
      }
    }
  }
  # TODO: Detect unlock PR problems?
  # Seems that unlock sometimes returns a 6xx code even if the lock file is removed?
  $self->unlock_pr($prnum);
  if (not $st) {
    # Something above failed, mark the error.
    $self->_mark_error($code, $response);
  }
  return;
}


sub newPR {
  my ( $self ) = @_;
  return Net::Gnats::PR->new($self);
}

# Fillout all defaults for a PR.
# TODO: should this always be called by newPR?
sub filloutPR {
  my ( $self, $pr ) = @_;
  foreach my $field ($self->listInitialInputFields) {
    $pr->setField($field,$self->getFieldDefault($field));
  }
  return;
}

sub getPRByNumber {
    my ( $self, $num ) = @_;

    my ($code, $response) = $self->_do_gnats_cmd('RSET');
    if (not $self->_is_code_ok($code)) {
        $self->_mark_error($code, $response);
        return;
    }

    ($code, $response) = $self->_do_gnats_cmd('QFMT full');
    if (not $self->_is_code_ok($code)) {
        $self->_mark_error($code, $response);
        return;
    }

    ($code, $response) = $self->_do_gnats_cmd("QUER $num");

    if ( $code == $CODE_NO_PRS_MATCHED and
         @{$response}[0] eq 'No PRs match.' ) { return; }

    if (not $self->_is_code_ok($code)) {
        $self->_mark_error($code, $response);
        return;
    }

    my $pr = $self->newPR();
    $pr->parse( @{ $response } ) ;

    return $pr;
}


sub expr {
    my ( $self ) = @_;
    my @exprs = @_;

    my ($code, $response);
    foreach my $expr (@exprs) {
        ($code, $response) = $self->_do_gnats_cmd("EXPR $expr");
    }
    return $code; #XXX TODO and codes together or abort or something
}

sub query {
    my ( $self ) = @_;
    my @exprs = @_;

    my ($code, $response) = $self->_do_gnats_cmd('RSET'); #XXX TODO
    if (not $self->_is_code_ok($code)) {
        $self->_mark_error($code, $response);
        return;
    }

    ($code, $response) = $self->_do_gnats_cmd('QFMT Number'); #XXX TODO
    if (not $self->_is_code_ok($code)) {
        $self->_mark_error($code, $response);
        return;
    }

    foreach my $expr (@exprs) {
        ($code, $response) = $self->_do_gnats_cmd("EXPR $expr");
        if (not $self->_is_code_ok($code)) {
            $self->_mark_error($code, $response);
            return;
        }
    }

    my @nums;
    ($code, $response) = $self->_do_gnats_cmd('QUER');
    if ($self->_is_code_ok($code)) {
        @nums = $self->_extract_list_content($response);
    } else {
        $self->_mark_error($code, $response);
        return;
    }
    return @nums;
}

sub _list {
  my ( $self, $listtype, $keynames ) = @_;

  my ($code, $response) = $self->_do_gnats_cmd("LIST $listtype");

  if (not $self->_is_code_ok($code)) {
    $self->_mark_error($code, $response);
    return;
  }

  my @result = qw();

  my @rawrows = $self->_extract_list_content($response);
  foreach my $row (@rawrows) {
    push @result, map { @{ $keynames }[$_] =>
                          $rawrows[$_] } 0..( scalar @{$keynames} - 1);
  }
  return \@result;
}

sub login {
    my ( $self, $db, $user, $pass ) = @_;

    $pass = '*' if (not defined $pass or $pass eq '');

    my ($code, $response) = $self->_do_gnats_cmd("CHDB $db $user $pass");
    if ($self->_is_code_ok($code)) {
        $self->{db}   = $db;
        $self->{user} = $user;
        $self->{pass} = $pass;
        $self->_setAccessMode;
        return 1;
    }

    $self->_mark_error($code, $response);
    return 0;
}

sub getAccessMode {
    my ( $self ) = @_;
    return $self->{accessMode};
}

# This is called by login to determine the current access mode,
# typically this would not be called by the user.
sub _setAccessMode {
    my ( $self )  = @_;

    $self->{accessMode} = undef; # Clear it.
    my ($code, $response) = $self->_do_gnats_cmd('USER');
    if ($self->_is_code_ok($code)) {
        $response =~ s/.*\n350\s*(\S+)\s*\n/$1/sxm;
        $self->{accessMode} = $response;
        return $response;
    } else {
        $self->_mark_error($code, $response);
        return 0;
    }
}


sub getErrorCode {
    my ( $self ) = @_;
    return $self->{errorCode};
}

sub getErrorMessage {
    my ( $self ) = @_;
    return $self->{errorMessage};
}

sub _do_gnats_cmd {
  my ( $self, $cmd ) = @_;

  $self->_clear_error();

  _debug('SENDING: [' . $cmd . ']');

  print SOCK "$cmd\n";

  my $r = $self->_process;

  return ($r->code, $r->raw);
}

sub _process {
  my ( $self ) = @_;

  my $r = $self->_get_gnatsd_response;

  if ($r->raw =~ /^411 There is a bad value/sxm) {
    <SOCK>
  }

  $self->{lastCode} = $r->code;
  $self->{lastResponse} = $r->raw;

  return $r;
}

# use this routine to get more data from the server such as
# Lists or PRs.
sub _read_multi {
  my ( $self ) = @_;
  my $raw = [];
  while ( my $line = <SOCK> ) {
    if ( $line =~ /^[.]\r/sxm) { last; }
    $line = $self->_read_clean($line);
    _debug('READ: [' . __LINE__ . '][' . $line . ']');
    my $parts = $self->_read_decompose( $line );

    if ( not $self->_read_has_more( $parts ) ) {
      if ( defined @{ $parts }[0] ) {
        push @{ $raw }, @{ $parts }[2];
      }
      last;
    }
    push @{ $raw }, $line;
  }
  return $raw;
}

sub _read {
  my ( $self ) = @_;
  my $raw = [];
  my $response = Net::Gnats::Response->new;

  my $line = <SOCK>;
  $line = $self->_read_clean($line);

  _debug('READ: [' . __LINE__ . '][' . $line . ']');

  my $result = $self->_read_decompose($line);

  $response->code( @{ $result }[0] );

  if (not defined $response->code) { return; }

  unless ( $response->code == $CODE_PR_READY           or
           $response->code == $CODE_TEXT_READY         or
           $response->code == $CODE_INFORMATION_FILLER ) {
    push @{ $raw }, @{$result}[2];
  }

  if ( $self->_read_has_more( $result ) ) {
    push @{ $raw } , @{ $self->_read_multi };
  }
  $response->raw( $raw );
  return $response;
}

sub _read_decompose {
  my ( $self, $raw ) = @_;
  my @result = $raw =~ /^(\d\d\d)([- ]?)(.*$)/sxm;
  return \@result;
}

sub _read_has_more {
  my ( $self, $parts ) = @_;
  if ( @{$parts}[0] ) {
    if ( @{$parts}[1] eq '-' ) {
      return 1;
    }
    elsif ( @{$parts}[0] >= $CODE_PR_READY and @{$parts}[0] < $CODE_INFORMATION) {
      return 1;
    }
    return; # does not pass 'continue' criteria
  }
  return 1; # no code, infer multiline read
}

sub _read_clean {
  my ( $self, $line ) = @_;
  $line =~ s/[\r\n]//gsxm;
  $line =~ s/^[.][.]/./sxm;
  return $line;
}

sub _get_gnatsd_response {
    return shift->_read;
}

sub _extract_list_content {
  my ( $self, $response ) = @_;
  my @lines = split /\n/sxm, $response;
  return @lines;
}

sub _is_code_ok {
  my ( $self, $code ) = @_;

  return 0 if not defined $code;
  return 1 if $code =~ /[23]\d\d/sxm;
  return 0;
}

sub _clear_error {
  my ( $self ) = @_;

  $self->{errorCode} = undef;
  $self->{errorMessage} = undef;

  return;
}


sub _mark_error {
  my ($self, $code, $msg) = @_;

  $self->{errorCode} = $code;
  $self->{errorMessage} = $msg;
  _debug('ERROR: CODE: [' . $code . '] MSG: [' . $msg . ']');

  return;
}

sub _debug {
  my ($message) = @_;
  if (not $debug_gnatsd) { return; }
  print 'DEBUG: [' . $message . ']' . "\n";
  return;
}

# preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.



1;

__END__

=head1 NAME

Net::Gnats - Perl interface to GNU Gnats daemon

=head1 VERSION

0.7

=head1 SYNOPSIS

  use Net::Gnats;
  my $g = Net::Gnats->new;
  $g->gnatsd_connect;
  my @dbNames = $g->get_dbnames;
  $g->login("default","somedeveloper","password");

  my $PRtwo = $g->getPRByNumber(2);
  print $PRtwo->asString();

  # Change the synopsis
  $PRtwo->replaceField("Synopsis","The New Synopsis String");

  # Change the responsible, which requires a change reason.
  $PRtwo->replaceField("Responsible","joe","Because It's Joe's");

  # Or we can change them this way.
  my $PRthree = $g->getPRByNumber(3);
  # Change the synopsis
  $PRtwo->setField("Synopsis","The New Synopsis String");
  # Change the responsible, which requires a change reason.
  $PRtwo->setField("Responsible","joe","Because It's Joe's");
  # And change the PR in the database
  $g->updatePR($pr);

  my $newPR = $g->newPR();
  $newPR->setField("Submitter-Id","developer");
  $g->submitPR($newPR);
  $g->disconnect();


=head1 DESCRIPTION

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

  my $g = Net::Gnats->new;
  $g->gnatsd_connect;
  my @dbNames = $g->getDBNames;

Note that getDBNames() is different than listDatabases(), which
requires logging in first and gets a little more info than just names.

=head2 LOGGING IN TO A DATABASE

The Gnats object has to be logged into a database to perform almost
all actions.

  my $g = Net::Gnats->new;
  $g->gnatsd_connect;
  $g->login("default","myusername","mypassword");


=head2 SUBMITTING A NEW PR

The Net::Gnats::PR object acts as a container object to store
information about a PR (new or otherwise).  A new PR is submitted to
gnatsperl by constructing a PR object.

  my $newPR = $g->newPR();
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

Obviously, fields are dependent on a specific gnats installation,
since Gnats administrators can rename fields and add constraints.
There are some methods in Net::Gnats to discover field names and
constraints, all described below.

Instead of setting each field of the PR individually, the
setFromString() method is available.  The string that is passed to it
must be formatted in the way Gnats handles the PRs.  This is useful
when handling a Gnats email submission ($newPR->setFromString($email))
or when reading a PR file directly from the database.  See
Net::Gnats::PR for more details.


=head2 QUERYING THE PR DATABASE

  my @prNums = $g->query('Number>"12"', "Category=\"$thisCat\"");
  print "Found ". join(":",@prNums)." matching PRs \n";

Pass a list of query expressions to query().  A list of PR numbers of
matching PRs is returned.  You can then pull out each PR as described
next.


=head2 FETCHING A PR

  my $prnum = 23;
  my $PR = $g->getPRByNumber($prnum);
  print $PR->getField('synopsis');
  print $PR->asString();

The method getPRByNumber() will return a Net::Gnats::PR object
corresponding to the PR num that was passed to it.  The getField() and
asString() methods are documented in Net::Gnats::PR, but I will note
here that asString() returns a string in the proper Gnats format, and
can therefore be submitted directly to Gnats via email or saved to the
db directory for instance.  Also, $newPR->setFromString(
$oldPR->asString() ) works fine and will result in a duplicate of the
original PR object.


=head2 MODIFYING A PR

There are 2 methods of modifying fields in a Net::Gnats::PR object.

The first is to use the replaceField() or appendField() methods which
uses the gnatsd REPL and APPN commands.  This means that the changes
to the database happen immediatly.

  my $prnum = 23;
  my $PR = $g->getPRByNumber($prnum);
  if (! $PR->replaceField('Synopsis','New Synopsis')) {
    warn "Error replaceing field (",$g->getErrorMessage,")\n";
  }

If the field requires a change reason, it must be supplied as the 3rd argument.
  $PR->replaceField('Responsible','joe',"It's joe's problem");

The second is to use the setField() and updatePR() methods which uses
the gnatsd EDIT command.  This should be used when multiple fields of
the same PR are being changed, since the datbase changes occur at the
same time.

  my $prnum = 23;
  my $PR = $g->getPRByNumber($prnum);
  $PR->setField('Synopsis','New Synopsis');
  $PR->setField('Responsible','joe',"It's joe's problem");
  if (! $g->updatePR($PR) ) {
    warn "Error updating $prNum: ",$g->getErrorMessage,"\n";
  }


=head1 DIAGNOSTICS

Most methods will return undef if a major error is encountered.

The most recent error codes and messages which Net::Gnats encounters
while communcating with gnatsd are stored, and can be accessed with
the getErrorCode() and getErrorMessage() methods.


=head1 SUBROUTINES/METHODS

=head2 new

Constructor, optionally taking one or two arguments of hostname and
port of the target gnats server.  If not supplied, the hostname
defaults to localhost and the port to 1529.

=head2 gnatsd_connect

Connects to the gnats server.  No arguments.  Returns true if
successfully connected, false otherwise.


=head2 disconnect

Issues the QUIT command to the Gnats server, therby closing the
connection.

=head2 get_dbnames

Issues the DBLS command, and returns a list of database names in the
gnats server.  Unlike listDatabases, one does not need to use the logn
method before using this method.

=head2 list_databases

Issues the LIST DATABASES command, and returns a list of hashrefs with
keys 'name', 'desc', and 'path'.

=head2 list_categories

Issues the LIST CATEGORIES command, and returns a list of hashrefs
with keys 'name', 'desc', 'contact', and '?'.

=head2 list_submitters

Issues the LIST SUBMITTERS command, and returns a list of hashrefs
with keys 'name', 'desc', 'contract', '?', and 'responsible'.

=head2 list_responsible

Issues the LIST RESPONSIBLE command, and returns a list of hashrefs
with keys 'name', 'realname', and 'email'.

=head2 list_states

Issues the LIST STATES command, and returns a list of hashrefs with
keys 'name', 'type', and 'desc'.

=head2 list_fieldnames

Issues the LIST FIELDNAMES command, and returns a list of hashrefs
with key 'name'.

=head2 list_inputfields_initial

Issues the LIST INITIALINPUTFIELDS command, and returns a list of
hashrefs with key 'name'.

=head2 get_field_type

Expects a fieldname as sole argument, and issues the FTYP command.
Returns text response or undef if error.

=head2 get_field_type_info

Expects a fieldname and property as arguments, and issues the FTYPINFO
command.  Returns text response or undef if error.

=head2 get_field_desc

Expects a fieldname as sole argument, and issues the FDSC command.
Returns text response or undef if error.

=head2 get_field_flags

Expects a fieldname as sole argument, and issues the FIELDFLAGS
command.  Returns text response or undef if error.

=head2 get_field_validators

Expects a fieldname as sole argument, and issues the FVLD command.
Returns text response or undef if error.

=head2 validate_field()

Expects a fieldname and a proposed value for that field as argument,
and issues the VFLD command.  Returns true if propose value is
acceptable, false otherwise.

=head2 get_field_default

Expects a fieldname as sole argument, and issues the INPUTDEFAULT
command.  Returns text response or undef if error.

=head2 reset_server

Issues the RSET command, returns true if successful, false otherwise.

=head2 lockMainDatabase()

Issues the LKDB command, returns true if successful, false otherwise.

=head2 unlockMainDatabase()

Issues the UNDB command, returns true if successful, false otherwise.

=head2 lock_pr

Expects a PR number and user name as arguments, and issues the LOCK
command.  Returns true if PR is successfully locked, false otherwise.

=head2 unlock_pr

Expects a PR number a sole argument, and issues the UNLK command.
Returns true if PR is successfully unlocked, false otherwise.

=head2 delete_pr($pr)

Expects a PR number a sole argument, and issues the DELETE command.
Returns true if PR is successfully deleted, false otherwise.

=head2 check_pr

Expects the text representation of a PR (see COMMON TASKS above) as
input and issues the CHEK initial command.  Returns true if the given
PR is a valid entry, false otherwise.

=head2 set_workingemail

Expects an email address as sole argument, and issues the EDITADDR
command.  Returns true if email successfully set, false otherwise.

=head2 truncate_field_content

Expects a PR number, a fieldname, a replacement value, and optionally
a changeReason value as arguments, and issues the REPL command.
Returns true if field successfully replaced, false otherwise.

If the field has requireChangeReason attribute, then the changeReason
must be passed in, otherwise the routine will return false.

replaceField changes happen immediatly in the database.  To change
multiple fields in the same PR it is more efficiant to use updatePR.

=head2 append_field_content

Expects a PR number, a fieldname, and a append value as arguments, and
issues the APPN command.  Returns true if field successfully appended
to, false otherwise.

=head2 submit_pr

Expect a Gnats::PR object as sole argument, and issues the SUMB
command.  Returns true if PR successfully submitted, false otherwise.

=head2 update_pr

Expect a Gnats::PR object as sole argument, and issues the EDIT
command.  Returns true if PR successfully submitted, false otherwise.

Use this instead of replace_field if more than one field has changed.

=head2 getPRByNumber()

Expects a number as sole argument.  Returns a Gnats::PR object.

=head2 query()

Expects one or more query expressions as argument(s).  Returns a list
of PR numbers.

=head2 login()

Expects a database name, user name, and password as arguments and
issues the CHDB command.  Returns true if successfully logged in,
false otherwise

=head2 getAccessMode()

Returns the current access mode of the gnats database.  Either "edit",
"view", or undef;

=head1 INCOMPATIBILITIES

This library is not compatible with the Gnats protocol prior to GNATS
4.

=head1 BUGS AND LIMITATIONS

Bug reports are very welcome.  Please submit to the project page
(noted below).

=head1 CONFIGURATION AND ENVIRONMENT

No externalized configuration or environment at this time.

=head1 DEPENDENCIES

No runtime dependencies other than the Perl core at this time.

=head1 AUTHOR

Current Maintainer:
Richard Elberger riche@cpan.org

Original Author:
Mike Hoolehan, <lt>mike@sycamore.us<gt>

Contributions By:
Jim Searle, <lt>jims2@cox.net<gt>
Project hosted at sourceforge, at http://gnatsperl.sourceforge.net

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014, Richard Elberger.  All Rights Reserved.

Copyright (c) 1997-2003, Mike Hoolehan. All Rights Reserved.

This module is free software. It may be used, redistributed,
and/or modified under the same terms as Perl itself.

=cut
