use strict; use warnings; use Test::More; use lib 't/lib'; use VeeTest;
for my $format (qw(par72 pandoc markdown)) {
    my $d=blog(); write_file("$d/vee-custom.sh",slurp('custom-formatters/vee-custom-3rd-party.sh'));
    my $shim=blog(); my $command=$format eq 'par72' ? 'par' : $format;
    write_file("$shim/$command","#!/bin/sh\nprintf 'CUSTOM OUTPUT\\n'\ncat\n"); chmod 0755,"$shim/$command";
    my $r=run_vee($d,['-b','-U','-g','-f',$format,'-t','Custom'],"body\n",{PATH=>"$shim:".bin_path().":$ENV{PATH}"});
    is($r->{code},0,"$format custom dispatcher") or diag $r->{err};
    my @raw=raw_files($d); (my $base=$raw[0])=~s/\.raw$//;
    like(slurp("$base.html"),qr/CUSTOM OUTPUT/,'external HTML formatter called');
    unlike(slurp("$base.txt"),qr/CUSTOM OUTPUT/,'Gopher stays literal');
}
my $d=blog(); write_file("$d/vee-custom.sh",slurp('custom-formatters/vee-custom-utf8.sh'));
my $r=run_vee($d,['-b','-U','-g','-f','null','-t','Literal'],"body\n"); is($r->{code},0,'UTF8 example literal dispatcher');
# Both hooks run once per enabled output, in order, with the documented argument.
$d=blog();
for my $hook (qw(pre post)) {
    write_file("$d/vee-$hook","#!/bin/sh\nprintf '$hook %s\\n' \"\$1\" >> hook.log\n"); chmod 0755,"$d/vee-$hook";
}
$r=run_vee($d,['-b','-U','-g','-f','none'],"body\n"); is($r->{code},0,'both hooks succeed');
is(slurp("$d/hook.log"),"pre html\npost html\npre gopher\npost gopher\n",'hook order and arguments');
# Gopher-only purge uses its map rather than requiring an HTML index.
$d=blog(); $r=run_vee($d,['-b','-U','-G','-f','none'],"body\n"); is($r->{code},0,'Gopher baseline');
write_file("$d/gophermap",'');
$r=run_vee($d,['-P','-U','-G']); is($r->{code},0,'Gopher purge succeeds'); is(scalar(raw_files($d)),0,'Gopher orphan removed');
done_testing;
