use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Net::Gnats',
    'PM'        =>  {
                        'Gnats.pm'    => '$(INST_LIBDIR)/Gnats.pm',
                        'Gnats/PR.pm' => '$(INST_LIBDIR)/Gnats/PR.pm',
                    },
    'VERSION_FROM'	=> 'Gnats.pm', # finds $VERSION
    'AUTHOR'	=> 'Mike Hoolehan <mike@sycamore.us>',
    'ABSTRACT'	=> 'Interface to GNU Gnats Daemon',
    'PREREQ_PM'		=> {}, # none
);
