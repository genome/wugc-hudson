package Library;

BEGIN {
	require File::Basename;
	push @INC, File::Basename::dirname(__FILE__);
}

use UR;
use LWP::Simple;
require Defaults;

####
# Parse Hudson's build status RSS feed and return the most recent successful build from today.
#
# Yes I am using Regexs to parse Xml. See:
# http://stackoverflow.com/questions/1732348/regex-match-open-tags-except-xhtml-self-contained-tags/1732454#1732454
####
sub check_for_new_build { # returns new build number or 0 if none.
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
    $mon = ($mon+1); # mon is 0 indexed by default.

    my $rss_feed = get(Defaults::RSS_FEED_URL());

    my @entries = ($rss_feed =~ /<entry>(.+?)<\/entry>/g);

    foreach (@entries) {
        $_ =~ /<published>\d{4}-(\d+)-(\d+)T.+<\/published>/; # $1 is month, $2 is day
        if ($1 == ($mon) && $2 == $mday) { # this build is from today.
            $_ =~ /<title>Genome #(\d+)\s\((\w+)\)<\/title>/;
            if ($2 eq "SUCCESS") {
                return $1;
            }
        }
    }
    return 0;
}

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
