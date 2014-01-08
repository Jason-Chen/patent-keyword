#!/usr/bin/perl
use utf8;
use XML::LibXML;
use Text::Ngramize;
use List::Util;
use String::Util ':all';
use Data::Dump;
use File::Basename;
use File::Path qw/make_path/;

binmode(STDIN, ':encoding(utf8)');
binmode(STDOUT, ':encoding(utf8)');
binmode(STDERR, ':encoding(utf8)');

my @BLACK_ARRAY;
my %BLACK_HASH;
my @FILES;

my $OUTPUT_FOLDER = './output';
my $OUTPUT_CLAIMS = 'claims.txt';
my $OUTPUT_DESCRIPTION = 'description.txt';
my $OUTPUT_KEYWORD = 'keyword.txt';
my $OUTPUT_GRAMS = 'grams-keyword.txt';

# Read file list to parse
open(FHD, "./config/file_list.txt") || die "$!\n";
while ( my $line = <FHD> ) {
    push @FILES, fullchomp($line);
}
close(FHD);

# Read black word list to filter out
open(FHD, "./config/black_list.txt") || die "$!\n";
while ( my $line = <FHD> ) {
    @BLACK_ARRAY = split(',', $line);
    %BLACK_HASH = @BLACK_ARRAY;
    $BLACK_HASH{$_}++ for (@BLACK_ARRAY);
}
close(FHD);

for my $file (@FILES) {
    # Parse XML file
    my $dom = XML::LibXML->new->parse_file($file);

    # Claims
    for my $node ($dom->findnodes('/us-patent-grant/claims/claim/claim-text/text()')) {
        $str = $node->toString;
        $claims = $claims.$str;

        my $one_grams_ref = Text::Ngramize->new (typeOfNgrams => 'words', normalizeText => 1, sizeOfNgrams => 1)
            ->getListOfNgrams (text => \$str);
        my $two_grams_ref = Text::Ngramize->new (typeOfNgrams => 'words', normalizeText => 1, sizeOfNgrams => 2)
            ->getListOfNgrams (text => \$str);

        $h_one{$_}++ for (@{ $one_grams_ref });
        $h_two{$_}++ for (@{ $two_grams_ref });
    }
    
    # Description
    for my $node ($dom->findnodes('/us-patent-grant/description/p/text()')) {
        $str = $node->toString;
        $description = $description.$str;

        my $one_grams_ref = Text::Ngramize->new (typeOfNgrams => 'words', normalizeText => 1, sizeOfNgrams => 1)
            ->getListOfNgrams (text => \$str);
        my $two_grams_ref = Text::Ngramize->new (typeOfNgrams => 'words', normalizeText => 1, sizeOfNgrams => 2)
            ->getListOfNgrams (text => \$str);

        $h_one{$_}++ for (@{ $one_grams_ref });
        $h_two{$_}++ for (@{ $two_grams_ref });
    }

    ++$i && print "##### $i #####\n";

    # Save claims
    print "Output claims...\n";
    output_str($claims, dirname($file), $OUTPUT_FOLDER, $OUTPUT_CLAIMS);
    
    print "Output description...\n";
    output_str($description, dirname($file), $OUTPUT_FOLDER, $OUTPUT_DESCRIPTION);

    # Save keywords
    print "Output keyword...\n";
    output_hash(\%h_one, dirname($file), $OUTPUT_FOLDER, $OUTPUT_KEYWORD);

    print "Output 2-grans keyword...\n";
    output_hash(\%h_two, dirname($file), $OUTPUT_FOLDER, $OUTPUT_GRAMS);

    print "\n";
}

sub match {
    my @array = split(' ', $_[0]);
    my %BLACK_HASH = %{$_[1]};

    ($BLACK_HASH{$_}) && return 1 for (@array); 0
}

sub output_hash {
    my %h = %{$_[0]};
    my $output_path = $_[1];
    my $FILE_FOLDER = $_[2];
    my $FILE_NAME = $_[3];
    my $count = 0;

    $output_path =~ s/^.\/\w+/$FILE_FOLDER/;
    $output_path = $output_path.'/'.$FILE_NAME;

    make_path(dirname($output_path));

    open(FHD, "+> $output_path") || die "$!\n";
    print "$output_path\n";
    print FHD "<count>\t\t<keyword>\n";
    for my $key ( sort { $h{$b} <=> $h{$a} } keys %h) {
        # Filter & Print
        print (FHD "$h{$key}\t\t$key\n") && $count++ unless ($h{$key}==1 || match($key, \%BLACK_HASH));
    }

    print FHD "There are $count keyword(s).\n";
    close(FHD);
}

sub output_str {
    my $str = $_[0];
    my $output_path = $_[1];
    my $FILE_FOLDER = $_[2];
    my $FILE_NAME = $_[3];

    $output_path =~ s/^.\/\w+/$FILE_FOLDER/;
    $output_path = $output_path.'/'.$FILE_NAME;

    make_path(dirname($output_path));

    open(FHD, "+> $output_path") || die "$!\n";
    print "$output_path\n";
    print FHD $str;
    close(FHD);
}