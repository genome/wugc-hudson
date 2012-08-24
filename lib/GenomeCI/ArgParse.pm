package GenomeCI::ArgParse;

use Getopt::Long;

sub argparse {
    my ($man, $help, $db, $model_id, $perl_version, $git_revision) = (0) x 2;

    GetOptions(
        'help|?' => \$help,
        'man' => \$man,
        'database|d:s' => \$db,
        'model_id|m:i' => \$model_id,
        'perl-version|p:f' => \$perl_version,
        'git-revision|g:s' => \$git_revision,
    ) or pod2usage(2);
    pod2usage(1) if $help;
    pod2usage(-exitstatus => 0, -verbose => 2) if $man;

    if (@ARGV) {
        print STDERR 'No bare arguments expected: ', join(' ', @ARGV), "\n";
        exit(2);
    }

    if ($ENV{GENOMECI_DB}) {
        $db = $ENV{GENOMECI_DB};
    }
    unless (-e $db) {
        print STDERR "--database does not exist: $db\n";
        exit(2);
    }

    if (defined $perl_version && $perl_version !~ /^5\.\d+$/) {
        print STDERR "--perl-version must be 5.x: $perl_version\n";
        exit(2);
    }

    if (defined $git_revision && $git_revision !~ /^[\w\d]+$/) {
        print STDERR "--git-revision must be alphanumeric: $git_revision\n";
        exit(2);
    }

    return (model_id => $model_id, perl_version => $perl_version, git_revision => $git_revision, db => $db);
}

1;
