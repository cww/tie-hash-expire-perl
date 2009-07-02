#!/usr/bin/perl -w

use strict;

use Test::More;
use Tie::Hash::Expire;

# Reimplementation of sum() so that we don't have to depend on List::Util.
sub sum(@)
{
    my $sum = 0;

    $sum += $_ for @_;

    return $sum;
}

our %num_tests;

$num_tests{basic_args} = 3;
sub basic_args
{
    eval
    {
        tie my %h => 'Tie::Hash::Expire', LIFETIME => 2;
    };

    is($@, q{}, 'Basic creation with LIFETIME');

    eval
    {
        tie my %h => 'Tie::Hash::Expire', TIMEFUNC => sub {};
    };

    is($@, q{}, 'Basic creation with TIMEFUNC');
    
    eval
    {
        tie my %h => 'Tie::Hash::Expire', TIMEFUNC => sub {},
                                          LIFETIME => 2;
    };

    is($@, q{}, 'Basic creation with TIMEFUNC and LIFETIME');
}

plan tests => sum(values %num_tests);

basic_args();
