#!/bin/bash
# Written by srepac (c) 2023
#
# This is meant for armbian PiKVM use -- required to make NFS MSD work properly (in effect since kvmd 3.206)
#
# In summary, this script will perform the following steps:
: "
1.  take the contents of /usr/lib/python3.10/site-packages/aiofiles from arch pikvm and extract it to armbian
2.  rename aiofiles within /usr/lib/python3/dist-packages to aiofiles.YYYYMMDD.hhmm
3.  create symlink to /usr/lib/python3.10/site-packages/aiofiles into /usr/lib/python3/dist-packages
4.  restart kvmd
"

NAME="aiofiles.tar"
AIOFILES="https://raw.githubusercontent.com/srepac/kvmd-armbian/master/$NAME"

echo -n "-> Downloading $AIOFILES into /tmp ... "
wget -O /tmp/$NAME $AIOFILES > /dev/null 2> /dev/null
echo "done"

LOCATION="/usr/lib/python3.11/site-packages"
echo "-> Extracting /tmp/$NAME into $LOCATION"
tar xvf /tmp/$NAME -C $LOCATION

echo "-> Renaming original aiofiles and creating symlink to correct aiofiles"
cd /usr/lib/python3/dist-packages
mv aiofiles aiofiles.$(date +%Y%m%d.%H%M)
ln -s $LOCATION/aiofiles .
ls -ld aiofiles*

echo "-> Restarting kvmd"
systemctl restart kvmd

echo "-> Please check webui to make sure that NFS MSD is working properly."
