use strict;
use warnings;
use Test::More;
use POSIX ();
use lib 't/lib';
use VeeTest;
my $seed = $ENV{VEE_TEST_SEED} // 577;
srand $seed;
diag "VEE_TEST_SEED=$seed";
my @alphabet = ( "a" .. "z", ' ', "\t", "\n", '\\', '%', '<', '>', '&', "\xc3\xa9" );
my $d        = blog();

for my $i ( 1 .. 40 ) {
    my $body = join '', map { $alphabet[ int rand @alphabet ] } 1 .. ( 1 + int rand 2048 );
    my $r    = run_vee( $d, [ '-b', '-U', '-f', 'none', '-t', "seed $seed case $i" ], $body );
    is( $r->{code}, 0, "random post $i" );
    my @raw = raw_files($d);
    my ($file) = grep { slurp($_) =~ /\Qseed $seed case $i\E\n/ } @raw;
    ok( defined $file, 'post found' );
    if ( defined $file ) { my $r = run_tool( $d, 'veecat', ['-b'], "$file\n" ); is( $r->{out}, $body, 'random bytes preserved' ); }
}
my %before = map { $_ => slurp($_) } raw_files($d);
my $r      = run_vee( $d, [ '-R', '-U', '-f', 'none' ] );
is( $r->{code}, 0,           'bulk rebuild' );
is( slurp($_),  $before{$_}, 'bulk rebuild preserves source' ) for sort keys %before;

# Simultaneous writers must succeed intact or fail explicitly with a lock error.
$d = blog();
my @workers;
for my $i ( 1 .. 8 ) {
    my $pid = fork();
    die $! unless defined $pid;
    if ( !$pid ) {
        my $r = run_vee( $d, [ '-b', '-U', '-f', 'none', '-t', "worker $i" ], "worker body $i\n" );
        write_file( "$d/result-$i", "$r->{code}\n$r->{err}" );
        POSIX::_exit(0);
    }
    push @workers, $pid;
}
for (@workers) { waitpid( $_, 0 ); is( $?, 0, 'worker completed' ); }
my $successful = 0;
for my $i ( 1 .. 8 ) {
    my $result = slurp("$d/result-$i");
    if   ( $result =~ /^0\n/ ) { $successful++; }
    else                       { like( $result, qr/locked/, 'contention reported' ); }
}
ok( $successful >= 1, 'at least one writer succeeds' );
is( scalar( raw_files($d) ), $successful, 'all successful writes retained' );
my $index = slurp("$d/vee.html");
my @links = $index =~ /<a href=/g;
is( scalar @links, $successful, 'index matches successful writes' );
ok( !-d "$d/.vee/.vee.lock", 'concurrent run leaves no lock' );

# Interrupt a process while inside its hook; the trap must release its lock.
$d = blog();
write_file( "$d/vee-pre", "#!/bin/sh\nkill -TERM \"\$PPID\"\nsleep 1\n" );
chmod 0755, "$d/vee-pre";
$r = run_vee( $d, [ '-b', '-U', '-f', 'none' ], "interrupted\n" );
isnt( $r->{code}, 0, 'interruption reported' );
ok( !-d "$d/.vee/.vee.lock", 'interruption unlocks' );
is( scalar( raw_files($d) ), 0, 'interrupted pre-hook publishes no raw post' );
done_testing;
