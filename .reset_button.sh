#!/bin/bash
# v1.0 raspi

#nur einmal ausfuehren!
[ $(pidof -x $(basename $0) | wc -w) -gt 2 ] && exit 0

#Ueberwacht den Zustand des Reset Knopfes

. /etc/vectra130/configs/sysconfig/.sysconfig

checkbutton() {
	if [ "$(cat /sys/class/gpio/gpio29/value)" == "1" ]; then
		logger -t RESET "Reset Button betaetigt seit $t Sekunden"
		press=1
	else
		press=0
	fi
}
setfirststart() {
	logger -t RESET "Reset Button wurde $t Sekunden betaetigt, Firststart Sequenz wird eingeleitet"
	sed -i -e 's/\(FIRSTSTART=\).*/\1\"1\"/' $SYSCONFDIR/.sysconfig
	sed -i -e 's/FIRSTSTART:0:/FIRSTATART:1:/' $SYSCONFDIR/.config
	reboot force
	exit 0
}


t=0
while [ 1 == 1 ]; do

	checkbutton
	if [ "$press" == "1" ]; then
		if [ "$t" == 5 ]; then
			setfirststart
		else
			t=$[ t+1 ]
		fi
	else
		t=0
	fi

sleep 1
done
