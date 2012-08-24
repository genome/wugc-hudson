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

package main; ##########################################################

use Genome;
use Test::More tests => 13;

my $test_count = 0;

my $model_name = $ENV{MODEL_NAME};
my $job_url = $ENV{JOB_URL};
my $timeout = $ENV{BUILD_TIMEOUT};

ok($model_name, 'model name was specified') or BAIL_OUT('model name was not specified');
ok($job_url, 'job url was specified') or BAIL_OUT('job url was not specified');
ok($timeout, 'timeout was specified') or BAIL_OUT('timeout was not specified');

my $test_revision = Revision->test_version('HEAD');
ok($test_revision, 'test revision is specified');

build($model_name, $test_revision, $timeout);

diff($model_name, $job_url, $test_revision);

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

    my $model = Genome::Model->get(name => $model_name);
    unless ($model) {
        print STDERR "Model not found: $model_name\n";
        return;
    }
    my $list_cmd = sprintf('list-blessed-builds -m %s -p %s', $model->id, Revision->perl_version());
    my $list_cmd_output = qx($list_cmd);
    chomp $list_cmd_output;
    my $blessed_git_revision = (split("\t", $list_cmd_output))[2];
    unless ($blessed_git_revision) {
        print STDERR "Blessed Git Revision not defined:\n$list_cmd_output";
        return;
    }
    my $blessed_snapshot_version = sprintf('%s-%s', Revision->perl_version(), $blessed_git_revision);

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

        my $set_cmd = sprintf('set-blessed-build -m %s -p %s -g %s', $model->id, Revision->perl_version(), $test_revision);
    if ($has_diffs) {
        diag qq(If you want to bless this build run '$set_cmd'.)
    } else {
        my $set_cmd_exit = system($set_cmd);
        is($set_cmd_exit, 0, 'Set Blessed Build');
    }
}
