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

my @BLACK_LIST;
my @FILES;
my $OUTPUT_FOLDER = './output';
my $OUTPUT_CLAIMS = 'claims';
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
    @BLACK_LIST = split(',', $line);
}
close(FHD);

for my $file (@FILES) {
    $i++;
    
    # Parse XML file
    my $dom = XML::LibXML->new->parse_file($file);

    # Add elements(each word) to hash
    for my $node ($dom->findnodes('/us-patent-grant/claims/claim/claim-text/text()')) {
        $str = $node->toString;
        # $str =~ s/[_:;?,]/ /g;
        # $str = lc $str;
        # @f = split(' ', $str);
        
        my $one_grams_ref = Text::Ngramize->new (typeOfNgrams => 'words', normalizeText => 1, sizeOfNgrams => 1)
            ->getListOfNgrams (text => \$str);
        my $two_grams_ref = Text::Ngramize->new (typeOfNgrams => 'words', normalizeText => 1, sizeOfNgrams => 2)
            ->getListOfNgrams (text => \$str);
        
        $h_one{$_}++ for (@{ $one_grams_ref });
        $h_two{$_}++ for (@{ $two_grams_ref });
    }

    #Print the hash out
    print "##### $i #####\n";
    
    print "Output keyword...\n";
    output(\%h_one, $file, $OUTPUT_FOLDER, $OUTPUT_KEYWORD);
    
    print "Output 2-grans keyword...\n";
    output(\%h_two, $file, $OUTPUT_FOLDER, $OUTPUT_GRAMS);
    
    print "\n";
}

sub match {
    my @array = split(' ', $_[0]);
    my @checkList = @{$_[1]};

    ($_ ~~ @checkList) && return 1 for (@array); 0
}

sub output {
    my %h = %{$_[0]};
    my $output_path = $_[1];
    my $FILE_FOLDER = $_[2];
    my $FILE_NAME = $_[3];

    $output_path =~ s/^.\/\w+/$FILE_FOLDER/;
    $output_path = dirname($output_path).'/'.$FILE_NAME;
    
    make_path(dirname($output_path));
    
    open(FHD, "+> $output_path") || die "$!\n";
    print "$output_path\n";
    for my $key ( sort { $h{$b} <=> $h{$a} } keys %h) {
        # Filter & Print
        print FHD "\t$h{$key} \t\t $key\n" unless match($key, \@BLACK_LIST);
    }
    close(FHD);
}