package Library;

BEGIN {
    require Cwd;
	require File::Basename;
    my $lib_dir = Cwd::abs_path(File::Basename::dirname(__FILE__));
    unless (grep { $lib_dir eq Cwd::abs_path($_) } @INC) {
        push @INC, $lib_dir;
    }
}

require Defaults;


# Shamelessly stolen from Genome/Utility/Text.pm
sub model_class_name_to_string {
    my $type = shift;
    $type =~ s/Genome::Model:://;
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

    my $msg = MIME::Lite->new(
        From => $from,
        To => $to,
        Subject => $subject,
        Data => $data,
        Cc => $cc,
    );
    $msg->send();
}

1;
