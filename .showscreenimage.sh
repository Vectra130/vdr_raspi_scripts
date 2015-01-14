#!/bin/bash
# v1.3 raspi

. /etc/vectra130/configs/sysconfig/.sysconfig
. $SCRIPTDIR/.killbootsplash

#OPTIONS="-a -noverbose -T 2"
OPTIONS="-noverbose -T 2"
TYPE="$2"
[ "$2" == "" ] && TYPE="png"
if [ -e $IMAGEDIR/screen_$1.$TYPE ]; then
        SHOWIMAGE=$IMAGEDIR/screen_$1.$TYPE
        SHOWINFO="Zeige User Grafik: $1"
else
        SHOWIMAGE=$VECTRADIR/sysimages/screen_$1.$TYPE
        SHOWINFO="Zeige Sys Grafik: $1"
fi
fbi $OPTIONS $VECTRADIR/sysimages/screen_blank.$TYPE &>/dev/null
fbset -depth 32; fbset -depth 16
export DISPLAY=:0.0
logger -t SHOWSCREENIMAGE $SHOWINFO
killall -9 -q fbi
fbi $OPTIONS $SHOWIMAGE &>/dev/null
sleep 15
killall -9 -q fbi
#Konsolenbildschirmschoner abschalten
setterm -blank 0 -blink off -powerdown 0 -cursor off -store > $KEYB_TTY
if [ "$1" == "kodi" ]; then
	sleep 1
	fbi $OPTIONS $VECTRADIR/sysimages/screen_blank.$TYPE &>/dev/null
	sleep 5
	killall -9 -q fbi
fi
exit 0
