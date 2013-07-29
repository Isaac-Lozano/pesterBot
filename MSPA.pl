#!/usr/bin/env perl
use warnings;
use strict;
use Data::Dumper;
use LWP::Simple;

sub getMSPA{
    my $site = get("http://www.mspaintadventures.com/rss/rss.xml");
    open(my $msparss, "<", \$site);
#my $notused = 1;
    my %rss = ( update => "", page => "" );

    while(<$msparss>) {
        my $line = $_;

        if($line =~ /\?s=6&amp;p=(\d{6})/){
            print "$1\n";
            $rss{page} = $1;
        }
        if($line =~ s/.*>(\w*, \d* \w* \d* \d\d:\d\d:\d\d).*/$1/) { #&& $notused
            close($msparss) or print STDERR "CANNOT CLOOOOOOOOSE";
            $rss{update} = $line;
            return %rss;
#        $notused = 0;
        }
    }
    close($msparss) or print STDERR "CANNOT CLOOOOOOOOSE";
}
1;

