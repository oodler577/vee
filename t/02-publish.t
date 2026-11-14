use strict; use warnings; use Test::More; use lib 't/lib'; use VeeTest;
for my $mode ('html','both','gopher') {
    subtest $mode=>sub {
        my $d=blog(); my @mode=$mode eq 'both' ? ('-g') : $mode eq 'gopher' ? ('-G') : ();
        my $title='A <title> & "quote" %s \\';
        my $body="  leading spaces\n\nback\\slash\n-n\nUTF-8: \xc3\xa9\nlast line without newline";
        my $r=run_vee($d,['-b','-U','-f','none','-t',$title,@mode],$body);
        is($r->{code},0,'publish succeeds') or diag($r->{err});
        my @raw=raw_files($d); is(scalar @raw,1,'one raw post');
        my $raw=slurp($raw[0]); like($raw,qr/\Q$body\E\z/,'input bytes preserved');
        my $extract=run_tool($d,'veecat',['-b'],"$raw[0]\n");
        is($extract->{out},$body,'body extraction is byte exact');
        $extract=run_tool($d,'veecat',['-t'],"$raw[0]\n"); is($extract->{out},"$title\n",'title preserved');
        (my $base=$raw[0]) =~ s/\.raw$//;
        is(-f "$d/vee.html" ? 1:0, $mode eq 'gopher' ? 0:1,'HTML mode respected');
        is(-f "$d/gophermap" ? 1:0, $mode eq 'html' ? 0:1,'Gopher mode respected');
        if($mode ne 'gopher') { like(slurp("$base.html"),qr/\Q$body\E/,'HTML contains body'); like(slurp("$d/vee.html"),qr/A &lt;title&gt; &amp;/,'index escapes title'); }
        if($mode ne 'html') { is(slurp("$base.txt"),$raw,'Gopher text contains complete raw post'); like(slurp("$d/gophermap"),qr/\Q$title\E\tphlogsrc\//,'map title literal'); ok(-l "$d/phlogsrc",'Gopher source link'); }
        ok(!-e "$d/.vee/.vee.lock",'lock cleaned');
        $r=run_vee($d,['-n']); like($r->{out},qr/\Q$title\E/,'listing title');
        $r=run_vee($d,['-b','-U','-f','none','-t','Second',@mode],"Second body\n");
        is($r->{code},0,'second publish'); is(scalar(raw_files($d)),2,'both raw posts retained');
        my %before=map {$_=>slurp($_)} raw_files($d);
        $r=run_vee($d,['-R','-U','-f','none',@mode]); is($r->{code},0,'rebuild succeeds');
        is(slurp($_),$before{$_},'rebuild preserves raw bytes') for sort keys %before;
        if($mode ne 'html') { my $map=slurp("$d/gophermap"); $r=run_vee($d,['-R','-U','-f','none',@mode]); is(slurp("$d/gophermap"),$map,'Gopher rebuild stable'); }
    };
}
done_testing;
