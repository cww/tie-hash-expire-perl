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

# Exercises SCALAR.
$num_tests{basic_scalar} = 3;
sub basic_scalar
{
    tie my %foo => 'Tie::Hash::Expire';

    is(scalar(keys %foo), 0, 'Basic SCALAR: zero elements');

    $foo{a} = 'bar';

    is(scalar(keys %foo), 1, 'Basic SCALAR: one element');

    $foo{b} = 'baz';

    is(scalar(keys %foo), 2, 'Basic SCALAR: two elements');
}

# Exercises STORE and FETCH.
$num_tests{basic_store_fetch} = 1 + 3 + 1 + 3;
sub basic_store_fetch
{
    tie my %foo => 'Tie::Hash::Expire';

    for (my $i = 0; $i < 3; ++$i)
    {
        $foo{$i} = $i + 1;
    }

    is(scalar(keys %foo), 3, 'Basic STORE: three elements');

    for (my $i = 0; $i < 3; ++$i)
    {
        is($foo{$i}, $i + 1, "Basic FETCH: element $i");
    }

    is(scalar(keys %foo), 3, 'Basic STORE: three elements after FETCH');

    $foo{a} = 'bar';

    is($foo{a}, 'bar', 'Basic FETCH: very basic');

    $foo{a} = 'baz';

    is($foo{a}, 'baz', 'Basic FETCH: overwrite');

    $foo{a} = 'quuuux';

    is($foo{a}, 'quuuux', 'Basic FETCH: overwrite longer');
}

# Exercises EXISTS.
$num_tests{basic_exists} = 3;
sub basic_exists
{
    tie my %foo => 'Tie::Hash::Expire';

    is(exists $foo{a} ? 1 : 0, 0, 'Basic EXISTS: new hash');

    $foo{a} = 'bar';

    is(exists $foo{a} ? 1 : 0, 1, 'Basic EXISTS: existent element');
    is(exists $foo{b} ? 1 : 0, 0, 'Basic EXISTS: non-existent element');
}

# Exercises DELETE.
$num_tests{basic_delete} = 3 + 1;
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
        is($foo{$i}, undef, "Basic DELETE: element $i");
    }

    is(scalar(keys %foo), 0, 'Basic complete DELETE test');
}

# Exercises DELETE and EXISTS.
$num_tests{basic_delete_exists} = 6 + 1;
sub basic_delete_exists
{
    tie my %foo => 'Tie::Hash::Expire';

    $foo{a} = 'bar';
    $foo{b} = 'baz';

    is(exists $foo{a} ? 1 : 0, 1,
       'Basic DELETE+EXISTS: existent element "a" (zero non-existent)');
    is(exists $foo{b} ? 1 : 0, 1,
       'Basic DELETE+EXISTS: existent element "b" (zero non-existent)');

    delete $foo{a};
    
    is(exists $foo{a} ? 1 : 0, 0,
       'Basic DELETE+EXISTS: non-existent element "a" (one non-existent)');
    is(exists $foo{b} ? 1 : 0, 1,
       'Basic DELETE+EXISTS: existent element "b" (one non-existent)');

    delete $foo{b};
    
    is(exists $foo{a} ? 1 : 0, 0,
       'Basic DELETE+EXISTS: non-existent element "a" (both non-existent)');
    is(exists $foo{b} ? 1 : 0, 0,
       'Basic DELETE+EXISTS: non-existent element "b" (both non-existent)');

    is(scalar(keys %foo), 0, 'Basic complete DELETE+EXISTS test');
}

# Exercises CLEAR.
$num_tests{basic_clear} = 2;
sub basic_clear
{
    tie my %foo => 'Tie::Hash::Expire';

    $foo{a} = 1;
    $foo{b} = 2;

    eval
    {
        %foo = ();
    };

    is($@, q{}, 'Basic CLEAR exception test');
    is(scalar(keys %foo), 0, 'Basic CLEAR scalar test');
}

# Exercises FIRSTKEY and NEXTKEY.
$num_tests{basic_firstkey_nextkey} = 1;
sub basic_firstkey_nextkey
{
    tie my %foo => 'Tie::Hash::Expire';

    my $num_high = 100;

    for (my $i = 0; $i < $num_high; ++$i)
    {
        $foo{$i} = $i * 2;
    }

    my @nums = (0 .. $num_high - 1);

    for my $key (keys %foo)
    {
        for (my $i = 0; $i < scalar(@nums); ++$i)
        {
            if ($nums[$i] == $key)
            {
                splice(@nums, $i, 1);
                last;
            }
        }
    }

    is(scalar(@nums), 0, 'Basic fill/purge with verify for FIRSTKEY+NEXTKEY');
}

plan tests => sum(values %num_tests);

basic_scalar();
basic_store_fetch();
basic_exists();
basic_delete();
basic_delete_exists();
basic_clear();
basic_firstkey_nextkey();
