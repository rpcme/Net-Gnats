use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::Gnats',
    'VERSION_FROM'	=> 'Gnats.pm', # finds $VERSION
    'AUTHOR'	=> 'Mike Hoolehan <mike@sycamore.us>',
    'ABSTRACT'	=> 'Interface to GNU Gnats Daemon',
    'PREREQ_PM'		=> {}, # none
);
