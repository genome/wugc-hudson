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
my $deb_upload_spool = "/gscuser/codesigner/incoming/lucid-genome-development/";

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
        ok(run("cd $DIST_DIR/$package/ && unlink devel.tar.gz"), "unlinked devel");
        ok(run("cd $DIST_DIR/$package/ && ln -sf $devel_version devel.tar.gz"), "symlinked $devel_version to devel");
    }

    if ($current_version) {
        ok(run("cd $DIST_DIR/$package/ && unlink current.tar.gz"), "unlinked current");
        ok(run("cd $DIST_DIR/$package/ && ln -sf $current_version current.tar.gz"), "symlink $current_version to current");
    }

    return 1;
}

sub build_cpack_package {
    my ($package_dir, $generator, $build_log) = @_;

    $build_log = "$package_dir/last_build.log" unless($build_log);

    my $pkg_extension = lc($generator);
    $generator = uc($generator); # cpack is picky

    my @pkgs_start = glob("$package_dir/*.$pkg_extension");
    my $cmd = qq{
        (
            cd $package_dir &&
            cmake . -DCMAKE_BUILD_TYPE=package &&
            make &&
            ctest &&
            fakeroot cpack -G $generator
        ) 2>&1 | tee $build_log
    };
    run($cmd);
    my @pkgs_now = glob("$package_dir/*.$pkg_extension");
    my @pkgs;
    for my $pkg (@pkgs_now) {
        push(@pkgs, $pkg) if !grep { $_ eq $pkg } @pkgs_start; 
    }
    return @pkgs;
}

sub build_deb_package {
    my $package_name = shift;
    my (%build_params) = %{(shift)};

    chomp(my $package_dir = qx(find . -maxdepth 1 -type d -name $package_name));

    my @packages;
    my $source;
    open(FH,"<$package_dir/debian/control") or die "Cannot open $package_dir/debian/control";
    while(<FH>) {
      if (/^Source:/) {
        $source = pop @{ [ split /\s+/, $_ ] };
      }
      if (/^Package:/) {
        push @packages, pop @{ [ split /\s+/, $_ ] };
      }
    }
    close(FH);

    # .debs get signed and added to the apt repo via the codesigner role
    # Check that we can write there before we build.
    my $deb_upload_spool = "/gscuser/codesigner/incoming/lucid-genome-development/";
    ok(-w "$deb_upload_spool", "$deb_upload_spool directory is writable");

    # .debs get built via pdebuild, must be run on a build host, probably a slave to hudson
    ok(run("cd $package_dir && /usr/bin/pdebuild --auto-debsign --logfile /var/cache/pbuilder/result/$source-build.log"), "built deb");

    # Put all files, source, binary, and meta into spool.
    my @pkgfiles = glob("/var/cache/pbuilder/result/${source}_*");
    deploy($deb_upload_spool, \@pkgfiles, remove_on_success => 1);
    ok(run("cp -f /var/cache/pbuilder/result/${source}_* $deb_upload_spool"), "copied source files to $deb_upload_spool");
    foreach my $package (@packages) {
      ok(run("cp -f /var/cache/pbuilder/result/${package}_*.deb $deb_upload_spool"), "copied binary debs to $deb_upload_spool");
    }
    # Clean up
    unlink "/var/cache/pbuilder/result/$source-build.log";
    unlink glob("/var/cache/pbuilder/result/${source}_*");
    unlink glob("../${source}_*");
    foreach my $package (@packages) {
      unlink glob("/var/cache/pbuilder/result/${package}_*.deb");
      unlink glob("../${package}_*.deb");
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

sub deploy {
    my ($dest, $packages, %opts) = @_;
    die "$dest directory is writable" unless -w "$dest";
    for my $p (@$packages) {
        run("cp $p $dest") and print "deployed $p to $dest\n";
        if ($opts{remove_on_success}) {
            unlink($p) or die "failed to remove $p after deploying";
        }
    } 
    return 1;
}

1;
