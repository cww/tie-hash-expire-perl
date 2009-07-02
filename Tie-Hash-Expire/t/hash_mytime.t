#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;
use Tie::Hash::Expire;

# Reimplementation of sum() so that we don't have to depend on List::Util.
sub sum(@)
{
    my $sum = 0;

    $sum += $_ for @_;

    return $sum;
}

sub my_time_closure
{
    my $my_time = 0;

    return sub
    {
        my ($add) = @_;

        if (defined $add)
        {
            $my_time += $add;
        }

        return $my_time;
    };
}

my %num_tests;
my $my_time;
my $my_time_func = sub
{
    return $my_time;
};


sub _incr($)
{
    $my_time += $_[0];
}

# Exercises STORE and FETCH without expiry.
$num_tests{basic_no_expiry} = 1;
sub basic_no_expiry
{
    my $f = my_time_closure();
    tie my %foo => 'Tie::Hash::Expire', TIMEFUNC => $f, LIFETIME => undef;
    
    $foo{a} = 'bar';
    $f->(1_000);
    is($foo{a}, 'bar', 'Undefined LIFETIME');
}

# Exercises STORE and FETCH with simple expiry.
$num_tests{basic_expiry} = 2;
sub basic_expiry
{
    my $f = my_time_closure();
    tie my %foo => 'Tie::Hash::Expire', TIMEFUNC => $f, LIFETIME => 4;

    $foo{a} = 'bar';
    $f->(2);
    is($foo{a}, 'bar', 'Defined LIFETIME, pre-expiry (simple)');
    $f->(2);
    is(exists $foo{a} ? 1 : 0, 0, 'Defined LIFETIME, post-expiry (simple)');
}

# Exercises STORE and FETCH while resetting values.
$num_tests{expiry_reset} = 3;
sub expiry_reset
{
    my $f = my_time_closure();
    tie my %foo => 'Tie::Hash::Expire', TIMEFUNC => $f, LIFETIME => 8;

    $foo{a} = 'bar';
    $f->(7);
    is($foo{a}, 'bar', 'Defined LIFETIME, pre-expiry');
    $foo{a} = 'baz';
    $f->(7);
    is($foo{a}, 'baz', 'Defined LIFETIME, post-reset');
    $f->(1);
    is(exists $foo{a} ? 1 : 0, 0, 'Defined LIFETIME, post-expiry');
}

# Exercises STORE and FETCH while resetting values, with multiple elements.
$num_tests{expiry_reset_multiple} = 5;
sub expiry_reset_multiple
{
    my $f = my_time_closure();
    tie my %foo => 'Tie::Hash::Expire', TIMEFUNC => $f, LIFETIME => 8;

    $foo{a} = 'bar';
    $foo{b} = 'baz';
    $f->(4);
    $foo{b} = 'qux';
    $f->(3);
    is($foo{a}, 'bar', 'Defined LIFETIME, pre-expiry (multiple #1)');
    is($foo{b}, 'qux', 'Defined LIFETIME, pre-expiry (multiple #2)');
    $f->(2);
    is(exists $foo{a} ? 1 : 0, 0,
       'Defined LIFETIME, post-expiry (multiple #1)');
    is(exists $foo{b} ? 1 : 0, 1,
       'Defined LIFETIME, not-quite-post-expiry (multiple #2)');
    $f->(4);
    is(exists $foo{b} ? 1 : 0, 0,
       'Defined LIFETIME, post-expiry (multiple #2)');
}

plan tests => sum(values %num_tests);

basic_no_expiry();
basic_expiry();
expiry_reset();
expiry_reset_multiple();
