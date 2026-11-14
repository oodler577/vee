use strict;
use warnings;
use Test::More;
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
done_testing;
