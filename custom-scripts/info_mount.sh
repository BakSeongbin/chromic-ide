#!/bin/sh
echo "-----------------------------------------------------------------------------------------------------------------------"
if [  $# != 0 ]; then
	echo "usage : m"
else
	mount
	echo ""
	lsblk
	echo ""
	blkid -o list
	echo ""
	cd /dev
	df -hl | grep -P "/dev/sd|Filesystem|Size|Used|Avail|Use%|Mounted on"
fi
echo "-----------------------------------------------------------------------------------------------------------------------"
