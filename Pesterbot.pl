#!/usr/bin/env perl
use Bot::BasicBot;
use Data::Dumper;
use Tie::File;
use strict;
use warnings;
use diagnostics;
package Pester;


#Bot global variabes
$Pester::currenttime = "i"; #Used for the Pesterchum "protocol"
$Pester::color = "0,170,0"; #In decimal R,G,B format
@Pester::Dave; #Holds the lines for Dave's Ebubble lines
@Pester::Notes; #Holds the notes file
$Pester::lastUpdate = "1"; #Just a random string so that the runtime doesn't complain (Holds the date string from the rss) 
%Pester::rss = (
        update => "1",
        page => 1901,); #more random values (This holds data from the rss)
$Pester::firstUpdate = 1;

print("Enter bot password [or ENTER]: "); #So that I don't have to put my bot's password on github >_>

#Server Arguements
my $server = "irc.mindfang.org"; #This is the name of the Pesterchum server
my @channels = [ "#multipath_forum_adventure", "#bots" ];
my $nick = "pesterBot";
my @alt_nicks = []; #If your nick is taken, this holds any alternates
my $username = "pesterBot";
my $name = "pesterBot";
my $password = <STDIN>; #Get password from stdin

require "MSPA.pl"; #This holds checkMSPA() to check the RSS

my $bot = Bot::BasicBot->new( 
        server    => $server,
        channels  => @channels,
        nick      => $nick,
        alt_nicks => @alt_nicks,
        username  => $username,
        name      => $name,
        password  => $password,); #Create the bot object

tie @Pester::Dave, 'Tie::File', 'redBubbleText' or die("Could not open DaveQuote file: $!"); #"Tie" The file to a perl array. (Nth line in file accessible as @Dave[N])
tie @Pester::Notes, 'Tie::File', '../Notes' or die("Error reading Notes file: $!");
print "$#Pester::Dave\n";

$bot->run(); #Run the bot!

#This runs every minute (the return value is how many sec. till next time it's run)
sub Bot::BasicBot::tick{
    my ($botob) = @_;

    if($Pester::firstUpdate == 1){
        %Pester::rss = getMSPA();
        $Pester::firstUpdate = 0;
#       $botob->say(who => "NickServ", channel => "msg", body => "id $password"); #Alternate password verification
    }

    $Pester::lastUpdate = $Pester::rss{update};
    %Pester::rss = getMSPA(); 
    checkMSPA($botob, @channels); #This does the check and responds if there's an update
        return 60;
}

sub Bot::BasicBot::chanjoin{
    my ($botob, $args) = @_;

    $botob->say((channel => $$args{channel}, body => "PESTERCHUM:TIME>$Pester::currenttime")); #Displays the bot's current time for the other clients to use

        if($$args{who} ne $nick){ #So that the bot doesn't say hi to himself when he joins. But for some reason, it makes him say "pesterBot:" :shrug:
            Psay($botob, (channel => $$args{channel}, body => "Hello, $$args{who}."));
        }
}

#This is called any time anybody says something on a channel we are in
sub Bot::BasicBot::said{
    my ($botob, $args) = @_;

    $$args{body} =~ s/<c=\d+,\d+,\d+>//ig; #remove colour tags
    $$args{body} =~ s/<\/c>//ig; #And their end tags

    if($$args{body} =~ /$nick: change colou?r (\d+,\d+,\d+)/i){ #these check what people say for commands then runs the appropriate function
        Pcolor($botob, $args, $1);
    }
    if($$args{body} =~ /$nick: say (.*)/i){
        Psay($botob, (channel => $$args{channel}, body => "$1"));
    }
    if($$args{body} =~ /$nick: change time ([PFi](?:\d+:\d{2})?)/i){
        Ptime($botob, $args, $1);
    }
    if($$args{body} =~ /\w+: random homestuck page/i){
        randomPage($botob, $args);
    }
    if($$args{body} =~ /DAVE_EBUBBLES/i){
        daveEbubbles($botob, $args);
    }
    if($$args{who} eq 'oneiricVariable' && $$args{body} =~ /Note: (.*)/i){ #Only I can do notes.
        @Pester::Notes[$#Pester::Notes + 1] = "$1" or print STDERR "Note print failed: $!"; #For some reason Printing to a file discriptor doesn't work here.
        Psay($botob, (channel => $$args{channel}, body => "Ok, $$args{who}, Noting '$1'."));
    } 

    if($$args{body} =~ s/p[ea]e?r/<c=0,255,0>pear<\/c>/i){ #Automatic pear puns! (In honour of P_equals_NP)
        if( rand() < .3){
            Psay($botob, (channel => $$args{channel}, body => "$$args{body}"));
        }
    }
} 

#This formats the bot's strings to Pesterchum format
sub Psay{
    my ($botob, %args) = @_;
    $botob->say(channel => $args{channel}, body => "<c=$Pester::color>PB: $args{body}</c>");
}

#Changes the colour to a new one
sub Pcolor{
    my ($botob, $args, $newColor) = @_;

    $Pester::color = $newColor;
    Psay($botob, (channel => $$args{channel}, body => "Ok, $$args{who}."));
}

#Same thing, but with time
sub Ptime{
    my ($botob, $args, $newTime) = @_;

    $Pester::currenttime = $newTime;
    $botob->say(channel => $$args{channel}, body => "PESTERCHUM:TIME>$Pester::currenttime");
    Psay($botob, (channel => $$args{channel}, body => "Ok, $$args{who}."));
}

#Checks the two MSPA strings for differences (Which means an UPDATE!!)
sub checkMSPA{
    my ($botob, @chan) = @_;
    unless($Pester::lastUpdate eq $Pester::rss{update}){
        print "Up: $Pester::rss{update}\nlUp: $Pester::lastUpdate\n";
        Psay($botob, (channel => @chan, body => "UPDATE!!"));
    }
}

#Makes the bot say a random Homestuck page
sub randomPage{
    my ($botob, $args) = @_;

    my $firstPage = 1901;
    my $range = $Pester::rss{page} - $firstPage;

    my $page = int(rand($range)) + $firstPage;

    Psay($botob, (channel => $$args{channel}, body => "http://www.mspaintadventures.com/?s=6&p=00$page"));#I should really add zero's appropriately on the "p=\d{6}" area, but I'm lazy and I assume Homestuck isn't gonna add 2000 pages by the time it ends. (Heh. Riiiiiiiight.)
}

#Bot says a random string from redBubbleText. As seen from the dream-bubble walkaround
sub daveEbubbles{
    my ($botob, $args) = @_;

    my $numLines = $#Pester::Dave; #Number of lines in the redBubbleText file.

        my $line = int(rand($numLines));
    Psay( $botob, (channel => $$args{channel}, body => "<c=240,7,7>$Pester::Dave[$line]</c>"));
}
