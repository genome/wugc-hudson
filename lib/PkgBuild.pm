package PkgBuild;

use strict;
use warnings;
use English '-no_match_vars';
use File::Path;
use File::Temp qw/ tempdir /;
use File::Basename;
use Test::More;
use Cwd qw/ abs_path getcwd /;
use File::pushd;

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

    my $orig_dir = getcwd();
    my $src_dir = abs_path($package_dir);
    my $build_dir = tempdir(CLEANUP => 1);
    pushd($build_dir);
    my @pkgs_start = glob("$build_dir/*.$pkg_extension");
    my $cmd = qq{
        (
            cd $build_dir &&
            cmake $src_dir -DCMAKE_BUILD_TYPE=package &&
            make VERBOSE=1 &&
            ctest -V &&
            fakeroot cpack -G $generator
        ) 2>&1 | tee $build_log
    };
    run($cmd);
    my @pkgs_now = glob("$build_dir/*.$pkg_extension");
    my @pkgs;
    for my $pkg (@pkgs_now) {
        if (!grep { $_ eq $pkg } @pkgs_start) {
            run("cp $pkg $src_dir"); 
            push(@pkgs, "$package_dir/". basename($pkg));
        }
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
    my %pkgs;
    my @bfiles;
    my @sfiles = glob("/var/cache/pbuilder/result/${source}_*");
    foreach my $package (@packages) {
      # Note that members of bfiles may also be in sfiles
      push @bfiles, glob("/var/cache/pbuilder/result/${package}_*");
    }
    # uniqify
    map { $pkgs{$_} = 1 } @sfiles;
    map { $pkgs{$_} = 1 } @bfiles;
    my @pkgfiles = keys %pkgs;

    deploy($deb_upload_spool, \@pkgfiles, remove_on_success => 1);
    system("ls -lh $deb_upload_spool");

    # Clean up
    unlink "/var/cache/pbuilder/result/$source-build.log";

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
        my $gid = getgrnam("codesigner");
        chmod 0664, $p;
        chown $UID, $gid, $p;
        system("ls -lh $p");
        run("cp -a $p $dest") and print "deployed $p to $dest\n";
        run("cp -a $p $dest") and print "deployed $p to $dest\n";
        if ($opts{remove_on_success}) {
            unlink($p) or die "failed to remove $p after deploying";
        }
    } 
    return 1;
}

1;
