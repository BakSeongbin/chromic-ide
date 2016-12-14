#!/bin/sh
ifconfig wlan0 down
ifconfig wlan0 essid "301B"
wpa_supplicant -i wlan0 -c /etc/wpa_supplicant/301B.conf &
sleep 20
dhclient -v wlan0
