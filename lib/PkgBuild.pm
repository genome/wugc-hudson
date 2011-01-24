package PkgBuild;

use strict;
use warnings;
use File::Path;
use Test::More;

BEGIN {
    require Cwd;
    require File::Basename;
    my $lib_dir = Cwd::abs_path(File::Basename::dirname(__FILE__) . '/../lib/');
    unless (grep { $lib_dir eq Cwd::abs_path($_) } @INC) {
        push @INC, $lib_dir;
    }
}
require Defaults;

my $DIST_DIR = Defaults::DIST_DIR();

sub execute {
    my $package_name = shift;
    my $build_type = shift;
    my %build_params;

    if ($build_type eq 'cpan') {
        build_cpan_package($package_name);
    }
    elsif ($build_type eq 'rpm') {
        $build_params{distro} = shift;
        build_rpm_package($package_name, \%build_params);
    }
    elsif ($build_type eq 'deb') {
        $build_params{distro} = shift;
        build_deb_package($package_name, \%build_params);
    }
    else {
        print "Unknown build type '$build_type'.\n";
        return;
    }
    return 1;
}

sub build_cpan_package {
    my $package_name = shift;

    chomp(my $package_dir = qx(find . -type d -name $package_name));
    my $build_pl = "$package_dir/Build.PL";
    my $package = $package_name;

    ok(run("cd $package_dir && perl Build.PL"), "build ./Build");
    ok(run("cd $package_dir && ./Build dist"), "built $package dist");

    File::Path::mkpath("$DIST_DIR/$package") unless (-d "$DIST_DIR/$package");
    ok(-d "$DIST_DIR/$package", "$DIST_DIR/$package directory exists");

    ok(run("cp -f $package_dir/*.tar.gz $DIST_DIR/$package/"), "copied dist to $DIST_DIR/$package/");

    my $cd = "cd $DIST_DIR/$package/";
    chomp(my @dists = qx($cd && ls *.tar.gz | sort -V | tail -n 2));

    my $current_version = $dists[0];
    my $devel_version;
    if (@dists == 2) {
        $devel_version = $dists[1];
    } else {
        $devel_version = $dists[0];
    }

    if ($devel_version) {
        ok(run("cd $DIST_DIR/$package/ && ln -sf $devel_version devel.tar.gz"), "symlinked $devel_version to devel");
    }

    if ($current_version) {
        ok(run("cd $DIST_DIR/$package/ && ln -sf $current_version current.tar.gz"), "symlink $current_version to current");
    }

    return 1;
}

sub build_deb_package {
    my $package_name = shift;
    my (%build_params) = %{(shift)};

    chomp(my $package_dir = qx(find . -type d -name $package_name));
    my $build_pl = "$package_dir/Build.PL";
    my $package = $package_name;

    ok(run("cd $package_dir && perl Build.PL"), "built ./Build");
    ok(run("cd $package_dir && ./Build"), "ran ./Build");
    ok(run("cd $package_dir && ./Build docs"), "ran ./Build docs");
    ok(run("cd $package_dir && dpkg-buildpackage -d"), "built deb");

    File::Path::mkpath("$DIST_DIR/$package") unless (-d "$DIST_DIR/$package");
    ok(-d "$DIST_DIR/$package", "$DIST_DIR/$package directory exists");

    ok(run("cp -f $package_dir/*.deb $DIST_DIR/$package/"), "copied dist to $DIST_DIR/$package/");

    my $cd = "cd $DIST_DIR/$package/";
    chomp(my @dists = qx($cd && ls *.deb | sort -V | tail -n 2));

    my $current_version = $dists[0];
    my $devel_version;
    if (@dists == 2) {
        $devel_version = $dists[1];
    } else {
        $devel_version = $dists[0];
    }

    if ($devel_version) {
        ok(run("cd $DIST_DIR/$package/ && ln -sf $devel_version devel.deb"), "symlinked $devel_version to devel");
    }

    if ($current_version) {
        ok(run("cd $DIST_DIR/$package/ && ln -sf $current_version current.deb"), "symlink $current_version to current");
    }

    return 1;
}

sub run {
    my $cmd = shift;
    #print "Running ($cmd)...\n";
    my $exit = qx($cmd);
    if ($? == 0) {
        return 1;
    } else {
        die "ERROR: Failed to execute ($cmd)!\n";
    }
}

1;
