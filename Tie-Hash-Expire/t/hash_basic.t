#!/usr/bin/perl -w

use strict;

use Test::More;
use Tie::Hash::Expire;

use constant NUM_TESTS => 30;

plan tests => NUM_TESTS;

tie my %foo => 'Tie::Hash::Expire';

for (my $i = 0; $i < NUM_TESTS; ++$i)
{
    $foo{"zzz${i}zzz"} = $i * 2;
}

for (my $i = 0; $i < NUM_TESTS; ++$i)
{
    is($foo{"zzz${i}zzz"}, $i * 2, "Basic functionality: $i / " . NUM_TESTS);
}
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
