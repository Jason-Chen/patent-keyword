#!/usr/bin/perl
use utf8;
use XML::LibXML;
use Text::Ngramize;
use List::Util;
use String::Util;
use Data::Dump;

binmode(STDIN, ':encoding(utf8)');
binmode(STDOUT, ':encoding(utf8)');
binmode(STDERR, ':encoding(utf8)');

@BLACK_LIST = ( 'is', 'are', 'do', 'did', 'does', 'can', 'cause',
                'could', 'may', 'might', 'a', 'the', 'at', 'of', 'and',
                'to', 'for', 'or', 'with' );
# Parse XML file
my $dom = XML::LibXML->new->parse_file( 'US08442857-20130514.XML' );

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
    
    $h{$_}++ for (@{ $one_grams_ref });
    $h{$_}++ for (@{ $two_grams_ref });
}

# Print the hash out
for my $key ( sort { $h{$b} <=> $h{$a} } keys %h) {
    # Filter & Print
    print "\t$h{$key} \t\t $key\n" unless match($key, \@BLACK_LIST);
}

sub match {
    my @array = split(' ', $_[0]);
    my @checkList = @{$_[1]};

    ($_ ~~ @checkList) && return 1 for (@array); 0
}