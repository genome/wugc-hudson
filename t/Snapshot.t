#!/usr/bin/env perl

use Test::More;

BEGIN {
	require File::Basename;
	push @INC, File::Basename::dirname(__FILE__) . '/../lib/';
}
require_ok('Snapshot');
require_ok('Defaults');
test_execute_or_die();
test_find_snapshot();
done_testing();

sub test_execute_or_die {
	{
		my $rv = eval { Snapshot::execute_or_die("perl -e 'die;'") };
		my $errors = $@;
		ok($errors, 'execute_or_die died when not exiting cleanly');
	}
	{
		my $rv = eval { Snapshot::execute_or_die("perl -e 'exit;'") };
		my $errors = $@;
		ok(!$errors, 'execute_or_die exited cleanly');
	}	
}

sub test_find_snapshot {
	{
		my $current_pipeline_snapshot = readlink($Defaults::CURRENT_PIPELINE);
		my ($current_pipeline_name) = $current_pipeline_snapshot =~ /(genome-\d+(-fix\d+)?)/;
		ok($current_pipeline_name, 'got current pipeline snapshot name');
		my $found_snapshot = Snapshot::find_snapshot($current_pipeline_name);
		ok($found_snapshot, 'found snapshot from current pipeline sanphost name');
		ok($found_snapshot =~ /$current_pipeline_snapshot\/?/, 'found snapshot matches original source')
	}
}