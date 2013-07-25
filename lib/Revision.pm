package Revision;

use Memoize;

use strict;
use warnings;


memoize('git_revision');


sub git_revision {
    my $package = shift;
    my $ref = shift || 'HEAD';
    my $rev = qx(git rev-parse --short $ref);
    chomp $rev;
    return $rev;
}

sub perl_version {
    my $package = shift;
    my $v = sprintf("%vd", $^V);
    my ($maj, $min, $bug) = split(/\./, $v);
    return "$maj.$min";
}

sub test_version {
    my $package = shift;
    return sprintf("%s-%s", $package->perl_version(), $package->git_revision(@_));
}

sub get_perl_version { # DEPRECATED
    # Watch out! This works in 5.8 and up - $^V is a vstring in 5.8
    # Other, nicer-looking ways of dealing with $^V won't work in 5.8.
    my $version = sprintf("%vd", $^V);

    # we only want 2 digits like 5.8 not 5.8.7
    $version =~ s/\.\d+$//;

    return $version;
}

sub get_head_rev { # DEPRECATED
    return get_pipeline_rev("HEAD");
}

sub get_pipeline_rev { # DEPRECATED
    my ($pipeline_version) = @_;

    my $git_rev = `git rev-parse --short $pipeline_version`;
    die "No reference version available for $pipeline_version" unless $git_rev;
    chomp $git_rev;

    return get_perl_version() . "-$git_rev";
}

1;
