use strict;
use warnings;
use Test::More;
use File::Path qw(make_path);
use lib 't/lib';
use VeeTest;
my $d = blog();
make_path("$d/.vee/nested");
for my $epoch ( 9, 10, 100 ) { write_file( "$d/.vee/$epoch.1.raw", "Fri May 29 09:02:12 UTC 2020\n\nTitle $epoch\n\n--\n\nBody $epoch\n" ); }
write_file( "$d/.vee/nested/200.1.raw", "date\n\nnested\n\n--\n\nbody\n" );

for my $tool (qw(veels veefind)) {
    my $r = run_tool( $d, $tool, [] );
    is( $r->{code}, 0,                                                     "$tool works" );
    is( $r->{out},  "./.vee/100.1.raw\n./.vee/10.1.raw\n./.vee/9.1.raw\n", "$tool numeric newest first" );
    $r = run_tool( $d, $tool, [ '-r', '-x' ] );
    is( $r->{out}, "./.vee/9.1\n./.vee/10.1\n./.vee/100.1\n", "$tool reverse and strip" );
}
my $r = run_tool( $d, 'veefind', [ '-M', '2' ] );
like( $r->{out}, qr/nested\/200/, 'recursive find' );
$r = run_tool( $d, 'vee-rebuild', [] );
is( $r->{code}, 0, 'recover index' );
like( $r->{out}, qr/100\.1\.html">Title 100/, 'recovery links' );
my $raw = "$d/.vee/10.1.raw";
$r = run_tool( $d, 'veecat', ['-a'], "$raw\n" );
is( $r->{out}, slurp($raw), 'all bytes' );
$r = run_tool( $d, 'veecat', ['-dtb'], "$raw\n" );
is( $r->{out}, slurp($raw), 'combined fields mean all' );
$r = run_tool( $d, 'veecat', ['-d'], "$raw\n" );
is( $r->{out}, "Fri May 29 09:02:12 UTC 2020\n", 'date extraction' );
done_testing;
