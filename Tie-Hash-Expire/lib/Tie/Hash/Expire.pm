package Tie::Hash::Expire;

use warnings;
use strict;

use Carp;
use Tie::Hash;

our @ISA = qw(Tie::Hash);

=head1 NAME

Tie::Hash::Expire - The great new Tie::Hash::Expire!

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Tie::Hash::Expire;

    my $foo = Tie::Hash::Expire->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=cut

our $VERSION = '0.01';

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

=head1 METHODS

=cut

=head2 TIEHASH

Creates the hash, with an optional LIFETIME parameter.  If LIFETIME is
undefined or zero, you would be better off using an ordinary hash instead
of this fancy, tied type; however, this module will play along, anyway.

=cut
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

=head2 FETCH

Returns the value corresponding to a key.  If the key does not exist in the
underlying hash, returns undef.

=cut
sub FETCH
{
    my ($self, $key) = @_;

    return exists $self->{HASH}->{$key} ? $self->{HASH}->{$key} : undef;
}

=head2 STORE

Stores a key-value pair in the underlying hash.  Sets the expiry time to the
current time plus LIFETIME.  If the key had previously been scheduled for
deletion, unschedules it.

=cut
sub STORE
{
    my ($self, $key, $value) = @_;

    $self->{HASH}->{$key} = $value;
    $self->{EXPIRE}->{$key} = time() + $self->{LIFETIME};
    delete $self->{SCHEDULE_DELETE}->{$key};
}

=head2 EXISTS

Returns a true value if the key exists in the underlying hash or false if the
key does not exist in the underlying hash.

=cut
sub EXISTS
{
    my ($self, $key) = @_;

    return exists $self->{HASH}->{$key};
}

=head2 CLEAR

Resets the underlying hash and all expiry times.  Also removes all scheduled
deletion records.

=cut
sub CLEAR
{
    my ($self) = @_;

    $self->{HASH} = {};
    $self->{EXPIRE} = {};
    $self->{SCHEDULE_DELETE} = {};
}

=head2 DELETE

Deletes a key-value pair from the underlying hash.

=cut
sub DELETE
{
    my ($self, $key) = @_;

    $self->_delete($key);
}

=head2 SCALAR

Returns the scalar value of the underlying hash.

=cut
sub SCALAR
{
    my ($self) = @_;

    return scalar %{$self->{HASH}};
}

=head2 FIRSTKEY

Returns the first key in the hash, for iterative purposes.

=cut
sub FIRSTKEY
{
    my ($self) = @_;

    # Reset internal iterator.
    my $a = keys %{$self->{HASH}};

    return $self->_next_key();
}

=head2 NEXTKEY

Returns the next key in the hash, using the iterator first assigned in
FIRSTKEY() or later reassigned in a previous NEXTKEY() call as a basis for
search.

=cut
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

=head1 AUTHOR

Colin Wetherbee <cww@cpan.org>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-tie-hash-expire at rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Tie-Hash-Expire>.  I will
be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Tie::Hash::Expire

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tie-Hash-Expire>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tie-Hash-Expire>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tie-Hash-Expire>

=item * Search CPAN

L<http://search.cpan.org/dist/Tie-Hash-Expire>

=back

=head1 COPYRIGHT

Copyright (c) 2009 Colin Wetherbee

=head1 LICENSE

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut

1;