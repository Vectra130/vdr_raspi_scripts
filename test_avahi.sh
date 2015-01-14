#!/bin/bash

while true; do

AVAHI="$(avahi-browse -lat | grep "\+.*vdrserver.*_system_running" | wc -l)"
if [ "$AVAHI" != "0" ]; then
	echo "SYSTEM: "$AVAHI
fi
AVAHI="$(avahi-browse -lat | grep "\+.*VDR-Backend.*vdrserver.*_vdr_backend" | wc -l)"
if [ "$AVAHI" != "0" ]; then
	echo "VDR_BACKEND: "$AVAHI
fi

sleep 5
done
