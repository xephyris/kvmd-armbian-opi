#!/bin/bash
###
# Written by @srepac
# This script creates FLASH.img within your root fs in case you didnt' create an MSD partition
# ... this will then add the proper /etc/fstab entry to mount the created FLASH.img
# ... this is meant for non-arch pikvm builds (e.g. armbian/raspbian)
###

# init variables
validname=0; NAME=""
validdir=0; FLASHDIR="/"
validsize=0; SIZE=9999

function usage() {
  echo "Usage:  $(basename $0) [-n <flashname> ] [ -s <size> ] [ -d <directory> ]"
  echo
  echo "Example: $(basename $0) -n TEST -s 8 -d /home/admin   creates 8GB /home/admin/TEST.img flash image"
  echo
  exit 1
}

VER=1.0
echo
echo "--- Flash image creator v${VER} by srepac ---"
echo

while getopts ':n:s:d:h' OPTION; do
  case $OPTION in
    n) 
      NAME="$OPTARG"
      echo "flash drive name: $NAME.img"
      validname=1
      ;;
    d)
      FLASHDIR="$OPTARG"
      echo "flash drive location: $FLASHDIR"
      if [ ! -e $FLASHDIR ]; then
        echo "$FLASHDIR doesn't exist." 
        validdir=0
      else
        validdir=1
      fi
      ;;
    s)
      SIZE="$OPTARG"
      echo "size: $SIZE GB"
      validsize=1
      ;;
    h)
      usage
      ;;
    *)
      echo "Invalid option $OPTION"
      usage
      ;;
  esac
done

if [[ "$FLASHDIR" != "/" ]]; then
  MAXSIZE=$( df -h $FLASHDIR | grep -v Size  | awk '{print $4}' | cut -d'.' -f1 )
  echo "MAXSIZE:  $MAXSIZE"
  if [ $SIZE -gt $MAXSIZE ]; then
    echo "Size cannot be bigger than available size.  Try again..." 
    validsize=0
  fi
fi
    
while [ $validname -eq 0 ]; do
  read -p "Please enter flash drive name you want to use -> " NAME
  if [[ "$NAME" == "" ]]; then
    echo "Nothing was entered.  Please try again..."
    validname=0
  else
    validname=1
  fi
done

while [ $validdir -eq 0 ]; do
  read -p "Please enter path to create the flash image -> " FLASHDIR
  if [[ "$FLASHDIR" == "" ]]; then
    echo "Nothing was entered.  Please try again..."
    validdir=0
  elif [ ! -e $FLASHDIR ]; then
    echo "$FLASHDIR doesn't exist.  Try again..."
    validdir=0
  else
    echo "-> $FLASHDIR exists.  Continuing..." 
    validdir=1
  fi
done

while [ $validsize -eq 0 ]; do
  MAXSIZE=$( df -h $FLASHDIR | grep -v Size  | awk '{print $4}' | cut -d'.' -f1 )

  read -p "Please enter size in GB (enter 1-$MAXSIZE) -> " SIZE
  SIZE=$( echo $SIZE | sed 's/[Gg][Bb]//g' )   # cleanup entry in case user entered 8GB instead of just 8

  if [[ "$SIZE" == "" ]]; then
    echo "Nothing was entered.  Please try again..."
    validsize=0
  elif [ $SIZE -le 0 ]; then
    echo "Size cannot be zero or negative number.  Try again..."
    validsize=0
  elif [ $SIZE -gt $MAXSIZE ]; then
    echo "Size cannot be bigger than available size.  Try again..." 
    validsize=0
  else
    validsize=1
  fi
done 

echo "-> Creating empty ${SIZE}GB flash in $FLASHDIR/$NAME.img ..."
truncate -s ${SIZE}G $FLASHDIR/$NAME.img    # creates an 8GB flash image file (in seconds)

echo
echo "-> Formatting $FLASHDIR/$NAME.img as ext4 ..."
mkfs.ext4 $FLASHDIR/$NAME.img         # format ext4 flash image

echo
echo "-> Labeling $FLASHDIR/$NAME.img as PIMSD ..."
e2label $FLASHDIR/$NAME.img PIMSD     # label it as PIMSD

systemctl daemon-reload

TESTDIR="/mnt/TEST"
echo
echo "-> Mounting $FLASHDIR/$NAME.img into $TESTDIR and testing creating files..."
mkdir -p $TESTDIR 
mount $FLASHDIR/$NAME.img $TESTDIR
umount $TESTDIR
sleep 3
mount $FLASHDIR/$NAME.img $TESTDIR 
lsblk -f

df -h | grep TEST
cd $TESTDIR 
pwd
chown kvmd:kvmd .
touch newfile      # test creating new file
mkdir NFS_Primary  # create NFS_Primary dir in case you use NFS https://docs.pikvm.org/msd/?h=nfs#nfs-storage
ls -la
cd 

echo
echo "-> Unmounting $TESTDIR..." 
umount $TESTDIR 

# and then add into fstab
echo
if [ $( grep /var/lib/kvmd/msd' ' /etc/fstab | grep -c -v '#' ) -ge 1 ]; then
  echo "/etc/fstab entry already exists."
else
  echo "-> Adding /etc/fstab entry..."
  echo $FLASHDIR/$NAME.img    /var/lib/kvmd/msd  ext4  nodev,nosuid,noexec,rw,errors=remount-ro,X-kvmd.otgmsd-root=/var/lib/kvmd/msd,X-kvmd.otgmsd-user=kvmd  0 0 >> /etc/fstab
fi
grep /var/lib/kvmd/msd' ' /etc/fstab | grep -v '#'
