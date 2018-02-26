use strict;
use Try::Tiny;
use LWP::UserAgent;
use JSON::Tiny qw(decode_json);
use DateTime;

$|++;
my $loc = "/ramdisk/homescreen/";
my $sleepInterval = 30;

my %tasks = (
    "meteogram" => {
        "delay" => 600,
        "sub" => \&fetchMeteogram,
        "rounds" => 0
    },
    "schedule" => {
        "delay" => 30,
        "sub" => \&fetchSchedule,
        "rounds" => 0
    },
    "precipitation" => {
        "delay" => 120,
        "sub" => \&fetchPrecipitation,
        "rounds" => 0
    }
);

my $ua = LWP::UserAgent->new(agent => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.78 Safari/537.36');

sub fetchMeteogram {
    my $svg = $ua->get("https://www.yr.no/place/Norway/Hordaland/Bergen/Nattland//meteogram.svg")->content();
    open (file, ">$loc"."meteogram.html.new") or die "cannot open meteogram.html.new";
    print file '<html><head><meta http-equiv="refresh" content="'.$tasks{'meteogram'}{'delay'}.'"></head><body><svg width="1002" height="330" xmlns="http://www.w3.org/2000/svg"><g transform="scale(1.21, 1.21)">';
    print file $svg;
    print file "</g></svg></body></html>";
    close file;
    rename "$loc"."meteogram.html.new", "$loc"."meteogram.html";
}

sub fetchPrecipitation {
    open (file, ">$loc"."precipitation.html.new") or die "cannot open precipitation.html.new";
    try {
        my $html = $ua->get("https://www.yr.no/en/list/daily/1-92741/Norway/Hordaland/Bergen/Nattland")->decoded_content();
        print file '<html><head><meta http-equiv="refresh" content="'.$tasks{'precipitation'}{'delay'}.'">';
        print file '<link href=index-48d2f5f87a2b787745b583f7f05d8951.css rel="stylesheet"></head>', "\n<body>";
        print file $1 if ($html =~ /(<div class="now-timeline-interval__graph-heading">.+?<span>90min<\/span><\/h3><\/div><\/div>)/);
        print file $1 if ($html =~ /(<div class="now-timeline-interval__text-only">.+?<\/span><\/span><\/div>)/); #.+?<90 minutes
        print file "</body></html>";
    } catch {
      print file "$_\n";
    };
    close file;
    rename "$loc"."precipitation.html.new", "$loc"."precipitation.html";
}

sub fetchSchedule {
    my %destinations = (
        "1" => {"from" => "Home",
                "to" => "Sentrum",
                "stopID" => 12011525,
                "line" => "&nbsp;21&nbsp;",
                "distance" => 4},
        "2" => {"from" => "Home",
                "to" => "Lagunen",
                "stopID" => 12011530,
                "line" => "&nbsp;21&nbsp;",
                "distance" => 2},
        "3" => {"from" => "Paradis",
                "to" => "Byparken",
                "stopID" => 12016523,
                "line" => "&nbsp;1&nbsp;",
                "distance" => 10},
        "4" => {"from" => "Paradis",
                "to" => "Lufthavn",
                "stopID" => 12015500,
                "line" => "&nbsp;1&nbsp;",
                "distance" => 10},
        "5" => {"from" => "Birkelundstoppen",
                "to" => "Sentrum",
                "stopID" => 12011466,
                "line" => "&nbsp;2&nbsp;&nbsp;",
                "distance" => 7}
    );
    
    my $itemsLimit = 6;
    
    open (file, ">$loc"."schedule.html.new") or die "cannot open schedule.html.new";
    try {
        print file '<html><head><meta http-equiv="refresh" content="'.$tasks{'schedule'}{'delay'}.'">';
        #print file '<link href="//fonts.googleapis.com/css?family=Roboto:400,500,600,700,800,900" rel="stylesheet" type="text/css">';
        print file "\n<style>p {margin-top: 0em; margin-bottom: 0em; font-size: small; font-family: monospace; font-size: 12px}</style></head>\n<body>";
        foreach my $destID (sort keys %destinations) {
            my $response = $ua->get('https://skyss.giantleap.no/public/departures?Hours=12&StopIdentifiers='.$destinations{$destID}{"stopID"})->decoded_content();
            my $json = decode_json $response;
            my (@times, $class, $nItems);
            print file '<p>', '<span style="color:white; font-weight:bold; background-color:black;">', $destinations{$destID}{"line"} , '</span>',
                '<span style="font-weight:bold">', " → ", $destinations{$destID}{"to"}, "</span>: ";
            foreach my $route (@{$$json{"PassingTimes"}}) {
                my $aimedTime = DateTime->new(
                    year       => $1,
                    month      => $2,
                    day        => $3,
                    hour       => $4,
                    minute     => $5,
                    second     => $6,
                    nanosecond => 0,
                    time_zone  => '+0000',
                ) if ($$route{"AimedTime"} =~ /(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})\./);
                my $duration = $aimedTime->subtract_datetime_absolute(DateTime->now( time_zone => 'local'))->seconds();
                if ($duration < $destinations{$destID}{"distance"}*60) {
                    $class = '<span style="color:lightgrey; font-weight:bold">';
                } elsif ($duration < ($destinations{$destID}{"distance"}+5)*60) {
                    $class = '<span style="color:red; font-weight:bold">';
                } elsif ($duration < ($destinations{$destID}{"distance"}+10)*60) {
                    $class = '<span style="color:black; font-weight:bold">';
                } else {
                    $class = '<span>';
                }
                push @times, $class.$$route{"DisplayTime"}.'</span>';
                last if ++$nItems >= $itemsLimit;
            }
            print file join(", ", @times), "\n";
        }
        print file "</body></html>";
    } catch {
        print "$_\n";
        print file "$_\n";
    };
    close file;
    rename "$loc"."schedule.html.new", "$loc"."schedule.html";
     
    #12011525 - Home->Busstasjon
    #12011530 - Home->Lagunen
    #12015500 - Paradis->Lufthavn
    #12016523 - Paradis->Byparken
    #12016440 - HaukelandN->Home
}


my $startTime = time;
while (1) {
    foreach my $task (keys %tasks) {
        if ((time-$startTime)/$tasks{$task}{"delay"} > $tasks{$task}{"rounds"}) {
            $tasks{$task}{"rounds"}++;
            #print $task, "\n";
            &{$tasks{$task}{"sub"}};
        }
    }
    sleep $sleepInterval;
}

