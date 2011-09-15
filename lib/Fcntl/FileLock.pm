# Marked as read-only because this module is actually from:
# git@github.com:nnutter/Fcntl--FileLock.git
# Will add as submodule and symlink or something later.

package Fcntl::FileLock;

use strict;
use warnings;

use Fcntl;

sub create { my $self = shift; return $self->new(@_); }
sub new {
    my $class = shift;
    my %params = @_;

    my $path = delete $params{path};
    unless ($path) { die "Must specify a path" };

    my $fh = delete $params{fh};
    unless ($fh) { sysopen($fh, $path, O_CREAT|O_RDWR) };
    unless ($fh) { die "Failed to open file handle" };

    my $object = {path => $path, fh => $fh};

    return bless $object, $class;
}

sub path {
    my $self = shift;
    return $self->{path};
}

sub fh {
    my $self = shift;
    return $self->{fh};
}

sub set_lock {
    my $self = shift;
    my $type = shift;

    unless(defined $type) {
        die "A lock type must be specified.\n";
    }

    my $struct = $self->create_fcntl_struct(type => $type);
    my $lock = fcntl($self->fh, F_SETLK, $struct);

    return (defined $lock);
}

sub lock {
    my $self = shift;
    my $type = shift || F_WRLCK;
    return $self->set_lock($type);
}

sub release {
    my $self = shift;
    return $self->set_lock(F_UNLCK);
}

sub unlink {
    my $self = shift;
    my $fh = $self->fh;
    my $path = $self->path;
    close $fh;
    unlink $path;
}

sub create_fcntl_struct {
    my $self = shift;
    my %params = @_;

    my $type = delete $params{type};
    unless ($type) { die "Must specify type of lock (e.g. F_SETLK, F_UNLCK, F_WRLCK)" };

    # defaults to locking whole file
    my $whence = delete $params{whence} || 0;
    my $start = delete $params{start} || 0;
    my $len = delete $params{len} || 0;

    # defaults to current process pid
    my $pid = delete $params{pid} || $$;

    my $struct = pack('s s l l s', $type, $whence, $start, $len, $pid);

    return $struct;
}

1;
