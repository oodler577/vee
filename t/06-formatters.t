use strict;
use warnings;
use Test::More;
use lib 't/lib';
use VeeTest;
for my $fmt (qw(none fmt fold)) {
    if ( $fmt eq 'fmt' && !grep { -x "$_/fmt" } split /:/, $ENV{PATH} ) {
        my $d = blog();
        my $r = run_vee( $d, [ '-b', '-U', '-f', 'fmt' ], "body\n" );
        isnt( $r->{code}, 0, 'explicit unavailable fmt fails' );
        next;
    }
    my $d = blog();
    my $r = run_vee( $d, [ '-b', '-U', '-g', '-f', $fmt, '-c', '20', '-t', 'formatter' ], "one two three four five six seven eight nine ten\n" );
    is( $r->{code}, 0, "$fmt works" ) or diag $r->{err};
    my @raw = raw_files($d);
    ( my $base = $raw[0] ) =~ s/\.raw$//;
    like( slurp("$base.html"), qr/one two three/, 'HTML formatted' );
    like( slurp("$base.txt"),  qr/one two three/, 'Gopher formatted' );
}
my $d = blog();
my $r = run_vee( $d, [ '-b', '-U', '-t', 'default' ], "default body\n" );
is( $r->{code}, 0, 'default formatter available' );
my @raw = raw_files($d);
( my $base = $raw[0] ) =~ s/\.raw$//;
like( slurp("$base.html"), qr/default body/, 'default did not silently discard body' );

# Test missing executable handling deterministically, regardless of installed groff.
my $shim = blog();
write_file( "$shim/groff", "#!/bin/sh\nexit 127\n" );
chmod 0755, "$shim/groff";
my $index = slurp("$d/vee.html");
$r = run_vee( $d, [ '-b', '-U', '-f', 'groff' ], "failed body\n", { PATH => "$shim:" . bin_path() . ":$ENV{PATH}" } );
isnt( $r->{code}, 0, 'formatter failure reported' );
is( slurp("$d/vee.html"), $index, 'formatter failure preserves index' );
done_testing;
