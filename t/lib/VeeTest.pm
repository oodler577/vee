package VeeTest;
use strict;
use warnings;
use Exporter 'import';
use Cwd qw(abs_path);
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use Text::ParseWords qw(shellwords);
use POSIX qw(setsid WNOHANG);
use Time::HiRes qw(time sleep);
our @EXPORT = qw(blog run_vee run_tool write_file slurp raw_files bin_path);
my $root = abs_path('.');
my $sandbox = tempdir('vee-tests-XXXXXXXX', TMPDIR=>1, CLEANUP=>1);
my $bin = "$sandbox/bin";
make_path($bin);
sub quote_sh { my $s=shift; $s =~ s/'/'"'"'/g; return "'$s'"; }
for my $name (qw(vee veels veecat veefind vee-rebuild vee-publish)) {
    my $source="$root/bin/$name";
    my @shell = shellwords($ENV{VEE_TEST_SHELL} || '');
    if (@shell) {
        write_file("$bin/$name", "#!/bin/sh\nexec ".join(' ',map {quote_sh($_)} (@shell,$source)).' "$@"'."\n");
    } else {
        symlink($source,"$bin/$name") or die "symlink: $!";
    }
    chmod 0755,"$bin/$name" or die "chmod: $!";
}
sub bin_path { $bin }
sub blog { tempdir('blog-XXXXXXXX', DIR=>$sandbox) }
sub write_file {
    my ($path,$bytes)=@_;
    open my $fh,'>:raw',$path or die "$path: $!";
    print {$fh} $bytes or die "write $path: $!";
    close $fh or die "close $path: $!";
}
sub slurp {
    my ($path)=@_;
    open my $fh,'<:raw',$path or die "$path: $!";
    local $/;
    return <$fh> // '';
}
sub raw_files { my ($dir)=@_; opendir my $dh,"$dir/.vee" or return wantarray ? () : 0; my @files=sort map {"$dir/.vee/$_"} grep {/\.raw\z/ && -f "$dir/.vee/$_"} readdir $dh; closedir $dh; return wantarray ? @files : scalar @files; }
sub run_vee { my ($dir,$args,$input,$env)=@_; run_tool($dir,'vee',$args,$input,$env) }
sub run_tool {
    my ($dir,$tool,$args,$input,$env)=@_;
    my $io=tempdir('io-XXXXXXXX', DIR=>$sandbox);
    write_file("$io/in",$input // '');
    my $pid=fork(); die "fork: $!" unless defined $pid;
    if (!$pid) {
        setsid() or die "setsid: $!";
        chdir $dir or die "chdir: $!";
        %ENV=(%ENV, PATH=>"$bin:$ENV{PATH}", HOME=>$dir, LC_ALL=>'C', TZ=>'UTC', %{ $env || {} });
        delete @ENV{qw(ENV BASH_ENV CDPATH)};
        umask 0022;
        open STDIN,'<',"$io/in" or die $!;
        open STDOUT,'>',"$io/out" or die $!;
        open STDERR,'>',"$io/err" or die $!;
        exec {"$bin/$tool"} "$bin/$tool", @$args;
        die "exec: $!";
    }
    my $deadline=time()+15;
    my $timed_out=0;
    while (waitpid($pid,WNOHANG)==0) {
        if(time()>$deadline) { kill 'KILL',-$pid; waitpid($pid,0); $timed_out=1; last; }
        sleep 0.01;
    }
    my $status=$?;
    return {code=>$timed_out ? 124 : ($status & 127 ? 128+($status & 127) : $status>>8),
        out=>slurp("$io/out"), err=>slurp("$io/err"), timeout=>$timed_out};
}
1;
