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
        #old: print file '<link href=index-48d2f5f87a2b787745b583f7f05d8951.css rel="stylesheet"></head>', "\n<body>";
        #old: print file $1 if ($html =~ /(<div class="now-timeline-interval__graph-heading">.+?<span>90min<\/span><\/h3><\/div><\/div>)/);
        #old: print file $1 if ($html =~ /(<div class="now-timeline-interval__text-only">.+?<\/span><\/span><\/div>)/); #.+?<90 minutes
        
        #new example: <div><div class="precip precip--rain now-hero__now-precipitation-amount">0<span class="precip__label precip__label--rain precip__label--inline"><abbr title="millimeters">mm</abbr></span></div><span class="now-hero__now-precipitation-text-divider" aria-hidden="true"> - </span><span class="now-hero__now-precipitation-text precipitation-text">No precipitation <span>next hour</span></span></div></div>
        #new example: <div><div class="precip precip--rain now-hero__now-precipitation-amount">0.1<span class="precip__label precip__label--rain precip__label--inline"><abbr title="millimeters">mm</abbr></span><span class="precip__dash">–</span>0.3<span class="precip__label precip__label--rain precip__label--inline"><abbr title="millimeters">mm</abbr></span></div><span class="now-hero__now-precipitation-text-divider" aria-hidden="true"> - </span><span class="now-hero__now-precipitation-text precipitation-text">Light rain <span>next hour</span></span></div></div>
        #new example: <div class="now-graph"><div class="nrk-sr">next 30 minutes no precipitation to moderate precipitation, in 30 to 60 minutes no precipitation to moderate precipitation, in 60 to 90 minutes no precipitation to moderate precipitation</div><div aria-hidden="true"><div class="now-graph__y-axis"><svg x="0" y="0" height="25px" focusable="false" width="25px" viewBox="0 0 100 100"><use xlink:href="#icon-precipitation-full" x="0" y="0" width="100" height="100"></use><image src="/assets/images/100/icon-precipitation-full.png" xlink:href></image></svg><svg x="0" y="0" height="25px" focusable="false" width="25px" viewBox="0 0 100 100"><use xlink:href="#icon-precipitation-half" x="0" y="0" width="100" height="100"></use><image src="/assets/images/100/icon-precipitation-half.png" xlink:href></image></svg><svg x="0" y="0" height="25px" focusable="false" width="25px" viewBox="0 0 100 100"><use xlink:href="#icon-precipitation-small" x="0" y="0" width="100" height="100"></use><image src="/assets/images/100/icon-precipitation-small.png" xlink:href></image></svg></div><svg class="now-graph__svg" viewBox="0 0 100 100" preserveAspectRatio="none"><defs><linearGradient id="nowPrecipitationGrad" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="0%" style="stop-opacity: 1px; stop-color: #0077CC;"></stop><stop offset="100%" style="stop-opacity: 0.4px; stop-color: #0086ff;"></stop></linearGradient></defs><path d="M0 76C1.388888888888889, 76, 5.5555555555555545, 74.66666666666667, 8.333333333333334, 76C11.111111111111112, 77.33333333333333, 13.888888888888888, 80, 16.666666666666668, 84C19.444444444444446, 88, 22.222222222222218, 97.33333333333333, 25, 100C27.777777777777782, 102.66666666666667, 30.555555555555554, 100, 33.333333333333336, 100C36.111111111111114, 100, 38.88888888888889, 100, 41.66666666666667, 100C44.44444444444445, 100, 47.22222222222223, 105.33333333333333, 50, 100C52.77777777777777, 94.66666666666667, 55.55555555555555, 73.33333333333333, 58.333333333333336, 68C61.111111111111114, 62.666666666666664, 63.888888888888886, 68, 66.66666666666667, 68C69.44444444444444, 68, 72.22222222222221, 64, 75, 68C77.77777777777777, 72, 80.55555555555556, 86.66666666666667, 83.33333333333334, 92C86.11111111111113, 97.33333333333333, 88.8888888888889, 98.66666666666667, 91.66666666666667, 100C94.44444444444444, 101.33333333333333, 98.6111111111111, 100, 100, 100 L 100 100 L 0 100 Z" fill="url(#nowPrecipitationGrad)"></path></svg><div class="now-graph__intervals"><span class="now-graph__interval"><span class="now-graph__interval-label">Now</span></span><span class="now-graph__interval"></span><span class="now-graph__interval"><span class="now-graph__interval-label">30</span></span><span class="now-graph__interval"></span><span class="now-graph__interval"><span class="now-graph__interval-label">60</span></span><span class="now-graph__interval"></span><span class="now-graph__interval"><span class="now-graph__interval-label">90</span></span></div></div></div>
        #ref: http://www.yr.no/place/Norway/Hordaland/Bergen/Nattland/varsel_nu.xml
        
        print file '<link href=index-16ce932d0d6d6406e76039f4b8ebb2af.css rel="stylesheet"></head>', "\n<body>";
        print file '<span class="pulse-icon"></span>';
        if ($html =~ /(<svg class="now-graph__svg".+?90<\/span><\/span><\/div>)/) {
            print file '&nbsp;&nbsp;Precipitation forecast:<div class="now-graph" style="width:180px;">', $1, '</div>'
        } else {
            print file '&nbsp;&nbsp;No precipitation expected next 90 minutes';
        }
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
    print file '<html><head><meta http-equiv="refresh" content="'.$tasks{'schedule'}{'delay'}.'">';
    print file "\n<style>p {margin-top: 0em; margin-bottom: 0em; font-size: small; font-family: monospace; font-size: 12px}</style></head>\n<body>";
    try {
        foreach my $destID (sort keys %destinations) {
            my $response = $ua->get('https://skyss.giantleap.no/public/departures?Hours=12&StopIdentifiers='.$destinations{$destID}{"stopID"})->decoded_content();
            my $json = decode_json $response;
            my (@times, $class, $nItems);
            print file '<p>', '<span style="color:white; font-weight:bold; background-color:black;">', $destinations{$destID}{"line"} , '</span>',
                '<span style="font-weight:bold">', " &rarr; ", $destinations{$destID}{"to"}, "</span>: ";
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
                next if (($#times >= 0) && ($times[$#times] eq $class.$$route{"DisplayTime"}.'</span>')); #bybanen duplicated entries
                push @times, $class.$$route{"DisplayTime"}.'</span>';
                last if ++$nItems >= $itemsLimit;
            }
            print file join(", ", @times), "\n";
        }    
    } catch {
        print "$_\n";
        print file "$_\n";
    };
    print file "</body></html>";
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

