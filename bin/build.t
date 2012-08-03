#!/usr/bin/perl

use strict;
use warnings;
use Data::Dump 'pp';

package Revision; ######################################################

sub git_short_rev {
    my $package = shift;
    my $ref = shift;
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
    return sprintf("%s-%s", $package->perl_version(), $package->git_short_rev(@_));
}

package JenkinsBuild; ##################################################

use JSON;
use LWP::Simple;

sub new {
    my $class = shift;
    my $url = shift;
    return bless({url => $url}, $class);
}

sub url {
    return shift->{url};
}

sub get_json_hash {
    my $self = shift;
    my $content = get($self->url);
    return unless $content;
    my $hash = decode_json($content);
    return $hash;
}

sub get_action {
    my $self = shift;
    my $action = shift;
    my $hash = $self->get_json_hash();
    my ($action_node) = grep { exists $_->{$action} } @{$hash->{'actions'}};
    return $action_node->{$action};
}

sub lastBuiltRevision {
    my $self = shift;
    return $self->get_action('lastBuiltRevision')->{SHA1};
}

sub get_parameter_value {
    my $self = shift;
    my $parameter_name = shift;
    my $parameters_array = $self->get_action('parameters');
    my ($parameter_node) = grep { $_->{name} eq $parameter_name } @$parameters_array;
    return $parameter_node->{value};
}

package main; ##########################################################

use Genome;
use Test::More;

my $test_count = 0;

my $skip_diff = ($ENV{SKIP_DIFF} eq 'true' ? 1 : 0);
my $model_name = $ENV{MODEL_NAME};
my $job_url = $ENV{JOB_URL};
my $timeout = $ENV{BUILD_TIMEOUT};

if ($skip_diff) {
    plan tests => 8;
} else {
    plan tests => 12;
}

ok($model_name, 'model name was specified') or BAIL_OUT('model name was not specified');
ok($job_url, 'job url was specified') or BAIL_OUT('job url was not specified');
ok($timeout, 'timeout was specified') or BAIL_OUT('timeout was not specified');

my $test_revision = Revision->test_version('HEAD');
ok($test_revision, 'test revision is specified');

build($model_name, $test_revision, $timeout);

if ($skip_diff) {
    ok(1, 'SKIP_DIFF turned on');
} else {
    diff($model_name, $job_url, $test_revision);
}

sub build {
    my $model_name = shift;
    my $test_revision = shift;
    my $timeout = shift;

    my $build = Genome::Model::Build->get(
        model_name => $model_name,
        run_by => 'apipe-tester',
        software_revision => $test_revision,
        status => ['Scheduled', 'Running', 'Succeeded'],
    );
    if ($build) {
        ok($build, sprintf('got an existing build (%s)', $build->id));
    } else {
        my $model = Genome::Model->get(name => $model_name) or die;
        $build = Genome::Model::Build->create(
            model_id => $model->id,
            software_revision => $test_revision,
        ) or die;
        $build->start();
        UR::Context->commit();
        is($build->status, 'Scheduled', sprintf('scheduled a new build (%s)', $build->id)) or die;
    }

    my $event = $build->the_master_event;
    ok($event, 'got the_master_event') or die;
    my $interval = ($timeout > 60 ? 60 : 1);
    my $start_time = time;
    my $last_report_time = $start_time;
    while (!grep { $event->event_status eq $_ } ('Succeeded', 'Failed', 'Crashed')) {
        UR::Context->current->reload($event);
        my $elapsed_time = time - $start_time;
        if ($elapsed_time > $timeout) {
            ok(0, 'build completed before timeout reached') or BAIL_OUT(sprintf('Build not complete within specified timeout (%s).', $timeout));
        }
        my $elapsed_report_time = time - $last_report_time;
        if ($elapsed_report_time > 5) {
            diag "Waited $elapsed_time seconds.";
            $last_report_time += $elapsed_report_time;
        }
        sleep($interval);
    }

    $build = UR::Context->current->reload('Genome::Model::Build', id => $build->id);
    is($build->status, 'Succeeded', 'build succeeded') or die;
}

sub diff {
    my $model_name = shift;
    my $job_url = shift;
    my $test_revision = shift;

    my $build_url = sprintf("%s/lastStableBuild/api/json", $job_url);
    my $build = JenkinsBuild->new($build_url);
    my $last_stable_revision = substr($build->lastBuiltRevision(), 0, 7);
    ok($last_stable_revision, 'got a last stable revision') or BAIL_OUT('Failed to get last stable revision.');
    my $blessed_snapshot_version = sprintf('%s-%s', Revision->perl_version(), $last_stable_revision);
    my $blessed_build = Genome::Model::Build->get(
        model_name => $model_name,
        run_by => 'apipe-tester',
        software_revision => "$blessed_snapshot_version",
        status => 'Succeeded',
    );
    ok($blessed_build, 'Found Blessed Build') or die;

    my $new_build = Genome::Model::Build->get(
        model_name => $model_name,
        run_by => 'apipe-tester',
        software_revision => $test_revision,
        status => 'Succeeded',
    );
    ok($new_build, 'Found New Build') or die;

    my $diff_cmd = Genome::Model::Build::Command::Diff->create(
        blessed_build => $blessed_build,
        new_build => $new_build,
    );
    ok($diff_cmd->execute, sprintf('Executed Diff Command (blessed build = %s and new build = %s)', $blessed_build->id, $new_build->id)) or die;

    my $has_diffs = (defined($diff_cmd->diffs) && scalar(keys %{$diff_cmd->diffs})) || 0;
    is($has_diffs, 0, 'No Diffs Found') or diag $diff_cmd->diffs_message();
}
