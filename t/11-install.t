use strict;
use warnings;
use Test::More;
use Cwd              qw(abs_path);
use File::Path       qw(make_path);
use Text::ParseWords qw(shellwords);
use lib 't/lib';
use VeeTest;
my $root     = abs_path('.');
my @shell    = shellwords( $ENV{VEE_TEST_SHELL} || '/bin/sh' );
my @commands = qw(vee veels veecat veefind vee-rebuild vee-publish);
my $home     = blog();
my $r        = run_command( $home, [ @shell, "$root/install.sh" ] );
is( $r->{code}, 0, 'default user install' ) or diag $r->{err};

for my $command (@commands) {
    ok( -x "$home/.local/bin/$command", "$command installed executable" );
    is( slurp("$home/.local/bin/$command"), slurp("bin/$command"), "$command copied intact" );
}
ok( !-e "$home/.veerc", 'installer leaves user config alone' );
my $site = blog();
$r = run_command( $site, [ "$home/.local/bin/vee", '-b', '-U', '-f', 'none', '-t', 'Installed' ], "installed body\n", { PATH => "$home/.local/bin:$ENV{PATH}" } );
is( $r->{code}, 0, 'installed vee and companion commands publish' );
like( slurp("$site/vee.html"), qr/Installed/, 'installed publisher creates index' );
my $prefix = "$home/a prefix's directory";
$r = run_command( $home, [ @shell, "$root/install.sh", '--prefix', $prefix ] );
is( $r->{code}, 0, 'custom prefix with spaces and apostrophe' );
ok( -x "$prefix/bin/vee", 'custom binary location' );
my ($path_command) = $r->{out} =~ /^  (export PATH=.*)$/m;
ok( defined $path_command, 'PATH instruction printed' );
$r = run_command( $home, [ '/bin/sh', '-c', "$path_command\nprintf '%s' \"\$PATH\"\n" ] );
is( $r->{code}, 0, 'PATH instruction is valid shell' );
like( $r->{out}, qr/^\Q$prefix\/bin:\E/, 'PATH instruction preserves prefix literally' );
$r = run_command( $home, [ @shell, "$root/install.sh", '--prefix', 'relative' ] );
is( $r->{code}, 0, 'relative prefix' );
ok( -x "$home/relative/bin/vee", 'relative prefix anchored to cwd' );

for my $args ( ['--unknown'], ['--prefix'], [ '--prefix', '' ] ) {
    $r = run_command( $home, [ @shell, "$root/install.sh", @$args ] );
    isnt( $r->{code}, 0, 'invalid installer arguments fail' );
}

# Refuse a conflicting directory before replacing any commands.
my $conflict = blog();
make_path("$conflict/bin/veecat");
write_file( "$conflict/bin/vee", 'old' );
$r = run_command( $home, [ @shell, "$root/install.sh", '--prefix', $conflict ] );
isnt( $r->{code}, 0, 'destination conflict fails' );
is( slurp("$conflict/bin/vee"), 'old', 'preflight preserves previous install' );

# Standalone download path: simulate GitHub with a curl fixture, never the network.
my $download = blog();
write_file( "$download/install.sh", slurp('install.sh') );
my $shim = blog();
write_file( "$shim/curl", <<'SH');
#!/bin/sh
set -eu
out= url=
while [ "$#" -gt 0 ]; do
  case $1 in
    -o) out=$2; shift 2;;
    https:*) url=$1; shift;;
    *) shift;;
  esac
done
name=${url##*/}
printf '%s\n' "$url" >> "$VEE_TEST_FETCH_LOG"
[ "$name" != "${VEE_TEST_FETCH_FAIL:-}" ] || exit 22
cp "$VEE_TEST_PAYLOAD/$name" "$out"
SH
chmod 0755, "$shim/curl";
my %fetch_env = ( PATH => "$shim:$ENV{PATH}", VEE_TEST_PAYLOAD => "$root/bin", VEE_TEST_FETCH_LOG => "$download/download.log" );
$r = run_command( $download, [ @shell, "$download/install.sh" ], undef, \%fetch_env );
is( $r->{code}, 0, 'standalone script downloads from GitHub' ) or diag $r->{err};
my $log = slurp("$download/download.log");
like( $log, qr{https://raw\.githubusercontent\.com/oodler577/vee/[0-9a-f]{40}/bin/vee\n}, 'downloads pinned commit' );
is( scalar( split /\n/, $log ), 6, 'all commands fetched' );
for my $command (@commands) { is( slurp("$download/.local/bin/$command"), slurp("bin/$command"), "downloaded $command intact" ); }
write_file( "$download/.local/bin/vee", 'old executable' );
$r = run_command( $download, [ @shell, "$download/install.sh" ], undef, { %fetch_env, VEE_TEST_FETCH_FAIL => 'veecat' } );
isnt( $r->{code}, 0, 'download failure reported' );
is( slurp("$download/.local/bin/vee"), 'old executable', 'failed download preserves old installation' );
opendir my $dh, "$download/.local/bin" or die $!;
my @staging = grep { /\.vee-install/ } readdir $dh;
closedir $dh;
is( scalar @staging, 0, 'download failure cleans staging' );
SKIP: {
    skip 'permission tests require an ordinary user', 2 if $> == 0;
    my $blocked = blog();
    chmod 0555, $blocked;
    $r = run_command( $home, [ @shell, "$root/install.sh", '--prefix', $blocked ] );
    isnt( $r->{code}, 0, 'unwritable prefix fails' );
    ok( !-e "$blocked/bin", 'unwritable prefix untouched' );
    chmod 0755, $blocked;
}
done_testing;
