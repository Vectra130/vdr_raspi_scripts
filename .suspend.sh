#!/bin/bash
# v1.8 raspi

#Energiesparen (Suspend Mode)

if [ -e /tmp/.pwlock ] ; then
  # Nur eine Instanz zulassen
  exit 1
fi

touch /tmp/.pwlock

. /etc/vectra130/configs/sysconfig/.sysconfig

#Erst die einzelnen Funktionen anlegen
#Suspend starten
startsuspend(){
        touch /tmp/.powersave
	touch /tmp/.wlan_watchdog.block
	touch /tmp/.renice_watchdog.block
	touch /tmp/.cec_watchdog.block

	#Suspend Screen setzen
	killall -9 -q .showscreenimage.sh
	if [ ! -e /tmp/.no_startsuspend_info ]; then
		$SCRIPTDIR/.showscreenimage.sh startsuspend &
		stopallmultimedia
	fi
        echo StandBy
        sed -i -e 's/StandBy/Wakeup/' $WWWDIR/config/commands
        #aufraumen und memory cache leeren
        [ $(ls /tmp/ | wc -l) != "0" ] && rm -r /tmp/* > /dev/null
	[ $(ls /root/ | grep ^kodi_crashlog | wc -l) != "0" ] && rm /root/kodi_crashlog*
	[ $(ls /var/log/ | grep [.][1-9] | wc -l) != "0" ] && rm /var/log/*.[1-9]*
	echo "" > /var/log/debug
        sync && echo 3 > /proc/sys/vm/drop_caches
#	stop autofs

        logger -t SUSPEND "suspend"
	stop syslog-ng
	rm /tmp/.pwlock
	killall -9 -q .showscreenimage.sh
	$SCRIPTDIR/.showscreenimage.sh suspend &
	if [ "$SCREENOFF" != "Nein" ]; then
		sleep 1
		if [ "$SCREENOFF" == "CEC" ]; then
			[ -e /tmp/.cec_connect.time ] && rm /tmp/.cec_connect.time
			echo "standby 0" | cec-client -s
		fi
		[ "$SCREENOFF" == "GPIO" ] && echo "0" > /sys/class/gpio/gpio3/value
	fi
	[ -e /tmp/.no_startsuspend_info ] && rm /tmp/.no_startsuspend_info

}

#Suspend beenden
endsuspend(){
	tput -Tlinux clear > $KEYB_TTY
	fbi -T 2 -noverbose $VECTRADIR/sysimages/screen_blank.png
	ls /nfs/vdrserver/ > /dev/null &
        test -e /tmp/.powersave && rm /tmp/.powersave
	test -e /tmp/.switchvdr && rm /tmp/.switchvdr
	[ -e /tmp/.cec_watchdog.block ] && rm /tmp/.cec_watchdog.block
	[ -e /tmp/.wlan_watchdog.block ] && rm /tmp/.wlan_watchdog.block
	[ -e /tmp/.renice_watchdog.block ] && rm /tmp/.renice_watchdog.block

	[ "$DEBUGMODE" == "YES" ] && start syslog-ng &
	if [ "$SCREENOFF" != "Nein" ]; then
		[ "$SCREENOFF" == "CEC" ] && echo "on 0" | cec-client -s
		[ "$SCREENOFF" == "GPIO" ] && echo "1" > /sys/class/gpio/gpio3/value
	fi
	[ $(pidof -xs automount | wc -l) == "0" ] && start autofs &
	logger -t SUSPEND "endsuspend"
	nice -$_watchdog_sh_nice $SCRIPTDIR/.frontend.sh &
        #Watchdog starten
        logger -t WATCHDOG "Starte Watchdogs"
        pidof -xs .watchdog.sh || $SCRIPTDIR/.watchdog.sh &
	tput -Tlinux clear > $KEYB_TTY
	chvt $(echo $KEYB_TTY | sed -e 's/\/dev\/tty//')
        rm /tmp/.pwlock
	echo Wakeup
	sed -i -e 's/Wakeup/StandBy/' $WWWDIR/config/commands
}

#poweroff
poweroff(){
    /sbin/raspi-init 0
    rm /tmp/.pwlock
    exit 0
}

stopallmultimedia(){
    . $SCRIPTDIR/.stopallmultimedia
}





#Aktion wenn die Power-Taste an der Fernbedienung gedrueckt wird

[[ "$1" != "" && "$1" != [0-9] ]] && POWEROFF=$1
echo $POWEROFF
case "$POWEROFF" in
    Ausschalten) # Powertaste startet SHUTDOWN
        test -e /tmp/.switchvdr && rm /tmp/.switchvdr && killall vdr-fbfe rm /tmp/pwlock && sleep 2 && svdrpsend MESG Lokaler VDR wieder aktiv && exit 0
        if [ ! -e /tmp/.powersave ]; then

		expect -c "set echo \"-noecho\"; set timeout 10; spawn -noecho "$SCRIPTDIR"/.get_avr_infos.sh; expect timeout { exit 1 } eof { exit 0 }"
                poweroff

        else

                endsuspend

        fi


        ;;

    Standby) # In den Standby wechseln
	if [ ! -e /tmp/.powersave ]; then
		touch /tmp/.irexec_watchdog.block
		killall -9 -q irexec
		expect -c "set echo \"-noecho\"; set timeout 10; spawn -noecho "$SCRIPTDIR"/.get_avr_infos.sh; expect timeout { exit 1 } eof { exit 0 }"
		startsuspend
	else
		touch /tmp/.irexec_watchdog.block
		killall -9 -q irexec
		endsuspend

	fi
        ;;

    Wakeup) # Aus dem Standby wecken
	if [ -e /tmp/.powersave ]; then
		touch /tmp/.irexec_watchdog.block
		killall -9 -q irexec
		endsuspend
	fi
        ;;

esac
[ "$(pidof -xs irexec | wc -l)" == "0" ] && irexec $SYSCONFDIR/.irexec.conf &
[ -e /tmp/.irexec_watchdog.block ] && rm /tmp/.irexec_watchdog.block

test -e /tmp/.pwlock && rm /tmp/.pwlock
