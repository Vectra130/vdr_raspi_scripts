#!/bin/bash
# v1.0 raspi

#nur einmal ausfuehren!
[ $(pidof -x $(basename $0) | wc -w) -gt 2 ] && exit 0

#Prueft die Lizenzen auf veraenderung

. /etc/vectra130/configs/sysconfig/.sysconfig

mount -o rw,remount /boot
for LICENSE in MPG2 WVC1; do
	. /boot/config.txt
	eval Lnow=\$decode_$(echo $LICENSE)
	. $SYSCONFDIR/.sysconfig
	eval Lnew=\$decode_$(echo $LICENSE)

	if [ "$Lnow" != "$Lnew" ]; then
		cat /boot/config.txt | sed -e 's/^decode_'$LICENSE'='$Lnow'/decode_'$LICENSE'='$Lnew'/' > /tmp/tmp_checklicense && mv /tmp/tmp_checklicense /boot/config.txt
		REBOOT=1
	fi
done
mount -o ro,remount /boot
exit 0
if [ "$REBOOT" == "1" ]; then
	echo "RaspberryPi Decoder-Lizenz-Key wurde veraendert!" >> $MSG
	echo "Uebernehme neue Lizenz-Keys ..." >> $MSG
	echo >> $MSG
	echo >> $MSG
	touch /tmp/.reboot
fi

