#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'pumpkin' ) || print "Bail out!\n";
}

diag( "Testing pumpkin $pumpkin::VERSION, Perl $], $^X" );
