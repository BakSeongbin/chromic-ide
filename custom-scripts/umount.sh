#!/bin/sh
echo "-----------------------------------------------------------------------------------------------------------------------"
if [ ! $# == 1 ]; then
	echo "usage : um [device]"
else
	# 1. Is it valid block device file?
	if [ ! -b /dev/"$1" ]; then
		# No, It is not valid
		echo "$1 is not proper block device"
	else
		# Yes, valid
		# 2. Is it mounted?
		if mount|grep "/dev/$1 ">/dev/null; then
			# Yes, already mounted
			# umount $1	
			while true; do
				echo "umount /dev/$1"
				umount /dev/$1	
				if mount|grep "/dev/$1 " &> /dev/null; then
					echo "cd .."
					cd ..
				else
					echo "$1 unmount success"
					echo "-----------------------------------------------------------------------------------------------------------------------"
					break
				fi
			done
		else
			# No, It is not mounted
			echo "$1 is not mounted"
			echo "-----------------------------------------------------------------------------------------------------------------------"
		fi
	fi
fi
