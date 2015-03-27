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
    printf("Set GENOME_SOFTWARE_RESULT_TEST_NAME to '%s'.\n", test_version());
    $ENV{GENOME_SOFTWARE_RESULT_TEST_NAME} = test_version();
    print "\n";
}

sub test_version {
    my $prefix = $ENV{TEST_VERSION_PREFIX} || '';
    return $prefix . Revision->test_version();
}

sub send_timeout_mail {
    send_mail_with_topic('Timed Out');
}

sub send_fail_mail {
    send_mail_with_topic('Build Failed');
}

sub send_diff_mail {
    my $diff_cmd = shift;

    send_mail_with_topic('Diffs Found',
        '********************************************************************************',
        $diff_cmd->bless_message,
        '********************************************************************************',
        $diff_cmd->diffs_message);
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

1;
