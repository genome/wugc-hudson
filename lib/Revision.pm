package Revision;

sub get_perl_version {
    # Watch out! This works in 5.8 and up - $^V is a vstring in 5.8
    # Other, nicer-looking ways of dealing with $^V won't work in 5.8.
    my $version = sprintf("%vd", $^V);

    # we only want 2 digits like 5.8 not 5.8.7
    $version =~ s/\.\d+$//;

    return $version;
}

sub get_head_rev {
    return get_pipeline_rev("HEAD");
}

sub get_pipeline_rev {
    my ($pipeline_version) = @_;

    $git_rev = `git rev-parse --short $pipeline_version`;
    die "No reference version available for $pipeline_version" unless $git_rev;
    chomp $git_rev;

    return get_perl_version() . "-$git_rev";
}

1;
