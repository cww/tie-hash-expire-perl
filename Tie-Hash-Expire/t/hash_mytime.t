#!/usr/bin/perl -w

use strict;

use Test::More;
use Tie::Hash::Expire;

our $my_time;
my $my_time_func = sub
{
    return $my_time;
};

tie my %foo => 'Tie::Hash::Expire', TIMEFUNC => $my_time_func, LIFETIME => 1;

plan tests => 2;
$my_time = 1;
$foo{a} = 4;
is($foo{a}, 4, 'mytime1');
$my_time = 3;
is($foo{a}, undef, 'mytime2');
