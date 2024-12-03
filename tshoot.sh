#!/bin/bash
# Written by srepac for PiKVM project
#
# This script checks what platform is installed on PiKVM (lots of users install wrong platform)
# Also, it will then check to make sure capture card is connected properly to the correct port
# ... and report any issues and possible resolutions.
#
WHOAMI=`whoami`
if [[ "$WHOAMI" != "root" ]]; then
  echo "$WHOAMI, you must be root to run this."
  exit 1
fi

errors=0
ARCHLINUX=$( grep PRETTY /etc/os-release | grep -c Arch )
if [ $ARCHLINUX -eq 1 ]; then
  SEARCH="1-1.4"        # use only port 1-1.4 on arch linux pikvm
  PLATFORM=$( pacman -Q | grep kvmd-platform | cut -d'-' -f3,4,5 | sed 's/ /  /g' )
else
  #SEARCH="MACRO"        # any port on anything other than arch pikvm
  SEARCH="UVC"          # any port on anything other than arch pikvm
  # Show kvmd-platform version for raspbian pikvm on rpi4
  v2v3=$( grep platform /var/cache/kvmd/installed_ver.txt | cut -d'-' -f3 | tail -1 )
  if [[ $( grep video /etc/udev/rules.d/99-kvmd.rules | grep -c hdmiusb ) -gt 0 ]]; then
    platform="v2-hdmiusb-rpi4"
  else
    platform="${v2v3}-hdmi-rpi4"
  fi
  PLATFORM="$platform  $( grep kvmd-platform /var/cache/kvmd/installed_ver.txt | tail -1 | awk '{print $4}' | awk -F\- '{print $NF}')"
fi

echo "kvmd-platform/installed version:  ${PLATFORM}"
echo

echo "+ Checking for KB, VID, and MOUSE symlinks..."
KVMDEVS="/tmp/kvmdevs.txt"; rm -f $KVMDEVS
ls -l /dev/kvmd* > $KVMDEVS                             # check for kb/mouse/video
STATUS="Found"
if [ $( grep -c hid' ' $KVMDEVS ) -ge 1 ]; then
  STATUS="$STATUS Serial keyboard mouse"
else
  if [ $( grep -c keyboard $KVMDEVS ) -ge 1 ]; then
    STATUS="$STATUS OTG keyboard"
  else
    STATUS="$STATUS <missing kb>"
    let errors=errors+1
  fi
  if [ $( grep -c mouse $KVMDEVS ) -ge 1 ]; then
    STATUS="$STATUS mouse"
  else
    STATUS="$STATUS <missing mouse>"
    let errors=errors+1
  fi
fi
if [ $( grep -c video $KVMDEVS ) -ge 1 ]; then
  STATUS="$STATUS + video"
else
  STATUS="$STATUS + <missing video>"
  let errors=errors+1
fi
echo "+ $STATUS"; cat $KVMDEVS
echo

echo "+ Checking for capture device..."
HDMIUSB=$( grep video /etc/udev/rules.d/99-kvmd.rules | grep -c hdmiusb )
if [ $HDMIUSB -ge 1 ]; then
  # Make sure MACROSILICON controller on USB-HDMI is plugged in to 1-1.4
  # show the last MACROSILICON entry in case user moved the usb dongle
  # ... this way, script will always give the most recent check
  # ... NOTE:  You can move usb dongle anytime without powering down Pi
  if [ ! -e /var/log/dmesg ]; then
    USBHDMI=$( dmesg | grep -i $SEARCH | grep 'usb ' | tail -1 )
  else
    USBHDMI=$( grep -i $SEARCH /var/log/dmesg | grep 'usb ' | tail -1 )
  fi
  if [[ $( echo $USBHDMI | grep -c $SEARCH ) -gt 0 ]]; then
    printf "+ USB HDMI dongle is connected properly\n"
    echo "$USBHDMI"
    echo
    echo "*NOTE:  USB HDMI max supported resolution is 4k 30Hz downsampled to 1080p for PiKVM"
  else
    printf "x Pls put USB HDMI dongle to bottom USB2.0 port on Pi4 OR any USB port on non RPi SBC.\n"
    let errors=errors+1
  fi
else
  # PiKVM uses CSI bridge capture so check to make sure it's in the CAMERA port
  # ... NOTE:  Poweroff Pi before moving CSI cable
  CSI=$( dmesg | grep tc35 | grep -E -v -i 'Dependency|Modules' )
  if [[ $( echo $CSI | grep -c not ) -gt 0 ]]; then
    printf "x Check CSI cable is properly connected to Pi Camera port.\n"
    let errors=errors+1
  else
    printf "+ CSI 2 HDMI bridge is connected properly\n"
  fi
  echo "$CSI"; echo

  echo "+ Checking for what resolution the target is sending..."
  DVTIMINGS="/tmp/dvtimings.txt"
  v4l2-ctl --query-dv-timings  > $DVTIMINGS    # look for active width/height and pixelclock
  HEIGHT=$( grep Active $DVTIMINGS | grep height | awk '{print $NF}')
  WIDTH=$( grep Active $DVTIMINGS | grep width | awk '{print $NF}')
  if [[ $HEIGHT -eq 0 && $WIDTH -eq 0 ]]; then
    echo "+ < NO SIGNAL > from target.  Check/replace HDMI cable or power ON target."
    let errors=errors+1
  else
    HZ=$( grep Pixelclock $DVTIMINGS | awk -F\( '{print $2}' | cut -d' ' -f1 )
    echo "+ Active Target resolution:  ${WIDTH}x${HEIGHT} ${HZ}Hz"
    cat $DVTIMINGS | grep -E 'width|height|Pixel' | grep -v Total
  fi

  echo
  echo "*NOTE1:  PiKVM V2/V3 CSI builds max supported resolution: 720p 60Hz + 1080p 50Hz"
  echo "*NOTE2:  PiKVM V4 max supported resolution: 1080p 60Hz + 1920x1200 60Hz"
  echo "*NOTE3:  BliKVM v1/v2 max supported resolution: 1080p 60Hz + 1920x1200 60Hz"
  echo "*NOTE4:  BliKVM v3 HAT max supported resolution: 720p 60Hz + 1080p 50Hz"
  echo "*NOTE5:  Geekworm x652/x680 (v1.5) max supported resolution: 1080p 60Hz + 1920x1200 60Hz"
  echo "*NOTE6:  Geekworm x650, old x680, and A3/A4/A8 max supported resolution: 720p 60Hz + 1080p 50Hz"
  echo "*NOTE7:  Geekworm x635 max supported resolution: 720p 30Hz + 1080p 30Hz"
fi
printf "\n--- KNOW THE LIMITS AND MAKE SURE TARGET RESOLUTIONS STAY WITHIN THOSE LIMITS ---\n"

echo
if [ $errors -gt 0 ]; then
  echo "-> Found $errors error(s).  Please fix then try again."
else
  echo "Congratulations, $errors errors found.  If you are having issues with K V or M, then check hardware/cables."
fi
