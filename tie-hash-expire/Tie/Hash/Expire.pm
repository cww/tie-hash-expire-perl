package Tie::Hash::Expire;

use strict;
use warnings;

use Carp;
use Tie::Hash;

our @ISA = qw(Tie::Hash);

BEGIN
{
    eval
    {
        require Time::HiRes;
    };

    if (!$@)
    {
        Time::HiRes->import('time');
    }
}

sub _is_expired
{
    my ($self, $key) = @_;

    return $self->{EXPIRE}->{$key} <= time();
}

sub _delete
{
    my ($self, $key) = @_;

    print "DELETE [$key]\n";

    delete $self->{HASH}->{$key};
    delete $self->{EXPIRE}->{$key};
    delete $self->{SCHEDULE_DELETE}->{$key};
}

sub _delete_scheduled
{
    my ($self) = @_;

    for my $key (keys %{$self->{SCHEDULE_DELETE}})
    {
        print "DELETE SCHEDULED [$key]\n";
        $self->_delete($key);
    }

    $self->{SCHEDULE_DELETE} = {};
}

sub _update_cache
{
    my ($self, $key) = @_;

    print "UPDATE [$key]\n";

    if ($self->_is_expired($key))
    {
        $self->_delete($key);
    }
}

sub _next_key
{
    my ($self) = @_;
    
    while (my $key = each(%{$self->{HASH}}))
    {
        # If we find an expired key, we can't delete it right away because
        # we'd risk messing up the order of each().  Schedule it for later.
        if ($self->_is_expired($key))
        {
            $self->{SCHEDULE_DELETE}->{$key} = 1;
        }
        else
        {
            return $key;
        }
    }

    return undef;
}

sub TIEHASH
{
    my ($self, %args) = @_;

    if (!defined $args{LIFETIME} || $args{LIFETIME} <= 0)
    {
        # Just use a real hash, will you?  It'll be faster!
        return {};
    }

    my %node =
    (
        LIFETIME        => $args{LIFETIME},
        HASH            => {},
        EXPIRE          => {},
        SCHEDULE_DELETE => {},
    );

    return bless \%node, $self;
}

sub FETCH
{
    my ($self, $key) = @_;

    return exists $self->{HASH}->{$key} ? $self->{HASH}->{$key} : undef;
}

sub STORE
{
    my ($self, $key, $value) = @_;

    $self->{HASH}->{$key} = $value;
    $self->{EXPIRE}->{$key} = time() + $self->{LIFETIME};
    delete $self->{SCHEDULE_DELETE}->{$key};
}

sub EXISTS
{
    my ($self, $key) = @_;

    return exists $self->{HASH}->{$key};
}

sub CLEAR
{
    my ($self) = @_;

    $self->{HASH} = {};
    $self->{EXPIRE} = {};
    $self->{SCHEDULE_DELETE} = {};
}

sub DELETE
{
    my ($self, $key) = @_;

    $self->_delete($key);
}

sub SCALAR
{
    my ($self) = @_;

    return scalar %{$self->{HASH}};
}

sub FIRSTKEY
{
    my ($self) = @_;

    # Reset internal iterator.
    my $a = keys %{$self->{HASH}};

    return $self->_next_key();
}

sub NEXTKEY
{
    # Perl is kind enough to give us last_key as the second argument, but we
    # don't need it here.
    my ($self, undef) = @_;

    return $self->_next_key();
}

# Integrate cache expiry via the symbol table.
for my $f (qw(FETCH EXISTS))
{
    eval qq
    {
        *Tie::Hash::Expire::_uncached_$f = *Tie::Hash::Expire::$f;
        undef *Tie::Hash::Expire::$f;
        *Tie::Hash::Expire::$f = sub
        {
            \$_[0]->_update_cache(\$_[1]);
            &_uncached_$f;
        };
    };
}

# Integrate scheduled deletion via the symbol table.
for my $f (qw(SCALAR FIRSTKEY))
{
    eval qq
    {
        *Tie::Hash::Expire::_unsched_$f = *Tie::Hash::Expire::$f;
        undef *Tie::Hash::Expire::$f;
        *Tie::Hash::Expire::$f = sub
        {
            \$_[0]->_delete_scheduled();
            &_unsched_$f;
        };
    };
}

1;
