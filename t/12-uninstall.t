use strict;
use warnings;
use Test::More;
use Cwd              qw(abs_path);
use File::Path       qw(make_path);
use Text::ParseWords qw(shellwords);
use lib 't/lib';
use VeeTest;
my $root                 = abs_path('.');
my @shell                = shellwords( $ENV{VEE_TEST_SHELL} || '/bin/sh' );
my @commands             = qw(vee veels veecat veefind vee-rebuild vee-publish);
my ($install_commands)   = slurp('install.sh')   =~ /^COMMANDS='([^']+)'/m;
my ($uninstall_commands) = slurp('uninstall.sh') =~ /^COMMANDS='([^']+)'/m;
is( $uninstall_commands, $install_commands, 'installer and uninstaller cover the same command set' );
my $home = blog();
my $r    = run_command( $home, [ @shell, "$root/install.sh" ] );
is( $r->{code}, 0, 'install before uninstall' );
write_file( "$home/.veerc",   "# keep config\n" );
write_file( "$home/.profile", "# keep PATH settings\n" );
make_path("$home/sites/blog/.vee");
write_file( "$home/sites/blog/.vee/post.raw", "keep post\n" );
write_file( "$home/.local/bin/unrelated",     'keep executable' );
$r = run_command( $home, [ @shell, "$root/uninstall.sh", '--dry-run' ] );
is( $r->{code}, 0, 'dry run succeeds' );

for my $command (@commands) {
    ok( -f "$home/.local/bin/$command", "dry run retains $command" );
    like( $r->{out}, qr/\Q$home\/.local\/bin\/$command\E\n/, "dry run lists $command" );
}
$r = run_command( $home, [ @shell, "$root/uninstall.sh" ] );
is( $r->{code}, 0, 'default uninstall succeeds' ) or diag $r->{err};
ok( !-e "$home/.local/bin/$_", "removed $_" ) for @commands;
is( slurp("$home/.local/bin/unrelated"),     'keep executable',        'unrelated command retained' );
is( slurp("$home/.veerc"),                   "# keep config\n",        'config retained' );
is( slurp("$home/.profile"),                 "# keep PATH settings\n", 'startup file retained' );
is( slurp("$home/sites/blog/.vee/post.raw"), "keep post\n",            'blog retained' );
ok( -d "$home/.local/bin", 'shared bin directory retained' );
$r = run_command( $home, [ @shell, "$root/uninstall.sh" ] );
is( $r->{code}, 0, 'repeated uninstall succeeds' );
like( $r->{out}, qr/No vee commands/, 'empty install explained' );

for my $prefix ( "$home/custom prefix's location", 'relative', '-leading-prefix' ) {
    $r = run_command( $home, [ @shell, "$root/install.sh", '--prefix', $prefix ] );
    is( $r->{code}, 0, 'custom install' );
    $r = run_command( $home, [ @shell, "$root/uninstall.sh", '--prefix', $prefix ] );
    is( $r->{code}, 0, 'matching custom uninstall' );
    my $absolute = $prefix =~ m{^/} ? $prefix : "$home/$prefix";
    ok( !-e "$absolute/bin/vee", 'custom command removed' );
}
$r = run_command( $home, [ @shell, "$root/uninstall.sh", '--prefix', "$home/nonexistent" ] );
is( $r->{code}, 0, 'absent prefix succeeds' );
ok( !-e "$home/nonexistent", 'absent prefix not created' );
for my $args ( ['--unknown'], ['--prefix'], [ '--prefix', '' ] ) {
    $r = run_command( $home, [ @shell, "$root/uninstall.sh", @$args ] );
    isnt( $r->{code}, 0, 'invalid arguments rejected' );
}
$r = run_command( $home, [ @shell, "$root/uninstall.sh", '--help' ] );
is( $r->{code}, 0, 'help succeeds' );
like( $r->{out}, qr/--dry-run/, 'help explains dry run' );
for my $kind ( 'directory', 'symlink', 'dangling' ) {
    my $d = blog();
    make_path("$d/bin");
    write_file( "$d/bin/vee", 'original command' );
    if   ( $kind eq 'directory' ) { make_path("$d/bin/veecat"); }
    else                          { symlink( $kind eq 'dangling' ? "$d/missing" : "$d/bin/vee", "$d/bin/veecat" ) or die $!; }
    $r = run_command( $home, [ @shell, "$root/uninstall.sh", '--prefix', $d ] );
    isnt( $r->{code}, 0, "$kind refused" );
    is( slurp("$d/bin/vee"), 'original command', 'preflight prevents earlier deletion' );
}

# A downloaded copy has no dependency on the source checkout.
my $standalone = blog();
write_file( "$standalone/uninstall.sh", slurp('uninstall.sh') );
make_path("$standalone/.local/bin");
write_file( "$standalone/.local/bin/vee", 'installed' );
$r = run_command( $standalone, [ @shell, "$standalone/uninstall.sh" ] );
is( $r->{code}, 0, 'standalone uninstall succeeds' );
ok( !-e "$standalone/.local/bin/vee", 'standalone removes command' );
SKIP: {
    skip 'permission tests require an ordinary user', 2 if $> == 0;
    my $d = blog();
    make_path("$d/bin");
    write_file( "$d/bin/vee", 'keep' );
    chmod 0555, "$d/bin";
    $r = run_command( $home, [ @shell, "$root/uninstall.sh", '--prefix', $d ] );
    isnt( $r->{code}, 0, 'unwritable directory fails' );
    is( slurp("$d/bin/vee"), 'keep', 'permission failure preserves command' );
    chmod 0755, "$d/bin";
}
done_testing;
