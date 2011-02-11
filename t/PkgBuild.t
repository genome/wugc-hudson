#!/usr/bin/env perl

BEGIN {
	require File::Basename;
	push @INC, File::Basename::dirname(__FILE__) . '/../lib/';
}

use Test::More tests => 25;
use File::Temp qw/tempdir/;
use File::Slurp qw/write_file/;

use_ok("PkgBuild");

my $cmakelists = q{
cmake_minimum_required(VERSION 2.6)
install(FILES foo.txt DESTINATION share/foo)
enable_testing(true)
add_test(true /bin/true)
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "foo")
set(CPACK_PACKAGE_NAME "foo")
set(CPACK_PACKAGE_VENDOR "test")
set(CPACK_PACKAGE_VERSION "1.0")
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "Test Case <test@case.com>")
set(CPACK_SYSTEM_NAME "Linux")
set(CPACK_GENERATOR "DEB")
include(CPack)
};

test_cpack_generator("deb");
test_cpack_generator("rpm");

sub test_cpack_generator {
    my $generator = shift;
    my $tmpdir = tempdir(CLEANUP => 1);
    my $proj_dir = "$tmpdir/foo";

    my $pkgname = "foo-1.0-Linux.$generator";
    ok(mkdir("$proj_dir"), "made temp project directory");
    ok(write_file("$proj_dir/CMakeLists.txt", $cmakelists), "wrote CMake file");
    ok(write_file("$proj_dir/foo.txt", "foo"), "wrote test project file");

    my $dir = File::Basename::dirname(__FILE__);
    my @deb = PkgBuild::build_cpack_package($proj_dir, $generator);
    is(scalar @deb, 1, "got 1 package");
    is($deb[0], "$proj_dir/$pkgname", "package has expected name");
    ok(-f "$proj_dir/$pkgname", "found package file");

    my $target = "$tmpdir/deploy";
    mkdir($target);
    ok(PkgBuild::deploy($target, \@deb), "deployed packages");
    ok(-f "$target/$pkgname", "found deployed package file at $target/$pkgname");
    ok(-f "$proj_dir/$pkgname", "deploy did not remove file when not asked to");

    $target .= "2";
    mkdir($target);
    ok(PkgBuild::deploy($target, \@deb, remove_on_success => 1), "deployed packages");
    ok(-f "$target/$pkgname", "found deployed package file");
    ok(! -f "$proj_dir/$pkgname", "deploy did remove file when asked to");
}
