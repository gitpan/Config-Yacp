use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Config::Yacp',
    'VERSION_FROM'	=> 'Yacp.pm', # finds $VERSION
    'PREREQ_PM'		=> {Parse::RecDescent => 0,
			    Carp => 0,
			    Data::Dumper => 0,
			    Fcntl => 0}, # e.g., Module::Name => 1.1
);
