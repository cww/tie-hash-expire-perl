#!/usr/bin/perl -w

use strict;

use Test::More;
use Tie::Hash::Expire;

eval 'use List::Util qw(sum);';

if ($@)
{
    plan skip_all => 'List::Util is required for testing basic hash ' .
                     'functionality.';
}

our %num_tests;

$num_tests{basic_mutate} = 3;
sub basic_mutate
{
    tie my %foo => 'Tie::Hash::Expire';

    for (my $i = 0; $i < 3; ++$i)
    {
        $foo{$i} = $i + 1;
    }

    for (my $i = 0; $i < 3; ++$i)
    {
        is($foo{$i}, $i + 1, "Basic mutate: $i / $num_tests{basic_mutate}");
    }
}

$num_tests{basic_delete} = 3;
sub basic_delete
{
    tie my %foo => 'Tie::Hash::Expire';

    for (my $i = 0; $i < 3; ++$i)
    {
        $foo{$i} = $i + 1;
    }

    for (my $i = 0; $i < 3; ++$i)
    {
        delete $foo{$i};
        is($foo{$i}, undef, "Basic delete: $i / $num_tests{basic_delete}");
    }
}

plan tests => sum(values %num_tests);

basic_mutate();
basic_delete();
