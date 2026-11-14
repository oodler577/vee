use strict;
use warnings;
use Test::More;
use File::Path qw(make_path);
use lib 't/lib';
use VeeTest;
my $d    = blog();
my $shim = blog();
write_file( "$d/.veerc",   "DIR='$d'\n" );
write_file( "$shim/rsync", "#!/bin/sh\nprintf '%s\\n' \"\$@\" > rsync.args\n" );
chmod 0755, "$shim/rsync";
my $r = run_tool( $d, 'vee-publish', [ '-s', 'example.invalid:/blog' ], undef, { PATH => "$shim:" . bin_path() . ":$ENV{PATH}" } );
is( $r->{code}, 0, 'publishing helper invokes mocked rsync' );
my $args = slurp("$d/rsync.args");
like( $args, qr/^-rlptuvPzh\n/,                    'recursive transfer and symlink preservation selected' );
like( $args, qr{\Q$d/\E\nexample.invalid:/blog\n}, 'entire publication directory supplied' );
like( $args, qr/--exclude=\.vee-recovery\//,       'private recovery drafts excluded' );
like( $args, qr/--exclude=\.veerc/,                'config excluded' );
like( $args, qr/--exclude=\.vee.lock\//,           'working lock excluded' );
write_file( "$shim/rsync", "#!/bin/sh\nexit 23\n" );
$r = run_tool( $d, 'vee-publish', [ '-s', 'example.invalid:/blog' ], undef, { PATH => "$shim:" . bin_path() . ":$ENV{PATH}" } );
is( $r->{code}, 23, 'rsync failure propagated' );

for my $config ( "RAWEXT=html\n", "RAWEXT=txt\nGOPHERMODE=2\n", "FORMAT=txt\nGOPHERMODE=1\n" ) {
    my $d = blog();
    write_file( "$d/.veerc", $config );
    $r = run_vee( $d, [ '-b', '-U', '-f', 'none' ], "body\n" );
    isnt( $r->{code}, 0, 'colliding extensions rejected' );
    ok( !-d "$d/.vee", 'collision rejected before writing posts' );
}
SKIP: {
    skip 'optional rsync is not installed', 7 unless grep { -x "$_/rsync" } split /:/, $ENV{PATH};
    make_path( "$d/.vee/.vee-recovery", "$d/.vee/.vee.lock", "$d/.git" );
    write_file( "$d/.vee/post.html",             'published page' );
    write_file( "$d/.vee/.vee-recovery/private", 'private draft' );
    write_file( "$d/.vee/.vee.lock/work",        'in progress' );
    write_file( "$d/.git/config",                'private metadata' );
    symlink( '.vee', "$d/phlogsrc" ) or die $!;
    my $destination = blog();
    $r = run_tool( $d, 'vee-publish', [ '-s', "$destination/" ] );
    is( $r->{code},                           0,                'real local rsync deployment succeeds' ) or diag $r->{err};
    is( slurp("$destination/.vee/post.html"), 'published page', 'hidden nested post deployed' );
    ok( -l "$destination/phlogsrc",            'Gopher symlink preserved' );
    ok( !-e "$destination/.vee/.vee-recovery", 'private recovery excluded' );
    ok( !-e "$destination/.vee/.vee.lock",     'active work excluded' );
    ok( !-e "$destination/.veerc",             'configuration excluded' );
    ok( !-e "$destination/.git",               'Git metadata excluded' );
}
done_testing;
