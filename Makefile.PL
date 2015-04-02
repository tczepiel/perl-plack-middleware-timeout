use strict;
use warnings;
use ExtUtils::MakeMaker;


WriteMakefile(
    NAME              => 'Plack::Middleware::Timeout',
    VERSION_FROM      => 'lib/Plack/Middleware/Timeout.pm',
    PREREQ_PM         => {
        'Scope::Guard' => 0,
    },
    ABSTRACT_FROM     => 'lib/Plack/Middleware/Timeout.pm',
    AUTHOR            => 'Tomasz Czepiel <tjmc@cpan.org>',
    LICENSE           => 'perl',
);
