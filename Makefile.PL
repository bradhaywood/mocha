use 5.010;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name     'mocha';
all_from 'lib/mocha.pm';
author   q{Brad Haywood <brad@perlpowered.com>};
license  'artistic2';

perl_version 5.006;

tests_recursive('t');

resources (
   #homepage   => 'http://yourwebsitehere.com',
   #IRC        => 'irc://irc.perl.org/#mocha',
   license    => 'http://www.perlfoundation.org/artistic_license_2_0',
   repository => 'https://github.com/bradhaywood/mocha', 
   #bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=mocha',
);

configure_requires (
   'Module::Install' => 0,
);

build_requires (
   'Test::More' => 0,
);

requires (
   'Import::Into' => 0,
   'Method::Signatures' => '20130222',
   'Mouse' => 0,
   'true' => 0,
   'namespace::autoclean' => 0,
);

install_as_cpan;
auto_install;
WriteAll;
