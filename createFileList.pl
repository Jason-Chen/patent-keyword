#!/usr/bin/perl
use File::Find;
use utf8;

binmode(STDIN, ':encoding(utf8)');
binmode(STDOUT, ':encoding(utf8)');
binmode(STDERR, ':encoding(utf8)');

my $path = './data/UTIL08438';
my @files;

finddepth(sub {
    return if($_ eq '.' || $_ eq '..');
    push @files,  grep(/\.xml$/i, $File::Find::name);
}, $path);

open(FHD, "+> ./config/file_list.txt") || die "$!\n";
print FHD $_."\n" for (@files);
close(FHD);