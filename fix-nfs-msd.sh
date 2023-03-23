#!/bin/bash
# first, check to make sure that NFS_Primary is mounted in /var/lib/kvmd/msd
if [ $(mount | grep -c NFS_Primary) -le 0 ]; then
  echo "Missing /var/lib/kvmd/msd/NFS_Primary mount"
  echo "Please follow https://docs.pikvm.org/msd/#nfs-storage" 
  exit 1
else
  echo "/var/lib/kvmd/msd/NFS_Primary is mounted."

  echo "-> Stopping kvmd"
  systemctl stop kvmd
fi

NAME="aiofiles.tar"
AIOFILES="https://kvmnerds.com/RPiKVM/$NAME"

echo -n "-> Downloading $AIOFILES into /tmp ... "
wget -O /tmp/$NAME $AIOFILES > /dev/null 2> /dev/null
echo "done"

LOCATION="/usr/lib/python3.10/site-packages"
echo "-> Extracting /tmp/$NAME into $LOCATION" 
tar xvf /tmp/$NAME -C $LOCATION 

echo "-> Renaming original aiofiles and creating symlink to correct aiofiles"
cd /usr/lib/python3/dist-packages
mv aiofiles aiofiles.$(date +%Y%m%d.%H%M)
ln -s $LOCATION/aiofiles .
ls -ld aiofiles*

echo "-> Restarting kvmd"
systemctl restart kvmd

echo "-> Please check to make sure that NFS MSD is working"
