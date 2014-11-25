package Changelog;

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw();

use Git::Repository::Log::Iterator qw();

sub formatted_log_message {
    my ($log) = @_;

    my @msg;
    if ($log->subject =~ /^CHANGELOG/) {
        push @msg,
            _strip_changelog($log->subject),
            _strip_changelog($log->body);
    } elsif ($log->body =~ /^CHANGELOG/) {
        push @msg, _strip_changelog($log->body);
    }

    for my $text ($log->subject, $log->body) {
        if ($text =~ /^CHANGELOG/) {
            push @msg, _strip_changelog($text);
        }
    }

    return sprintf("%s\n-- %s (%s)\n\n",
        join("\n", @msg), $log->author_name, substr($log->commit, 0, 7),
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
    return (grep { /^CHANGELOG/ } ($log->subject, $log->body))
        ? 1 : 0;
}

1;
