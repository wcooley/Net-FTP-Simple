use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::FTP::Simple',
    AUTHOR              => 'Wil Cooley <wcooley@nakedape.cc>',
    VERSION_FROM        => 'lib/Net/FTP/Simple.pm',
    ABSTRACT_FROM       => 'lib/Net/FTP/Simple.pm',
    EXCLUDE_EXT         => [ qw( Net::FTP::Fake ) ],
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-FTP-Simple-*' },
);
