killall perl
killall chromium-browser
cp -R /home/pi/homescreen /ramdisk/
export DISPLAY=:0
chromium-browser --noerrdialogs --disable-infobars --disable-suggestions-service --disable-session-crashed-bubble --incognito --kiosk /ramdisk/homescreen/homescreen.html &
perl /ramdisk/homescreen/fetcher.pl &
