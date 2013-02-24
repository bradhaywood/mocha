package mocha;
{
    $mocha::VERSION = '0.002';
}

=head1 NAME

mocha - Modern-ish Perl 5 pragma Prototype

=head1 SYNOPSIS

    # imports Moo, Method::Signatures, 5.10 features (say, switch, etc),
    use mocha;

    # imports the same, but Moo::Role instead of Moo
    use mocha as => 'role';

    # lose the signatures
    use mocha no => [qw/ sigs /];
    
    # lose signatures and Moo
    use mocha no => [qw/ sigs oop /];

    # want Moose instead of Moo?
    use mocha with => 'Moose';

=head1 WHY MOCHA??

Why not? Everyone has had their own opinions about the whole Perl 5 rename/fork/new version explosion, mine is simple. 
Forget changing it dramatically - add a new pragma. One that imports everything that fixes most of the gripes outsiders have with our language. 
There was talk of adding a MOP into Perl core. I'm not 100% sure what this means, but I wouldn't like it to be forced. So we have a simple pragma you can turn on to give you these abilities, and more, like signatures. OK, so you can do all of this already, why would I want to use mocha? 
I was writing several roles and the top of my files looks something like this:

    package MyApp::Role;
    
    use 5.010;
    use Method::Signatures;
    use Moo::Role;
    

Now, they look like this

    package MyApp::Role;
    use mocha as => 'role';

It doesn't seem like a big difference, but to someone from the outside looking at Perl, that's a lot nicer.

=head1 DIFFERENCES

I guess the closest module to mocha is L<nextgen>. However, there are a few differences. Firstly, mocha imports L<Method::Signatures> so you can use C<method> and C<func> with signatures instead of subs. Also, it utilises L<Moo> instead of L<Moose> by default. Mocha also allows you to change the framework if you wanted to use something else (ie: Moose or L<Mouse>, if you really must). And mocha also supports Roles, which means instead of just importing the base OOP framework module, it will import Moo::Role instead using a simple human-readable command.

=cut

use 5.010;
use warnings;
use strict;

use Import::Into;
use feature ();
use namespace::autoclean ();

sub import {
    my ($class, %opts) = @_;
    my $caller = caller;

    feature->import(':5.10');

    my ($has_sigs, $has_oop, $is_role) = (1, 1, 0);
    my $oop_fw = 'Moo';

    if ($opts{no}) {
        if (ref $opts{no} eq 'ARRAY') {
            for my $thing (@{$opts{no}}) {
                $has_sigs = 0
                    if $thing eq 'sigs';
                $has_oop = 0
                    if $thing eq 'oop';
            }
        }
    }

    if ($opts{with}) {
        if ($has_oop) {
            my @valid_oops = qw(Mouse Moo Moose);
            $oop_fw = $opts{with}
                if grep { $_ eq $opts{with} } @valid_oops;
        }
    }

    if ($opts{as}) {
        if ($has_oop && $opts{as} eq 'role') {
            $is_role = 1;
        }
    }

    if ($has_sigs) {
        require Method::Signatures;
        Method::Signatures->import::into($caller);
    }

    if ($caller ne 'main') {
        if ($has_oop) {
            if ($is_role) {
                my $klass = "${oop_fw}::Role";
                _load_framework ($caller, "$oop_fw\::Role");
            }
            else {
                _load_framework ($caller, $oop_fw);
            }

            namespace::autoclean->import(-cleanee => $caller)
                if defined $caller->can('meta');
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

sub _load_framework {
    my ($target, $module) = @_;
    (my $file = $module) =~ s|::|/|g;
    require "$file.pm";
    
    loadit: {
        local $@;
        eval qq{
            package $target;
            $module->import();
        };
    }
    
    return 1;
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
