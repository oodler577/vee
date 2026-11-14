use strict; use warnings; use Test::More; use File::Path qw(make_path); use lib 't/lib'; use VeeTest;
my $d=blog(); my $space="$d with spaces"; rename $d,$space or die $!; $d=$space;
write_file("$d/.veerc", "DIR='post store'\nINDEX=custom.html\nGOPHERMODE=2\nFORMAT_FUNC=with_no_formatting\n");
write_file("$d/vee-top.tpl", "<html><body><pre>Custom top\n");
write_file("$d/vee-bottom.tpl", "Custom bottom</pre></body></html>\n");
my $r=run_vee($d,['-d',$d,'-b','-U','-g','-I','-t','Original'],"body\n");
is($r->{code},0,'config and paths with spaces') or diag $r->{err};
ok(-f "$d/index.html",'CLI index overrides config'); ok(!-f "$d/custom.html",'config index unused'); ok(-f "$d/gophermap",'CLI combined mode overrides config');
opendir my $dh,"$d/post store" or die $!; my @raw=map {"$d/post store/$_"} grep {/\.raw$/} readdir $dh; closedir $dh;
is(scalar @raw,1,'custom post directory'); (my $base=$raw[0])=~s/\.raw$//;
like(slurp("$base.html"),qr/Custom top.*body.*Custom bottom/s,'templates honored');
$r=run_vee($d,['-n']); like($r->{out},qr/Original/,'listing reads config');
# Editor invocation preserves the historical EDITOR command-with-arguments convention.
write_file("$d/edit.sh", "#!/bin/sh\nsed 's/Original/Changed/' \"\$1\" > \"\$1.new\"\nmv \"\$1.new\" \"\$1\"\n");
# Use a path without spaces for EDITOR; arguments are intentionally shell words.
my $editor=blog().'/editor'; write_file($editor,slurp("$d/edit.sh")); chmod 0755,$editor;
$r=run_vee($d,['-l','-U','-g','-I'],undef,{EDITOR=>$editor}); is($r->{code},0,'edit latest');
like(slurp($raw[0]),qr/Changed/,'edited raw saved'); like(slurp("$d/index.html"),qr/Changed/,'edited HTML title refreshed'); like(slurp("$d/gophermap"),qr/Changed/,'edited Gopher title refreshed');
my $recover=run_tool($d,'vee-rebuild',[]); like($recover->{out},qr/Changed/,'recovered HTML title refreshed');
# Purging must not remove similarly prefixed unrelated files.
write_file("$base.keep",'keep');
write_file("$d/index.html", "<!doctype html>\n");
$r=run_vee($d,['-p','-U','-g','-I']); is($r->{code},0,'purge preview'); ok(-f $raw[0],'preview retains post');
$r=run_vee($d,['-P','-U','-g','-I']); is($r->{code},0,'purge'); ok(!-f $raw[0],'orphan raw removed'); ok(-f "$base.keep",'unrelated suffix preserved');
done_testing;
