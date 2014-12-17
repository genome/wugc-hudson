use strict;
use warnings;

use Test::More;

use Changelog qw();
use File::Temp qw();
use Git::Repository qw();

my @cases = (
    [qq(CHANGELOG this is one subject),
     qr(^this is one subject)],
    [qq(CHANGELOG: this is two subject),
     qr(^this is two subject)],
    [qq(CHANGELOG this is three subject\n\nthis is three body),
     qr(^this is three subject\nthis is three body)],
    [qq(CHANGELOG: this is four subject\n\nthis is four body),
     qr(^this is four subject\nthis is four body)],
    [qq(this is five subject\n\nCHANGELOG this is five body),
     qr(^this is five body)],
    [qq(this is six subject\n\nCHANGELOG: this is six body),
     qr(^this is six body)],
    [qq(this is seven subject\n\nthis is unrelevant line\n\nCHANGELOG:  This is seven changelog.),
     qr(^This is seven changelog\.)],
    [qq(Remove ModelGroups from AnPs\n\nCHANGELOG: As of this commit, Analysis Projects no longer have\nan associated Model Group. The canonical source of Analysis Project),
     qr(^As of this commit, Analysis Projects no longer have\nan associated Model Group. The canonical source of Analysis Project)],
);
plan tests => scalar(@cases);

for my $case (@cases) {
    my $expected = $case->[1];
    next unless defined $expected;

    my $initial_tag = 'INITIAL';
    my $r = setup($initial_tag, $case);
    my $iter = Changelog->new($r, $initial_tag, 'HEAD');
    my $log = $iter->next;
    my $got = Changelog::formatted_log_message($log);
    like($got, $expected);
}

sub setup {
    my $initial_tag = shift;
    my @cases = @_;

    my $work_tree = File::Temp::tempdir();
    Git::Repository->run( init => $work_tree );
    my $r = Git::Repository->new( work_tree => $work_tree );

    $r->run('commit', '--allow-empty', '-m', 'initial commit');
    $r->run('tag', $initial_tag);

    for my $case (@cases) {
        my $msg = $case->[0];
        $r->run('commit', '--allow-empty', '-m', 'this is not a CHANGELOG');
        $r->run('commit', '--allow-empty', '-m', $msg);
        $r->run('commit', '--allow-empty', '-m', 'this is not a CHANGELOG');
    }

    return $r;
}
