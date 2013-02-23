package pumpkin;
{
    $pumpkin::VERSION = '0.001';
}

use 5.010;
use warnings;
use strict;

use Import::Into;
use feature ();

sub import {
    my ($class, @opts) = @_;
    my $caller = caller;

    feature->import(':5.10');

    # TODO: change behaviour to
    # no => [ qw/ roles sigs/ ]
    if (not grep { $_ eq '-sigs' } @opts) {
        require Method::Signatures;
        Method::Signatures->import::into($caller);
    }

    if (not grep { $_ eq '-oop' } @opts) {
        if (grep { $_ eq 'role' } @opts) {
            require Mouse::Role;
            Mouse::Role->import::into($caller);
        }
        else {
            require Mouse;
            Mouse->import::into($caller);
        }
    }
    else {
        warnings->import();
        strict->import();
    }
}

1;
