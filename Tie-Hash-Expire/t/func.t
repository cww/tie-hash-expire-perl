#!/usr/bin/perl -w

use strict;

use lib '../lib';
use Tie::Hash::Expire;

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
