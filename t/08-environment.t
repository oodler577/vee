use strict; use warnings; use Test::More; use lib 't/lib'; use VeeTest;
for my $tz ('UTC','America/Chicago','Pacific/Auckland') {
    my $d=blog(); my $r=run_vee($d,['-b','-g','-f','none','-t','Time zones'],"body\n",{TZ=>$tz});
    is($r->{code},0,"publish in $tz");
    my $map=slurp("$d/gophermap");
    $r=run_vee($d,['-R','-U','-g','-f','none'],undef,{TZ=>'UTC'});
    is($r->{code},0,'rebuild under another time zone'); is(slurp("$d/gophermap"),$map,'stored dates survive time zone change');
}
SKIP: {
    skip 'permission tests require an ordinary user',3 if $> == 0;
    my $d=blog(); chmod 0555,$d;
    my $r=run_vee($d,['-b','-U','-f','none'],"body\n");
    isnt($r->{code},0,'unwritable blog fails'); ok(!-e "$d/vee.html",'no partial index'); ok(!-e "$d/.vee",'no partial post store');
    chmod 0755,$d;
}
my $d=blog(); write_file("$d/.veerc","_CUSTOM_UMASK=0077\n");
my $r=run_vee($d,['-b','-f','none'],"private\n"); is($r->{code},0,'private umask supported');
my @raw=raw_files($d); is((stat($raw[0]))[2] & 0777,0600,'private post permission preserved');
$r=run_vee($d,['-b','-U','-f','none'],"public\n"); is($r->{code},0,'explicit public umask overrides config');
@raw=raw_files($d); ok(grep({((stat($_))[2] & 0777)==0644} @raw),'public raw created');
done_testing;
