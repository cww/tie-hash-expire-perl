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

=cut
sub print_defined
{
    my ($hash_ref, $key) = @_;

    if (exists $hash_ref->{$key})
    {
        print "[$key] exists.\n";

        if (defined $hash_ref->{$key})
        {
            print "[$key] is defined: [$hash_ref->{$key}].\n";
        }
    }
    else
    {
        print "[$key] does not exist.\n";
    }
}

tie my %foo => 'Tie::Hash::Expire', LIFETIME => 1;

$foo{i} = 1;
$foo{j} = 2;
$foo{k} = 3;

sleep(2);

print_defined(\%foo, 'i');

local $, = q{ };
print "keys foo: [ ", keys %foo, " ]\n";

#print_defined(\%foo, 'j');

for (0 .. 3)
{
    my ($k, $v) = each %foo;
    print "[$k=$v]\n";
}
