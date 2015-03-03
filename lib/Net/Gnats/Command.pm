package Net::Gnats::Command;
use utf8;
use strict;
use warnings;


# USER [userid password]
#
# Specifies the userid and password for database access. Either both a
# username and password must be specified, or they both may be
# omitted; in the latter case, the current access level is returned.
#
# The possible server responses are:
#
# 350 (CODE_INFORMATION) The current access level is specified.
#
# 422 (CODE_NO_ACCESS) A matching username and password could not be
# found.
#
# 200 (CODE_OK) A matching username and password was found, and the
# login was successful.

sub user {
  my ( $c, $uid, $pwd ) = @_;
  my $c = 'USER';

  $c->send_cmd( $c . $SPC . $uid . $SPC . $pwd );
  is_error($r->code) and log_error($r) and return;
  return $r;
}

# QUIT
#
# Requests that the connection be closed. Possible responses:
#
# 201 (CODE_CLOSING) Normal exit.
#
# The QUIT command has the dubious distinction of being the only
# command that cannot fail.

sub quit {
  my $cmd = 'QUIT';
  return $c->send_cmd( $cmd );
  is_error($r->code) and log_error($r) and return;
  return $r;
}

# LIST list type
#
# Describes various aspects of the database. The lists are returned as
# a list of records, one per line. Each line may contain a number of
# colon-separated fields.
#
# Possible values for list type include

# Categories  : Describes the legal categories for the database.
#
# Submitters  : Describes the set of submitters for the database.
#
# Responsible : Lists the names in the responsible administrative
# file, including their full names and email addresses.
#
# States
#
# Lists the states listed in the state administrative file, including
# the state type (usually blank for most states; the closed state has
# a special type).
#
# FieldNames Lists the entire set of PR fields.
#
# InitialInputFields : Lists the fields that should be present when a
# PR is initially entered.
#
# InitialRequiredFields : Lists fields that have to be present and
# nonempty when a PR is initially entered (fields containing only
# blank characters such as spaces or newlines are considered empty.)
#
# Databases : Lists the set of databases.
#
# The possible responses are:
#
# 301 (CODE_TEXT_READY) Normal response, followed by the records
# making up the list as described above.
#
# 416 (CODE_INVALID_LIST) The requested list does not exist.

sub list {
  my ( $c ) = @_;
}

# FTYP field [field ...]
#
# Describes the type of data held in the field(s) specified with the
# command. The currently defined data types are:

# Text
#
# A plain text field, containing exactly one line.

# MultiText
#
# A text field possibly containing multiple lines of text.

# Enum
#
# An enumerated data field; the value is restricted to one entry out
# of a list of values associated with the field.

# MultiEnum
#
# The field contains one or more enumerated values. Values are
# separated with spaces or colons :.

# Integer
#
# The field contains an integer value, possibly signed.

# Date
#
# The field contains a date.

# TextWithRegex
#
# The value in the field must match one or more regular expressions
# associated with the field.

# The possible responses are:

# 350 (CODE_INFORMATION)
#
# The normal response; the supplied text is the data type.

# 410 (CODE_INVALID_FIELD_NAME)
#
# The specified field does not exist.

# If multiple field names were given, multiple response lines will be
# sent, one for each field, using the standard continuation protocol;
# each response except the last will have a dash - immedately after
# the response code.

sub ftyp {
}

# FTYPINFO field property

# Provides field-type-related information. Currently, only the
# property separators for MultiEnum fields is supported. When
# separators is specified, the possible return codes are:

# 350 (CODE_INFORMATION)
#
# A proper MultiEnum field was specified and the returned text is the
# string of separators specified for the field in the dbconfig file
# (see Field datatypes) quoted in ''s.

# 435 (CODE_INVALID_FTYPE_PROPERTY)
#
# The separators property is not defined for this field, i.e. the
# specified field is not of type MultiEnum.

# Currently, specifying a different property than separators results
# in return code 435 as above.

sub ftypinfo {
}

# FDSC field [field ... ]

# Returns a human-readable description of the listed field(s). The possible responses are:

# 350 (CODE_INFORMATION)
#
# The normal response; the supplied text is the field description.

# 410 (CODE_INVALID_FIELD_NAME)
#
# The specified field does not exist.

# Like the FVLD command, the standard continuation protocol will be
# used if multiple fields were specified with the command.

sub fdsc {
}

# FIELDFLAGS field [field ... ]

# Returns a set of flags describing the specified field(s). The possible responses are either

# 410 (CODE_INVALID_FIELD_NAME)
#
# meaning that the specified field is invalid or nonexistent, or

# 350 (CODE_INFORMATION)
#
# which contains the set of flags for the field. The flags may be
# blank, which indicate that no special flags have been set for this
# field.

# Like the FDSC and FTYP commands, multiple field names may be listed
# with the command, and a response line will be returned for each one
# in the order that the fields appear on the command line.

# The flags include:

# textsearch
#
# The field will be searched when a text field search is requested.

# allowAnyValue
#
# For fields that contain enumerated values, any legal value may be
# used in the field, not just ones that appear in the enumerated list.

# requireChangeReason
#
# If the field is edited, a reason for the change must be supplied in
# the new PR text describing the reason for the change. The reason
# must be supplied as a multitext PR field in the new PR whose name is
# field-Changed-Why (where field is the name of the field being
# edited).

# readonly
#
# The field is read-only, and cannot be edited.

sub fieldflags {
}

# FVLD field

# Returns one or more regular expressions or strings that describe the
# valid types of data that can be placed in field. Exactly what is
# returned is dependent on the type of data that can be stored in the
# field. For most fields a regular expression is returned; for
# enumerated fields, the returned values are the list of legal strings
# that can be held in the field.
#
# The possible responses are:
#
# 301 (CODE_TEXT_READY)
#
# The normal response, which is followed by the list of regexps or
# strings.

# 410 (CODE_INVALID_FIELD_NAME)
#
# The specified field does not exist.

sub fvld {
}

# VFLD field
#
# VFLD can be used to validate a given value for a field in the
# database. The client issues the VFLD command with the name of the
# field to validate as an argument. The server will either respond
# with 212 (CODE_SEND_TEXT), or 410 (CODE_INVALID_FIELD_NAME) if the
# specified field does not exist.
#
# Once the 212 response is received from the server, the client should
# then send the line(s) of text to be validated, using the normal
# quoting mechanism described for PRs. The final line of text is
# followed by a line containing a single period, again as when sending
# PR text.

# The server will then either respond with 210 (CODE_OK), indicating
# that the text is acceptable, or one or more error codes describing
# the problems with the field contents.

sub vfld {
}

# INPUTDEFAULT field [field ... ]
#
# Returns the suggested default value for a field when a PR is
# initially created. The possible responses are either 410
# (CODE_INVALID_FIELD_NAME), meaning that the specified field is
# invalid or nonexistent, or 350 (CODE_INFORMATION) which contains the
# default value for the field.
#
# Like the FDSC and FTYP commands, multiple field names may be listed
# with the command, and a response line will be returned for each one
# in the order that the fields appear on the command line.

sub inputdefault {
}

# RSET
#
# Used to reset the internal server state. The current query expression is cleared, and the index of PRs may be reread if it has been updated since the start of the session. The possible responses are:
#
# 200 (CODE_OK)
#
# The state has been reset.

# 440 (CODE_CMD_ERROR)
#
# One or more arguments were supplied to the command.

# 6xx (internal error)
#
# There were problems resetting the state (usually because the index
# could not be reread). The session will be immediately terminated.

sub rset {
}

# LKDB
#
# Locks the main gnats database. No subsequent database locks will
# succeed until the lock is removed. Sessions that attempt to write to
# the database will fail. The possible responses are:

# 200 (CODE_OK) The lock has been established.

# 440 (CODE_CMD_ERROR) One or more arguments were supplied to the
# command.

# 431 (CODE_GNATS_LOCKED) The database is already locked, and the lock
# could not be obtained after 10 seconds.

# 6xx (internal error) An internal error occurred, usually because of
# permission or other filesystem-related problems. The lock may or may
# not have been established.

sub lkdb {
}

# UNDB

# Unlocks the database. Any session may steal a database lock; no
# checking of any sort is done. The possible responses are:

# 200 (CODE_OK) The lock has been removed.

# 432 (CODE_GNATS_NOT_LOCKED) The database was not locked.

# 440 (CODE_CMD_ERROR) One or more arguments were supplied to the
# command.

# 6xx (internal error) The database lock could not be removed, usually
# because of permissions or other filesystem-related issues.

sub undb {
}

# LOCK PR user [pid]

# Locks the specified PR, marking the lock with the user name and the
# optional pid. (No checking is done that the user or pid arguments
# are valid or meaningful; they are simply treated as strings.)

# The EDIT command requires that the PR be locked before it may be
# successfully executed. However, it does not require that the lock is
# owned by the editing session, so the usefulness of the lock is
# simply as an advisory measure.

# The APPN and REPL commands lock the PR as part of the editing
# process, and they do not require that the PR be locked before they
# are invoked.

# The possible responses are:

# 440 (CODE_CMD_ERROR)
#
# Insufficient or too many arguments were specified to the command.

# 300 (CODE_PR_READY)
#
# The lock was successfully obtained; the text of the PR (using the
# standard quoting mechanism for PRs) follows.

# 400 (CODE_NONEXISTENT_PR)
#
# The PR specified does not exist.

# 430 (CODE_LOCKED_PR)
#
# The PR is already locked by another session.

# 6xx (internal error)
#
# The PR lock could not be created, usually because of permissions or
# other filesystem-related issues.

sub lock_pr {

  if ( $r->code == $CODE_LOCKED_PR      or
       $r->code == $CODE_CMD_ERROR      or
       $r->code == $CODE_NONEXISTENT_PR or
       $r->code >  $CODE_ERROR ) {
    return;
  }

  return $r;
}

# UNLK PR
#
# Unlocks PR. Any user may unlock a PR, as no checking is done to
# determine if the requesting session owns the lock.
#
# The possible responses are:

# 440 (CODE_CMD_ERROR)
#
# Insufficient or too many arguments were specified to the command.

# 200 (CODE_OK)
#
# The PR was successfully unlocked.

# 433 (CODE_PR_NOT_LOCKED)
#
# The PR was not locked.

# 6xx (internal error)
#
# The PR could not be unlocked, usually because of permission or other
# filesystem-related problems.


sub unlk_pr {
}

# DELETE PR
#
# Deletes the specified PR. The user making the request must have
# admin privileges (see Controlling access to databases). If
# successful, the PR is removed from the filesystem and the index
# file; a gap will be left in the numbering sequence for PRs. No
# checks are made that the PR is closed.
#
# The possible responses are:
#
# 200 (CODE_OK)
#
# The PR was successfully deleted.

# 422 (CODE_NO_ACCESS)
#
# The user requesting the delete does not have admin privileges.

# 430 (CODE_LOCKED_PR)
#
# The PR is locked by another session.

# 431 (CODE_GNATS_LOCKED)
#
# The database has been locked, and no PRs may be updated until the
# lock is cleared.

# 6xx (internal error)
#
# The PR could not be successfully deleted, usually because of
# permission or other filesystem-related problems.

sub delete_pr {
}

CHEK [initial]
Used to check the text of an entire PR for errors. Unlike the VFLD command, it accepts an entire PR at once instead of the contents of an individual field.
The initial argument indicates that the PR text to be checked is for a PR that will be newly created, rather than an edit or replacement of an existing PR.

After the CHEK command is issued, the server will respond with either a 440 (CODE_CMD_ERROR) response indicating that the command arguments were incorrect, or a 211 (CODE_SEND_PR) response code will be sent.

Once the 211 response is received from the server, the client should send the PR using the normal PR quoting mechanism; the final line of the PR is then followed by a line containing a single period, as usual.

The server will then respond with either a 200 (CODE_OK) response, indicating there were no problems with the supplied text, or one or more error codes listing the problems with the PR. 

sub chek {
}

EDIT PR
Verifies the replacement text for PR. If the command is successful, the contents of PR are completely replaced with the supplied text. The PR must previously have been locked with the LOCK command.
The possible responses are:

431 (CODE_GNATS_LOCKED) 
The database has been locked, and no PRs may be updated until the lock is cleared.

433 (CODE_PR_NOT_LOCKED) 
The PR was not previously locked with the LOCK command.

400 (CODE_NONEXISTENT_PR) 
The specified PR does not currently exist. The SUBM command should be used to create new PRs.

211 (CODE_SEND_PR) 
The client should now transmit the replacement PR text using the normal PR quoting mechanism. After the PR has been sent, the server will respond with either 200 (CODE_OK) indicating that the edit was successful, or one or more error codes listing problems either with the replacement PR text or errors encountered while updating the PR file or index. 

sub edit_pr {
}

EDITADDR address
Sets the e-mail address of the person communicating with gnatsd. The command requires at least the edit access level.
The possible responses are:

200 (CODE_OK) 
The address was successfully set.

440 (CODE_CMD_ERROR) 
Invalid number of arguments were supplied. 

sub editaddr {
}

# APPN PR field
#
# REPL PR field

# Appends to or replaces the contents of field in PR with the supplied
# text. The command returns a 201 (CODE_SEND_TEXT) response; the
# client should then transmit the new field contents using the
# standard PR quoting mechanism. After the server has read the new
# contents, it then attempts to make the requested change to the PR.

# The possible responses are:

# 200 (CODE_OK) The PR field was successfully changed.

# 400 (CODE_NONEXISTENT_PR) The PR specified does not exist.

# 410 (CODE_INVALID_FIELD_NAME) The specified field does not exist.

# 402 (CODE_UNREADABLE_PR) The PR could not be read.

# 431 (CODE_GNATS_LOCKED) The database has been locked, and no PRs may
# be updated until the lock is cleared.

# 430 (CODE_LOCKED_PR) The PR is locked, and may not be altered until
#     the lock is cleared.

# 413 (CODE_INVALID_FIELD_CONTENTS) The supplied (or resulting) field
#     contents are not valid for the field.

# 6xx (internal error) An internal error occurred, usually because of
# permission or other filesystem-related problems. The PR may or may
# not have been altered.

sub repl {
  my ( $c, $pr, $field, $text, $append ) = @_;
  my $cmd = defined $append ? 'APPN' : 'REPL';

}

# SUBM

# Submits a new PR into the database. The supplied text is verified for correctness, and if no problems are found a new PR is created.

# The possible responses are:

# 431 (CODE_GNATS_LOCKED) The database has been locked, and no PRs may
# be submitted until the lock is cleared.

# 211 (CODE_SEND_PR) The client should now transmit the new PR text
# using the normal quoting mechanism. After the PR has been sent, the
# server will respond with either

# 351 (CODE_INFORMATION_FILLER) and
# 350 (CODE_INFORMATION) responses indicating that the new PR has been
# created and supplying the number assigned to it, or one or more
# error codes listing problems with the new PR text.

sub subm {
}

# CHDB database

# Switches the current database to the name specified in the command.

# The possible responses are:

# 422 (CODE_NO_ACCESS)
#
# The user does not have permission to access the requested database.

# 417 (CODE_INVALID_DATABASE)
#
# The database specified does not exist, or one or more configuration
# errors in the database were encountered.

# 220 (CODE_OK)
#
# The current database is now database. Any operations performed will
# now be applied to database.

sub chdb {
}

# DBLS
#
# Lists the known set of databases.

# The possible responses are:

# 6xx (internal error) An internal error was encountered while trying
# to obtain the list of available databases, usually due to lack of
# permissions or other filesystem-related problems, or the list of
# databases is empty.

# 301 (CODE_TEXT_READY)
#
# The list of databases follows, one per line, using the standard
# quoting mechanism. Only the database names are sent.

# The gnatsd access level listdb denies access until the user has
# authenticated with the USER command. The only other command
# available at this access level is DBLS. This access level provides a
# way for a site to secure its gnats databases while still providing a
# way for client tools to obtain a list of the databases for use on
# login screens etc.

sub dbls {
}

# DBDESC database
#
# Returns a human-readable description of the specified database.
#
# Responses include:
#
# 6xx (internal error) An internal error was encountered while trying
# to read the list of available databases, usually due to lack of
# permissions or other filesystem-related problems, or the list of
# databases is empty.
#
# 350 (CODE_INFORMATION) The normal response; the supplied text is the
# database description.
#
# 417 (CODE_INVALID_DATABASE) The specified database name does not
# have an entry.

sub dbdesc {
}

# EXPR query expression
#
# Specifies a query expression used to limit which PRs are returned
# from the QUER command. The expression uses the normal query
# expression syntax, (see Query expressions).
#
# Multiple EXPR commands may be issued; the expressions are boolean ANDed together.
#
# Expressions are cleared by the RSET command.
#
# Possible responses include:
#
# 415 (CODE_INVALID_EXPR) The specified expression is invalid, and could not be parsed.
#
# 200 (CODE_OK) The expression has been accepted and will be used to limit the results returned from QUER.

sub expr {
}

# QFMT query format
#
# Use the specified query format to format the output of the QUER
# command. The query format may be either the name of a query format
# known to the server (see Named query definitions), or an actual
# query format (see Formatting query-pr output). The possible
# responses are:
#
# 200 (CODE_OK) The normal response, which indicates that the query
#     format is acceptable.
#
# 440 (CODE_CMD_ERROR) No query format was supplied.
#
# 418 (CODE_INVALID_QUERY_FORMAT) The specified query format does not
#     exist, or could not be parsed.

sub qfmt {
}

# QUER [PR] [PR] [...]
#
# Searches the contents of the database for PRs that match the
# (optional) specified expressions with the EXPR command. If no
# expressions were specified with EXPR, the entire set of PRs is
# returned.
#
# If one or more PRs are specified on the command line, only those PRs
# will be searched and/or output.
#
# The format of the output from the command is determined by the query
# format selected with the QFMT command.
#
# The possible responses are:

# 418 (CODE_INVALID_QUERY_FORMAT)
# A valid format was not specified with the QFMT command prior to invoking QUER.
#
# 300 (CODE_PR_READY) One or more PRs will be output using the
#     requested query format. The PR text is quoted using the normal
#     quoting mechanisms for PRs.

# 220 (CODE_NO_PRS_MATCHED)  No PRs met the specified criteria.

sub quer {
  my $cmd = 'QUER';
}

# GNATS SPECIFICATION
#
# ADMV field key [subfield]
#
# Returns an entry from an administrative data file associated with
# field. key is used to look up the entry in the data file. If
# subfield is specified, only the value of that subfield is returned;
# otherwise, all of the fields in the adm data file are returned,
# separated by colons :.
#
# The responses are:

# 410 (CODE_INVALID_FIELD_NAME) The specified field does not exist.
#
# 221 (CODE_NO_ADM_ENTRY) An adm entry matching the key was not found,
#      or the field does not have an adm file associated with it.
#
# 350 (CODE_INFORMATION) The normal response; the supplied text is the
#     requested field(s).

sub admv {


}


1;
