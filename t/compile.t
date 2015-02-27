#!/usr/bin/env perl
use Test::More;
require File::Basename;
my $base_dir = File::Basename::dirname(__FILE__) . '/../';

my @files;
push @files, qx[grep -l -r '^#!.*perl' $base_dir/bin];
push @files, qx[find $base_dir/lib -type f -name '*.pm'];

@files = grep { $_ !~ /.*~/ } @files;
@files = grep { $_ !~ /\._.*/} @files;

map { chomp $_ } @files;

for my $file (@files) {
	my $exit = system("$^X -c $file");
	ok($exit == 0, "$file compiled");
}
done_testing();
