#!/usr/bin/env perl
use Bot::BasicBot;
use Data::Dumper;
use Tie::File;
use strict;
use warnings;
package Pester;


#Bot global variabes
$Pester::currenttime = "F10:00";
$Pester::color = "33,100,33";
@Pester::Dave;
$Pester::lastUpdate = "1";
%Pester::rss = (
    update => "1",
    page => 1901
);
$Pester::firstUpdate = 1;

#Server Arguements
my $server = "irc.mindfang.org";
my @channels = [ "#multipath_forum_adventure", "#bots" ];
my $nick = "pesterBot";
my @alt_nicks = [];
my $username = "pesterBot";
my $name = "pesterBot";

require "../MSPA.pl";

my $bot = Bot::BasicBot->new( 
        server    => $server,
        channels  => @channels,
        nick      => $nick,
        alt_nicks => @alt_nicks,
        username  => $username,
        name      => $name,);

tie @Pester::Dave, 'Tie::File', 'redBubbleText' or die("Could not open DaveQuote file." . $!);

$bot->run();

sub Bot::BasicBot::tick{
    my ($botob) = @_;

    if($Pester::firstUpdate == 1){
        %Pester::rss = getMSPA();
        $Pester::firstUpdate = 0;
    }

    $Pester::lastUpdate = $Pester::rss{update};
    %Pester::rss = getMSPA();
    checkMSPA($botob, @channels);
    return 60;
}

sub Bot::BasicBot::chanjoin{
    my ($botob, $args) = @_;

    $botob->say((channel => $$args{channel}, body => "PESTERCHUM:TIME>$Pester::currenttime"));

    if($$args{who} ne $nick){
        Psay($botob, (channel => $$args{channel}, body => "Hello, $$args{who}."));
    }
}

sub Bot::BasicBot::said{
    my ($botob, $args) = @_;

    $$args{body} =~ s/<[Cc]=\d+,\d+,\d+>// =~ s_</c>__;

    if($$args{body} =~ /\w{2,5}: change colou?r (\d+,\d+,\d+)/i){
        Pcolor($botob, $args, $1);
    }
    if($$args{body} =~ /\w{2,5}: say (.*?)/i){
        Psay($botob, (channel => $$args{channel}, body => "$1"));
    }
    if($$args{body} =~ /\w{2,5}: change time ([PFi](?:\d+:\d{2})?)/i){
        Ptime($botob, $args, $1);
    }
    if($$args{body} =~ s/p[ea]r/<c=0,255,0>pear<\/c>/i){
        if( rand() < .3){
            Psay($botob, (channel => $$args{channel}, body => "$$args{body}"));
        }
    }
    if($$args{body} =~ /\w{2}: random homestuck page/i){
        randomPage($botob, $args);
    }
    if($$args{body} =~ /DAVE_EBUBBLES/i){
        daveEbubbles($botob, $args);
    }
}

sub Psay{
    my ($botob, %args) = @_;
    $botob->say(channel => $args{channel}, body => "<c=$Pester::color>PB: $args{body}</c>");
}


sub Pcolor{
    my ($botob, $args, $newColor) = @_;

    $Pester::color = $newColor;
    Psay($botob, (channel => $$args{channel}, body => "Ok, $$args{who}."));
}

sub Ptime{
    my ($botob, $args, $newTime) = @_;

    $Pester::currenttime = $newTime;
    $botob->say(channel => $$args{channel}, body => "PESTERCHUM:TIME>$Pester::currenttime");
    Psay($botob, (channel => $$args{channel}, body => "Ok, $$args{who}."));
}

sub checkMSPA{
    my ($botob, @chan) = @_;
    unless($Pester::lastUpdate eq $Pester::rss{update}){
        print "Up: $Pester::rss{update}\nlUp: $Pester::lastUpdate\n";
        Psay($botob, (channel => @chan, body => "UPDATE!!"));
    }
}

sub randomPage{
    my ($botob, $args) = @_;

    my $firstPage = 1901;
    my $range = $Pester::rss{page} - $firstPage;

    my $page = int(rand($range)) + $firstPage;
#    if(
    Psay($botob, (channel => $$args{channel}, body => "http://www.mspaintadventures.com/?s=6&p=00$page"));
}

sub daveEbubbles{
    my ($botob, $args) = @_;

    my $numLines = 1514;

    my $line = int(rand($numLines));
    Psay( $botob, (channel => $$args{channel}, body => "<c=240,7,7>$Pester::Dave[$line]</c>"));
}
