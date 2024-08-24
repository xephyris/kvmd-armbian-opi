#!/bin/bash
# Written by @srepac (c) 2024
####
# Filename:  flash-img-creator.sh
####

# Remount internal storage to read-write mode manually:
kvmd-helper-otgmsd-remount rw

# Initialize variables
FLASHIMG=/var/lib/kvmd/msd/flash.img	# path/filename of img file
LABEL="FLASHIMG"			# partition label
create=1				# default is to create img file	

if [ -e $FLASHIMG ]; then 		# check if img file already exists
	ls -l $FLASHIMG
	echo "Found existing $FLASHIMG" 

	loop=1
	while [ $loop -eq 1 ]; do
		read -p "Do you want to remove it? Y/N -> " answer
		case $answer in
			y|Y) echo "Deleting $FLASHIMG"; rm -f $FLASHIMG; create=1; loop=0;;	# remove and create new img file
			n|N) echo "Exiting."; loop=0; create=0;;				# don't touch img file
			*) echo "Please try again."; loop=1;;
		esac
	done
fi

set -x
if [ $create -eq 1 ]; then
	# Create empty image file in /var/lib/kvmd/msd (in internal storage of PiKVM images) of desired size 
	# ... 8GB in this example and format it to FAT32 and add a label to it
	truncate -s 8G $FLASHIMG 
	echo -e 'o\nn\np\n1\n\n\nt\nc\nw\n' | fdisk $FLASHIMG 
	loop=$(losetup -f)
	losetup -P $loop $FLASHIMG 
	mkfs.vfat ${loop}p1
	fatlabel ${loop}p1 $LABEL && sleep 5
	lsblk -f ${loop}
	losetup -d $loop
	chmod go+rw $FLASHIMG
	ls -l $FLASHIMG
fi

# Remount internal storage back to safe read-only mode:
kvmd-helper-otgmsd-remount ro
set +x
