use strict;
use warnings;
use Test::More;
use lib 't/lib';
use VeeTest;
my @corpus = ( "", "\n", "\n\n", "-n\n", "\\c", "\\n\\t\\000", "  leading\tand trailing  \n", "<>&\"'\n", "%s%n\\\n", "\xc3\xa9\xe2\x98\x83\n", ( 'x' x 8192 ), "first\n\nlast" );
for my $i ( 0 .. $#corpus ) {
    my $d = blog();
    my $r = run_vee( $d, [ '-b', '-U', '-f', 'none', '-t', "corpus $i" ], $corpus[$i] );
    is( $r->{code}, 0, "corpus $i publishes" );
    my @raw  = raw_files($d);
    my $body = run_tool( $d, 'veecat', ['-b'], "$raw[0]\n" );
    is( $body->{out}, $corpus[$i], "corpus $i exact bytes" );
}
done_testing;
