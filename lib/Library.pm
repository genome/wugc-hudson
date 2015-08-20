package Library;

use strict;
use warnings;
use Revision;
use JenkinsData;
use Genome;

BEGIN {
    require Cwd;
	require File::Basename;
    my $lib_dir = Cwd::abs_path(File::Basename::dirname(__FILE__));
    unless (grep { $lib_dir eq Cwd::abs_path($_) } @INC) {
        push @INC, $lib_dir;
    }
}

require Defaults;


sub log_environment {
    print "\n\n => Environment Info\n";
    print join("\n\t", "PATHs:", split(':', $ENV{PATH})), "\n";
    print join("\n\t", "PERL5LIBs:", split(':', $ENV{PERL5LIB})), "\n";
    print "\n";
}

sub set_genome_software_result_test_name {
    print("Customizing test environment...\n");
    printf("Set software_result_test_name to '%s'.\n", test_version());
    Genome::Config::set_env('software_result_test_name', test_version());
    print "\n";
}

sub test_version {
    my $prefix = $ENV{TEST_VERSION_PREFIX} || '';
    return $prefix . Revision->test_version();
}

sub get_timeout_seconds {
    my $hours = shift;
    return $hours * 3600;
}

sub send_timeout_mail {
    send_mail_with_topic('Timed Out');
}

sub send_fail_mail {
    send_mail_with_topic('Build Failed');
}

sub send_diff_mail {
    my @diff_cmds = @_;

    my @diffs_messages = map {$_->diffs_message} @diff_cmds;
    send_mail_with_topic('Diffs Found',
        '********************************************************************************',
        @diffs_messages);
}

sub send_mail_with_topic {
    my $topic = shift;
    my @extra_body = @_;

    my ($to, $cc) = get_to_and_cc();

    send_mail(
        from => 'apipe-tester@genome.wustl.edu',
        to => $to,
        cc => $cc,
        subject => mail_subject($topic),
        body => mail_body(@extra_body),
    );
}

sub mail_subject {
    my $topic = shift;
    return sprintf('%s - Build %d - %s', JenkinsData->test_spec,
        JenkinsData->build_number, $topic);
}

sub mail_body {
    return join("\n",
        sprintf('Project: %s', JenkinsData->job_name),
        sprintf('Build: %s', JenkinsData->build_url),
        sprintf('Console: %sconsole', JenkinsData->build_url),
        @_,
    );
}


sub get_to_and_cc {
    if (Genome::Sys->username eq 'apipe-tester') {
        my $to_default = users_to_addresses(Users::apipe());
        my $cc_default = users_to_addresses(Users::apipe());

        my $to = email_env('MODEL_TEST_TO', $to_default);
        my $cc = email_env('MODEL_TEST_CC', $cc_default);
        return $to, $cc;
    } else {
        return Genome::Sys->current_user->email;
    }
}

sub email_env {
    my $key = shift;
    my $default = shift;
    if (exists $ENV{$key}) {
        if ($ENV{$key}) {
            return $ENV{$key};
        }
        else {
            return;
        }
    }
    else {
        return $default;
    }
}
# Shamelessly stolen from Genome/Utility/Text.pm
sub model_class_name_to_string {
    my $type = shift;
    $type =~ s/Genome::Model:://;
    $type =~ s/:://g;
    my @words = split( /(?=(?<![A-Z])[A-Z])|(?=(?<!\d)\d)/, $type);
    return join('_', map { lc $_ } @words);
}

sub users_to_addresses {
    my @users = @_;
    return join(',', map { $_ . '@genome.wustl.edu' } @users);
}

sub send_mail {
    my %params = @_;
    my $subject = $params{subject} || die "No subject provided to send_mail method!";
    my $data = $params{body} || die "No messsage body provied to send_mail method!";
    my $from = $params{from} || sprintf('%s@genome.wustl.edu', $ENV{'USER'});
    my $cc = $params{cc} || '';
    my $to = $params{to} || die "No to parameters provided to send_mail method!"; 
    my $stdout = $params{stdout} || 1;

    if ($stdout) {
        printf("Sending mail...\n");
        printf("From => %s\n", $from);
        printf("To => %s\n", $to);
        printf("Subject => %s\n", $subject);
        printf("%s\n", $data);
    }

    my $msg = MIME::Lite->new(
        From => $from,
        To => $to,
        Subject => $subject,
        Data => $data,
        Cc => $cc,
    );
    $msg->send();
}

sub setup_model_process_test {
    log_environment();
    JenkinsData->validate_environment;

# set the title of this process
    $0 = sprintf("%s %s # TEST_SPEC = %s", $^X, __FILE__, JenkinsData->test_spec);

}

sub wait_for_build {
    my $build = shift;
    my $start_time = shift;
    my $timeout = shift;

    my $event = $build->the_master_event;
    unless ($event) {
        fail("Could not get the build's master event!\n");
    }

    printf("Monitoring build (%s) until it completes or timeout "
        . "of %s minutes is reached.\n\n", $build->id, $timeout / 60);

    while (!grep { $event->event_status eq $_ } ('Succeeded',
            'Failed', 'Crashed')) {
        UR::Context->current->reload($event);
        UR::Context->current->reload($build);
        my $elapsed_time = time - $start_time;
        if ($elapsed_time > $timeout) {
            printf("Build (%s) timed out after %s minutes\n",
                $build->id, $timeout / 60);
            Library::send_timeout_mail();
            Library::build_view_and_exit($build);
        }

        sleep(30);
    }
}

sub check_build_failure {
    my $build = shift;

    if ($build->status eq 'Succeeded') {
        printf("Build status is %s.\n", $build->status);
    } else {
        Library::send_fail_mail();
        Library::build_view_and_exit($build);
    }
}

sub wait_for_process {
    my $process = shift;
    my $timeout = shift;

    printf("Monitoring process (%s) until it completes or timeout "
        . "of %s minutes is reached.\n\n", $process->id, $timeout / 60);

    my $start_time = time;
    while (!grep { $process->status eq $_ } ('Succeeded', 'Crashed')) {
        UR::Context->current->reload($process);

        my $elapsed_time = time - $start_time;
        if ($elapsed_time > $timeout) {
            printf("Process (%s) timed out after %s minutes\n",
                $process->id, $timeout / 60);
            Library::send_timeout_mail();
            process_view_and_exit($process);
        }

        sleep(30);
    }
}

sub process_view_and_exit {
    my $process = shift;
    my $pv_command = Genome::Process::Command::View->create(
        process => $process);
    $pv_command->execute;
    exit(255);
}

sub check_process_failure {
    my $process = shift;

    if ($process->status eq 'Succeeded') {
        printf("Process status is %s.\n", $process->status);
    } else {
        Library::send_fail_mail();
        Library::process_view_and_exit($process);
    }
}

sub build_view_and_exit {
    my $build = shift;
    my $bv_command = Genome::Model::Build::Command::View->create(
        build => $build);
    $bv_command->execute;
    exit(255);
}

sub fail {
    my $test_name = shift;
    if (scalar(@_) == 1) {
        print @_;
    } elsif (scalar(@_) > 1) {
        printf @_;
    } else {
        print "Failed to execute $test_name\n";
    }

    exit(255);
}
1;
