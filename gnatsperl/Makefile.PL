use ExtUtils::MakeMaker;
use ExtUtils::MakeMaker::Coverage;

WriteMakefile(
              'NAME' => 'Net::Gnats',
              'VERSION_FROM' => 'code/Net/Gnats.pm',
              'AUTHOR'	=> 'Richard Elberger <rich@richelberger.com, ' .
                           'Mike Hoolehan <mike@sycamore.us>',
              'ABSTRACT' => 'Interface to GNU Gnats Daemon',
              'PREREQ_PM' => {},
);
