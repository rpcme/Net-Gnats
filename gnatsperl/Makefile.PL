use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker::Coverage;

WriteMakefile(
  'NAME'               => 'Net::Gnats',
  'VERSION_FROM'       => 'lib/Net/Gnats.pm',
  'AUTHOR'             => 'Richard Elberger <riche@cpan.org>, ' .
                          'Mike Hoolehan <mike@sycamore.us>',
  'ABSTRACT'           => 'Interface to GNU Gnats Daemon',
  'CONFIGURE_REQUIRES' => {'ExtUtils::MakeMaker::Coverage' => '0.03',
                          },
  'MIN_PERL_VERSION'   => '5.010_000',
  'NO_META'            => 'false',
);
