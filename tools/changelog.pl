
use strict;

use Data::Dumper;
use File::chdir '$CWD';

#genome-250, genome-388
my ($rev1, $rev2) = @ARGV;
die "Whoops! Try: changelog.pl [REV1] [REV2]" if !$rev1 || !$rev2;
die "Error: rev1 and rev2 are both $rev1" if $rev1 eq $rev2

local $CWD = '/gscuser/jlolofie/dev/git/genome/lib/perl';

my $rev = join('..',$rev1, $rev2);
my $cmd = q[git log --pretty="format:JAGVILLSOVA%h	%ce	%s	%b " ] . $rev;

my $c = `$cmd`;


#undef $/;
#open(my $fh, '/gscuser/jlolofie/tmp/changelog');
#my $c = <$fh>;
#close($fh);


my $now = localtime();
print<<"_TOP_";

Change Log for $rev2
This is a summary of important changes (since $rev1).
For an exhaustive list try:  $ git log $rev1..$rev2
($now)
****************

_TOP_

my @lines = split(/JAGVILLSOVA/,$c);
my $i;
for my $l (@lines) {

    next if $i++ == 0;
    my ($hash, $email, $subj, $body) = split(/\t/,$l);
    chomp($body);

    my $r = {
        hash  => $hash,
        email => $email,
        subj  => $subj,
        body  => $body,
    };

    my @log;
    if ($subj =~ /CHANGELOG:\s*(.*)/) {
        push @log, $1;
    }

    if ($body =~ /CHANGELOG:/) {

        if ($body =~ /CHANGELOG:(.*?)\n*^\s*$/ms) {
            push @log, $1; 
        } else {
            $body =~ /CHANGELOG:(.*)\n/ms;
            push @log, $1;
        }
    }

    if (@log > 0) {
        $r->{'log'} = \@log;
        print_log_entry($r);
    }
}

exit;


sub print_log_entry {

    my ($r) = @_;

    my $log = join('', @{$r->{'log'}});
    printf("%s\n%s (%s)\n\n", $log, $r->{'email'}, $r->{'hash'});
}





