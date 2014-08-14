use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker::Coverage;

WriteMakefile(
              'NAME' => 'Net::Gnats',
              'VERSION_FROM' => 'lib/Net/Gnats.pm',
              'AUTHOR'	=> 'Richard Elberger <rich@cpan.org, ' .
                           'Mike Hoolehan <mike@sycamore.us>',
              'ABSTRACT' => 'Interface to GNU Gnats Daemon',
              'PREREQ_PM' => {},
);
