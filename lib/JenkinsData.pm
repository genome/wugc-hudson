package JenkinsData;

use strict;
use warnings;


sub job_name {
    return $ENV{JOB_NAME} or die 'JOB_NAME not set.';
}

sub build_url {
    return $ENV{BUILD_URL} or die 'BUILD_URL not set.';
}

sub build_number {
    return $ENV{BUILD_NUMBER} or die 'BUILD_NUMBER not set.';
}

sub test_spec {
    return $ENV{TEST_SPEC} or die 'TEST_SPEC not set.';
}

sub validate_environment {
    my $package = shift;

    $package->job_name;
    $package->build_url;
    $package->build_number;
    $package->test_spec;
}

1;
