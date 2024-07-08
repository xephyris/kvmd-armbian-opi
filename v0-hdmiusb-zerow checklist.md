**Checklist to make v0-hdmiusb-zerow image from v2-hdmi-zerow**


REQUIREMENTS:

- Pi Zero W with gpio header pins
- CSI 2 HDMI adapter and micro USB cable (this is only needed to verify v2-hdmi-zerow functionality temporarily)
- Micro USB HUB (connects to otg port on pi zero w; can have 2-3 USB-A ports and/or ethernet adapter)
- Official RPi micro USB power adapter
- USB-HDMI capture dongle
- ch9329 serial HID + dupont wires (3x)


STEP-BY-STEP INSTRUCTIONS:

0.  Image raspbian 32-bit bookworm to SD card using Raspberry Pi Imager.

1.  Boot Pi Zero W with SD card and install v2-hdmi-zerow pikvm using kvmd-armbian installer (run part 1, reboot, then run part2).  See https://github.com/srepac/kvmd-armbian for details on how to install pikvm on armbian/raspbian bookworm

For reference, this is the platform package that should be installed by the script above.

  https://kvmnerds.com:8443/REPO/kvmd-platform-v2-hdmi-zerow-3.54-1-any.pkg.tar.xz

NOTE:  The most important file from the package is /etc/kvmd/main.yaml.  These are the streamer entries that are needed out of the /etc/kvmd/main.yaml file from the package above, but you should make sure /etc/kvmd/main.yaml exists after the install.
```
    streamer:
        quality: 50
        unix: /run/kvmd/ustreamer.sock
        cmd:
            - "/usr/bin/ustreamer"
            - "--device=/dev/kvmd-video"
            - "--persistent"
            - "--dv-timings"
            - "--format=uyvy"
            - "--encoder=omx"
            - "--workers=1"
            - "--quality={quality}"
            - "--desired-fps={desired_fps}"
            - "--drop-same-frames=30"
            - "--last-as-blank=0"
            - "--unix={unix}"
            - "--unix-rm"
            - "--unix-mode=0660"
            - "--exit-on-parent-death"
            - "--process-name-prefix={process_name_prefix}"
            - "--notify-parent"
            - "--no-log-colors"
```

**IMPORTANT:  Make sure pikvm works to control a target system using OTG (micro USB cable) and CSI adapter before continuing**

**Once you have verified it works with OTG and CSI, then we need to power off pi zero w to remove CSI adapter and micro USB to USB-A cable.  Afterwards, connect ch9329 to UART gpio pins on the pi and connect USB hub with USB-HDMI connected to one of the ports on the hub.  Power on zero w + usb hub + usb-hdmi dongle and ch9329 serial HID.**


2.  Edit /etc/udev/rules.d/99-kvmd.rules for use with the usb-hdmi capture instead of CSI adapter.  You will also need to edit /usr/bin/kvmd-udev-hdmiusb-check and add entry for zerow.

/etc/udev/rules.d/99-kvmd.rules change to use USB HDMI in place of CSI and ch9329 serial HID
```
KERNEL=="video[0-9]*", SUBSYSTEM=="video4linux", PROGRAM="/usr/bin/kvmd-udev-hdmiusb-check zerow %b", ATTR{index}=="0", GROUP="kvmd", SYMLINK+="kvmd-video"
KERNEL=="ttyAMA0", SYMLINK+="kvmd-hid"
```

/usr/bin/kvmd-udev-hdmiusb-check script change:

Add the zerow) line right before the *) exit 1;; line
```
	zerow) exit 0;;    # allow any USB port for USB HDMI capture dongle
        *) exit 1;;
```

3.  Edit /etc/kvmd/override.yaml to use ch9329 serial hid instead of OTG
```
kvmd:
    hid:
        type: ch9329
        speed: 9600     # default speed after loading ch9329 plugin is 9600
        device: /dev/kvmd-hid
```

4.  Modify dr_mode=peripheral to dr_mode=host in /boot/config.txt so we can use a USB hub on the pi zero w for the USB HDMI capture.
```
sed -i -e 's/dr_mode=peripheral/dr_mode=host/g' /boot/config.txt
```


5.  Lastly, remove tc358743 from /etc/modules, delete /etc/kvmd/tc358743-edid.hex and disable kvmd-tc358743 and kvmd-otg services.
```
sed -i -e 's/tc358743/#tc358743/g' /etc/modules
rm -f /etc/kvmd/tc358743-edid.hex
systemctl disable --now kvmd-tc358743 kvmd-otg
```

6.  Reboot and verify you can use USB-HDMI capture and ch9329 serial HID to control a target system.
