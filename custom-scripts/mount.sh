#!/bin/sh
echo "-----------------------------------------------------------------------------------------------------------------------"
if [ ! $# == 1 ]; then
	echo "usage : mm [device]"
else
	#1. Is it valid block device file?
	if [ ! -b /dev/"$1" ]; then
		# No, It is not valid 
		echo "$1 is not proper block device"
		echo "-----------------------------------------------------------------------------------------------------------------------"
	else
		# Yes, valid
		# 2. Is it mounted?
		if mount|grep "/dev/$1 ">/dev/null; then
			# Yes, already mounted
			echo "$1 is already mounted"
			echo "-----------------------------------------------------------------------------------------------------------------------"
		else
			# No, It is not mounted
			# 3. mount $1
			echo "mkdir -p /media/$1"
			mkdir -p /media/$1
			echo "mount /dev/$1 /media/$1"
			mount /dev/$1 /media/$1
			# 4. In this point, mount is success or failed
			if mount|grep "/dev/$1 ">/dev/null; then
				# If mount is success
				echo "cd /media/$1"
				cd /media/$1
			fi
			echo "-----------------------------------------------------------------------------------------------------------------------"
		fi
	fi
fi
