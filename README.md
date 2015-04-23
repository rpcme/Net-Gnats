Net-Gnats
=========
[![Build Status](https://travis-ci.org/rpcme/Net-Gnats.svg?branch=master)](https://travis-ci.org/rpcme/Net-Gnats)
[![Coverage Status](https://coveralls.io/repos/rpcme/Net-Gnats/badge.svg)](https://coveralls.io/r/rpcme/Net-Gnats)
[![CPAN version](https://badge.fury.io/pl/Net-Gnats.svg)](http://badge.fury.io/pl/Net-Gnats)

Repository for the Net::Gnats module.

Version
-------
The current version is 0.18.

Changes in 0.18
---------------
Bugfix Github issue #1 regarding expression concatenation.
Bugfix Github issue #4 regarding perldoc parse problems in Net::Gnats.
Fixed stubbed subroutines which caused test failures for Perl 5.10.1.
Added additional tests and documentation for Net::Gnats::Command.
Added additional tests and documentation for Net::Gnats::Command::ADMV.
Removed dead code from Net::Gnats::Session.

Changes in 0.17
---------------
Added ability to submit a PR from a PR object.

Changes in 0.16
---------------
Set consistent versioning across all modules.
Added 'strictures' to PREREQ_PM.

Changes in 0.15
---------------
Completely reworked sessions and issuing commands.
Comprehensive tests, removing all stubs.
Known issue: attachments not managed
Known issue: after submit of PR, new PR number not captured into the PR object.
