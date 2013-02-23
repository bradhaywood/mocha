package pumpkin;
{
    $pumpkin::VERSION = '0.001';
}

=head1 NAME

pumpkin - Modern-ish Perl 5 pragma Prototype

=head1 SYNOPSIS

    # imports Mouse, Method::Signatures, 5.10 features (say, switch, etc),
    use pumpkin;

    # imports the same, but Mouse::Role instead of Mouse
    use pumpkin qw(role);

    # lose the signatures
    use pumpkin qw(-sigs);
    
    # lose signatures and Mouse
    use pumpkin qw(-sigs -oop);

=head1 WHY PUMPKIN???

Why not? Everyone has had their own opinions about the whole Perl 5 rename/fork/new version explosion, mine is simple. 
Forget changing it dramatically - add a new pragma. One that imports everything that fixes most of the gripes outsiders have with our language. 
There was talk of adding a MOP into Perl core. I'm not 100% sure what this means, but I wouldn't like it to be forced. So we have a simple pragma you can turn on to give you these abilities, and more, like signatures. OK, so you can do all of this already, why would I want to use pumpkin? 
I was writing several roles and the top of my files looks something like this:

    package MyApp::Role;
    
    use 5.010;
    use Method::Signatures;
    use Mouse::Role;
    

Now, they look like this

    package MyApp::Role;
    use pumpkin 'role';

It doesn't seem like a big difference, but to someone from the outside looking at Perl, that's a lot nicer.

=cut

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
    # and uh, basically re-write this entire thing
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

    {
        no strict 'refs';
        *{"${caller}::enum"} = sub {
            my ($name, @args) = @_;
            for (my $i = 0; $i < @args; $i++) {
                my $n = $i+1;
                my $opt = $args[$i];
                if (my ($opt, $n) = split ':', $opt) {
                    *{"${name}::$opt"} = sub { return $n; };
                }
            }
        };
    }
}

package
    type {
        sub number {
            my $i = shift;
            return $i =~ /[1-9](?:\d{0,2})(?:,\d{3})*(?:\.\d*[1-9])?|0?\.\d*[1-9]|0/;
        }

        sub float {
            my $f = shift;
            return $f =~ /^[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?$/;
        }

        sub struct {
            my ($name, $hash) = @_;
            {
                no strict 'refs';
                no warnings 'redefine';
                *{"${name}::new"} = sub {
                    my ($self, %args) = @_;
                    my $klass = {};
                    foreach my $key (keys %args) {
                        if ($hash->{$key}) {
                            my $type = $hash->{$key};
                            if (ref($type) eq 'CODE') {
                                $type = $type->($key);
                                if (ref($args{$key}) ne $type) {
                                    warn "Expecting a $type";
                                    return 0;
                                }
                            }
                            else {
                                if ($type eq 'String') {
                                    if (number($args{$key}) || $args{$key} !~ /\w+/) {
                                        warn "Expecting a string";
                                        return 0;
                                    }
                                }
                                elsif ($type eq 'Int') {
                                    if (! number($args{$key})) {
                                        warn "Expecting an integer";
                                        return 0;
                                    }
                                }
                                elsif ($type eq 'HashRef') {
                                    if (ref($args{$key}) ne 'HASH') {
                                        warn "Expecting a HashRef";
                                        return 0;
                                    }
                                }
                                elsif ($type eq 'ArrayRef') {
                                    if (ref($args{$key}) ne 'ARRAY') {
                                        warn "Expecting an ArrayRef";
                                        return 0;
                                    }
                                }
                                else {
                                    warn "Unknown type in struct";
                                    return 0;
                                }
                            }

                            $klass->{$key} = $args{$key};
                            *{"${name}::${key}"} = sub {
                                if (@_ > 1) { $_[0]->{$key} = $_[1]; }
                                return $_[0]->{$key};
                            };
                        }
                        else {
                            warn "No such key in struct ${name}: $key";
                            return 0;
                        }
                    }
                    return bless $klass, $name;
                };
            }
        }
}
=head1 AUTHOR

Brad Haywood <brad@perlpowered.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
