#!/bin/bash
# Written by @srepac
#
# This apply kvmd 3.291 patch so that MSD doesn't require the forced_eject patch
#
# Filename:  apply-msd-patch.sh
#
# To ignore applying msd patch, run the following command as root:   touch /root/disable-msd
###
function usage() {
  echo "usage:  $0 [-f]	where -f will actually perform destructive tasks"
  exit 1
} # end usage

function patch-msd() {
  set -x

  if [ $( ls /sys/kernel/config/usb_gadget/kvmd/functions/mass_storage.usb0/lun.0/ | grep -c forced_eject ) -eq 1 ]; then
    echo "Found forced_eject patch already enabled.  Nothing to do here."
  else
    PATCHNAME="3.291msd.patch"
    echo "Applying ${PATCHNAME} for use with kvmd $KVMDVERuse..."
    cd /usr/lib/python3/dist-packages/kvmd
    wget -q https://github.com/RainCat1998/Bli-PiKVM/raw/main/$PATCHNAME -O $PATCHNAME
    patch -p1 < $PATCHNAME

    # delete msd: and next line from override.yaml
    sed -i.msd -e '/    msd:/,+1d' /etc/kvmd/override.yaml
  fi

  set +x
} # end patch-msd


### MAIN STARTS HERE ###
WHOAMI=$( whoami )
if [[ "$WHOAMI" != "root" ]]; then
  echo "$WHOAMI, please run this as root."
  exit 1
fi

perform=0
while getopts "fhv" opts; do
  case $opts in
    f) perform=1 ;;
    v) set -x; perform=0 ;;
    h) usage ;;
    *) perform=0 ;;
  esac
done

if [ $( mount | grep -c /kvmd/msd' ' ) -ge 1 ]; then
  KVMDVER=$( pikvm-info 2> /dev/null | grep kvmd-platform | awk '{print $1}' )
  if [ "$KVMDVER" == "3.291" ]; then
    if [ -e /root/disable-msd ]; then
      echo "MSD has to be disabled.  Skipping."
    else
      echo "-> Call to function patch-msd"   ### ONLY apply patch if kvmd 3.291 and /root/disable-msd file not exist ###
      if [ $perform -eq 1 ]; then
        patch-msd
      else
	echo "Please re-run script with -f to perform destructive task:  $0 -f"
      fi
    fi
  else
    echo "Found kvmd $KVMDVER running.  Patch only applies to kvmd 3.291.  Exiting."
    exit 1
  fi
else
  echo "*** Make sure an /etc/fstab entry exists for /var/lib/kvmd/msd ***"
  echo "/var/lib/kvmd/msd is not mounted.  Please create new partition for /var/lib/kvmd/msd and have it mounted before continuing."
  exit 1
fi
