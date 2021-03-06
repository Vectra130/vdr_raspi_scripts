#!/bin/bash
# v1.9 all clients

#nur einmal ausfuehren!
[ $(pidof -x $(basename $0) | wc -w) -gt 2 ] && exit 0

. /etc/vectra130/configs/sysconfig/.sysconfig

if [ -e /tmp/.switch-frontend ]; then exit 1; fi
if [ "$USEKODI" != "1" ]; then exit 1; fi

touch /tmp/.switch-frontend

if [ ! -e /tmp/.powersave ]; then # testen ob suspend aktiv
	if [ -e /tmp/.startvdr ]; then
		[ x$(vdr-dbus-send.sh /Remote remote.GetVolume | grep boolean | awk '{ print $2 }') == "xfalse" ] && vdr-dbus-send.sh /Remote remote.SetVolume variant:string:'mute'
	        killall -9 -q .showscreenimage.sh
	        $SCRIPTDIR/.showscreenimage.sh switchkodi &
		test -e /tmp/.startvdr && rm /tmp/.startvdr
		killall -q vdr &
                WAIT=0
                while true; do
                        [ $(pidof -xs vdr | wc -l) == "0" ] && break
                        [ $WAIT == 8 ] && logger -t SWITCHFRONTEND "sauberes beenden von vdr nicht möglich, töte vdr" && killall -9 -q vdr && break
                        WAIT=$[ WAIT+1 ]
                        sleep 0.5
                done
	else
	        killall -9 -q .showscreenimage.sh
	        $SCRIPTDIR/.showscreenimage.sh switchvdr &
		touch /tmp/.startvdr
		for kill in kodi-standalone kodi kodi.bin; do
			killall -q $kill
	                WAIT=0
	                while true; do
	                        [ $(pidof -xs $kill | wc -l) == "0" ] && break
	                        [ $WAIT == 8 ] && logger -t SWITCHFRONTEND "sauberes beenden von $kill nicht möglich, töte $kill" && killall -9 -q $kill && break
	                        WAIT=$[ WAIT+1 ]
	                        sleep 0.5
	                done
		done
	fi
else
	touch /tmp/.startkodi
	$SCRIPTDIR/.suspend.sh
fi

rm /tmp/.switch-frontend

