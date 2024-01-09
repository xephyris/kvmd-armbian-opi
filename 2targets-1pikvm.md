QUICK HOW TO "ONE PIKVM - TWO TARGETS" by @srepac

Requirements:
- x86pikvm  https://github.com/srepac/kvmd-armbian/blob/master/How%20to%20Install%20PiKVM%20x86.pdf 
- 2x uart + ch9329 (one per target)
- 2x usb hdmi (one per target)

VIDEO IN ACTION:
- https://discord.com/channels/580094191938437144/580858755827367956/1194307516838977598

Overview steps:

1.  Create x86 pikvm per the doc above.  Connect one pair of uart + ch9329 and usb hdmi per target.

2.  Setup scripts in /usr/local/bin/ for use by GPIO menu.  The ln -sf commands may need to be edited to reflect the correct devices used for your target 1 and target 2.  In my case, I confirmed the first target used ttyUSB0 and video0, before connecting the next target uart + usb hdmi to the x86 PC.
```
[root@x86kvm bin]# pwd
/usr/local/bin
[root@x86kvm bin]# ls -l ch_reset.py target.sh
-rwxr-xr-x 1 root root 471 Aug 25 16:45 ch_reset.py
-rwxr-xr-x 1 root root 384 Jan  9 08:21 target.sh

[root@x86kvm bin]# cat target.sh
#!/bin/bash
set -x

case $1 in
  1) echo "Control change to target 1"
     ln -sf ttyUSB0 /dev/kvmd-hid
     ln -sf video0 /dev/kvmd-video
     ;;
  2) echo "Control change to target 2"
     ln -sf ttyUSB1 /dev/kvmd-hid
     ln -sf video2 /dev/kvmd-video
     ;;
  *) echo "Target not defined.  Exiting."
     exit 1
     ;;
esac

systemctl restart kvmd

sleep 3
ch_reset.py

set +x

[root@x86kvm bin]# cat ch_reset.py
#!/usr/bin/python3
import serial
import time

device_path = "/dev/kvmd-hid"

chip = serial.Serial(device_path, 9600, timeout=1)

command = [87, 171, 0, 15, 0]
sum = sum(command) % 256
command.append(sum)

print("Resetting CH9329")

chip.write(serial.to_bytes(command))

time.sleep(2)

data = list(chip.read(5))

print("Initial data:", data)

if data[4] :
        more_data = list(chip.read(data[4]))
        data.extend(more_data)

print("Output: ", data)
chip.close()
```

3.  Setup sudoers to allow kvmd user to perform any commands
```
[root@x86kvm bin]# cat /etc/sudoers.d/custom_commands
kvmd ALL=(ALL) NOPASSWD: ALL
```

4.  Setup override to show target buttons in GPIO menu 
```[root@x86kvm bin]# cat /etc/kvmd/override.d/ch9329.yaml
kvmd:
    gpio:
        drivers:
            ch_reset:
                type: cmd
                cmd: [/usr/local/bin/ch_reset.py]
            target1:
                type: cmd
                cmd: [/usr/bin/sudo, /usr/local/bin/target.sh, 1]
            target2:
                type: cmd
                cmd: [/usr/bin/sudo, /usr/local/bin/target.sh, 2]

        scheme:
            ch_reset_button:
                driver: ch_reset
                pin: 0
                mode: output
                switch: false
            target1_button:
                driver: target1
                pin: 1
                mode: output
                switch: false
            target2_button:
                driver: target2
                pin: 2
                mode: output
                switch: false

        view:
            table:
                - []
                - ["#CUSTOM SCRIPTS"]
                - []
                - ["#ch_reset.py", "ch_reset_button|Reset CH9329 HID"]
                - []
                - ["#CHANGE TARGETS - requires webui restart"]
                - []
                - ["#TARGET1", "target1_button|Target1"]
                - ["#TARGET2", "target2_button|Target2"]
```
