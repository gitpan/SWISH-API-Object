use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SWISH::API::Object',
    VERSION_FROM      => 'lib/SWISH/API/Object.pm', # finds $VERSION
    PREREQ_PM         => {

               'SWISH::API::Stat' => '0.02',
               'Data::Dump' => '1.06',


}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/SWISH/API/Object.pm', # retrieve abstract from module
       AUTHOR         => 'Peter Karman <karman@cpan.org>') : ()),

    clean => { FILES => 't/index.swish-e t/index.swish-e.prop' }
);
