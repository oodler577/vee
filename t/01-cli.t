use strict; use warnings; use Test::More; use lib 't/lib'; use VeeTest;
my $d=blog();
for my $tool (qw(vee veels veefind vee-rebuild vee-publish)) {
    my $r=run_tool($d,$tool,['-h']);
    is($r->{code},0,"$tool help succeeds");
    ok(length($r->{out}),"$tool help is present");
}
my $r=run_vee($d,['-v']); like($r->{out},qr/^2\.0/, 'version');
ok(!-d "$d/.vee",'help/version have no blog side effects');
for my $args (['-z'],['-t'],['-d',"$d/absent"],['-b','-c','oops'],['-r','-1'],['-L','no']) {
    $r=run_vee($d,$args); isnt($r->{code},0,"bad arguments: @$args");
}
for my $args (['-n'],['-o']) {
    $r=run_vee($d,$args); is($r->{code},0,'empty listing succeeds'); is($r->{out},'','empty listing is quiet');
}
done_testing;
