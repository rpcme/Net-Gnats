use ExtUtils::MakeMaker;

WriteMakefile(
  'NAME'               => 'Net::Gnats',
  'VERSION_FROM'       => 'lib/Net/Gnats.pm',
  'AUTHOR'             => 'Richard Elberger <riche@cpan.org>, ' .
                          'Mike Hoolehan <mike@sycamore.us>',
  'ABSTRACT'           => 'Interface to GNU Gnats Daemon',
  'MIN_PERL_VERSION'   => '5.010_000',
);
