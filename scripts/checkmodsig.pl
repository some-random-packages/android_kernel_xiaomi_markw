#!/usr/bin/env perl

use strict;

sub through {
    my ($cmd, $data, $cb) = @_;
    use IPC::Open2;
    my $pid = open2 my $from, my $to, ref $cmd ? @$cmd : $cmd;
    print $to $data; close $to; my $out;
    if($cb){ while(<$from>){ last if $out = $cb->($_) } }
    else { local $/; $out = <$from>; }
    waitpid ($pid, 0);
    die "status $?" if $? != 0;
    $out;
}
sub gethash {
    my ($d) = @_; my ($alg, $hash);
    through [qw(openssl asn1parse -inform der)], $d, sub {
        if(/(\d+):d=\d+ +hl= *(\d+) +l= *(\d+) +prim: +OCTET STRING/){
            $hash = substr $d, $1 + $2, $3
        }elsif(/prim: +OBJECT +:(sha\w+)/){
            $alg = $1;
        }
        undef
    };
    $alg, $hash
}

use File::Temp;
my $tf = new File::Temp;
my $pub_key;
my @type = qw(PGP X509 PKCS7);
my $r = 0;
if((my $cert = shift) =~ /(\.x509)$|\.pem$/i){
    $pub_key = $tf->filename;
    system qw(openssl x509 -pubkey -noout),
        '-inform', $1 ? 'der' : 'pem',
        '-in', $cert, '-out', $pub_key;
    die "status $?" if $? != 0;
}
die "no certificate/key file" unless $pub_key;
for my $kof (@ARGV){
    open my $ko, '<', $kof or die "open $kof: $!\n";
    seek $ko, -4096, 2 or die "seek: $!";
    read $ko, my $d, 4096 or die "read: $!";
    my ($algo, $hash, $type, $signer_len, $key_id_len, $sig_len, $magic) =
        unpack 'C5x3Na*', substr $d, -40;
    die "no signature in $kof"
        unless $magic eq "~Module signature appended~\n";
    die "this script only knows about PKCS#7 signatures"
        unless $type[$type] eq 'PKCS7';

    my $hash = gethash substr $d, - 40 - $sig_len, $sig_len;
    die "hash not found" unless $hash;

    my ($alg, $vhash) = gethash
        through [qw(openssl rsautl -verify -pubin -inkey), $pub_key],
            $hash;

    seek $ko, 0, 0 or die "seek: $!";
    read $ko, my $d, (-s $ko) - $sig_len - 40 or die "read: $!";
    use Digest::SHA;
    my $fhash = new Digest::SHA($alg)->add($d)->digest;

    if($fhash eq $vhash){
        print "OK $kof\n";
    }else{
        print "**FAIL** $kof\n";
        $r = 1;
        warn 'orig=', unpack('H*', $vhash), "\n";
        warn 'file=', unpack('H*', $fhash), "\n";
    }
}
exit $r;
