package Changelog;

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw();

use Git::Repository::Log::Iterator qw();

sub formatted_log_message {
    my ($log) = @_;

    if ($log->subject =~ /^CHANGELOG/) {
        my $changelog = join("\n", _strip_changelog($log->subject), $log->body);
        return _signed_changelog($log->author_name, $log->commit, $changelog);
    }

    my @paragraphs =
        map { _strip_changelog($_) }
        grep { /^CHANGELOG/ }
        split(/\n\n/, $log->body);
    chomp @paragraphs;
    @paragraphs =
        map { _signed_changelog($log->author_name, $log->commit, $_) }
        @paragraphs;

    return join('', @paragraphs);
}

sub _signed_changelog {
    my ($author_name, $commit, @msg) = @_;
    return sprintf("%s\n-- %s (%s)\n\n",
        join("\n", @msg), $author_name, substr($commit, 0, 7),
    );
}

sub _strip_changelog {
    my ($text) = @_;
    $text =~ s/^CHANGELOG:*\s*//;
    return $text;
}

sub new {
    my $class = shift;

    my @args;
    if ( $_[0] && ref $_[0] && $_[0]->isa('Git::Repository') ) {
        push @args, shift @_;
    }
    push @args, join('..', @_[0..1]);

    bless {
        iterator => Git::Repository::Log::Iterator->new(@args),
    }, $class;
}

sub next {
    my ($self) = @_;
    while ( my $log = $self->{iterator}->next ) {
        next unless _has_changelog($log);
        return $log;
    }
}

sub _has_changelog {
    my ($log) = @_;
    return (grep { /^CHANGELOG/ } ($log->subject, split(/\n/, $log->body)))
        ? 1 : 0;
}

1;
