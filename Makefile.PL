use 5.010;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name     'pumpkin';
all_from 'lib/pumpkin.pm';
author   q{Brad Haywood <brad@perlpowered.com>};
license  'artistic2';

perl_version 5.006;

tests_recursive('t');

resources (
   #homepage   => 'http://yourwebsitehere.com',
   #IRC        => 'irc://irc.perl.org/#pumpkin',
   license    => 'http://www.perlfoundation.org/artistic_license_2_0',
   #repository => 'git://github.com/Brad Haywood/pumpkin.git',
   #bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=pumpkin',
);

configure_requires (
   'Module::Install' => 0,
);

build_requires (
   'Test::More' => 0,
   'Import::Into' => 0,
   'Method::Signatures' => '20130222',
   'Mouse' => 0,
);

requires (
   #'ABC'              => 1.6,
   #'Foo::Bar::Module' => 5.0401,
);

install_as_cpan;
auto_install;
WriteAll;
