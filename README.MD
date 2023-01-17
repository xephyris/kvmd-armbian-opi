# KVMD-ARMBIAN
This project supports non-Raspberry Pi device to run pikvm on armbian

# Install
KVMD Install for armbian
It supports Allwinner, Amlogic and Rockchip based tv box, tested on phicomm n1, mxq pro 4k, tqc a01. 
Chipset needs support USB OTG feature, lots of old amglogic chipset does not support otg feature, such as s805 and s905.
You should install armbian with debian jammy as jammy has python 3.10 which the newer kvmd code is based on.
Then running this script to install pikvm.
Install scripts is fork from @srepac raspbian pikvm install script.

Original Script [https://kvmnerds.com/RPiKVM/install-pikvm-raspbian.sh]

# Hardware for kvmd-armbian project
* A tv box/arm board supports otg feature:
    - Tests on phicomm n1(Amlogic s905d), mxq pro 4k (rk322x), tqc a01(Allwinner H6). 
    - If you are using arm board you can remove gpio patch to enable gpio feature.
* Video capture device:
    - HDMI to USB dongle (30 RMB On taobao, 10$ on aliexpress.)
      cheap hdmi to usb dongle all use physics USB2.0 port, but fake USB3.0(USB 5GBPS, USB3.2GEN1) version supports 720P 60FPS,
      usb 2.0 version only supports 720P 30FPS.
* USB-A to USB-A cable:
    - Recommended to cut off usb cable's power line, otherwise it might cause otg disconnect.

## Step 1
- Flash armbian debian [Recommended jammy] for your tv box (If kernel not support otg you should build a kernel enable otg features)
- Flash armbian debian jammy for all others

## Step 2 (skip this step if running on Orange Pi boards)
- Modify your dtb file to enable otg feature. Change dr_mode from host to peripheral for otg usb port.
- If you use rk322x (rk3228A rk3228B rk3229) series chipset, you can use dtb/4.4/rk332x-box.dtb 
- Add the following to your /boot/armbianEnv.txt file
```
overlays=usbhost0 usbhost1 usbhost2 usbhost3
```

## Step 3 - Perform part 1 of install
```
apt install -y git vim make python3-dev gcc
git clone https://github.com/srepac/kvmd-armbian.git
cd kvmd-armbian
./install.sh
```
This will ask you to press ENTER to reboot after part 1 completes.

## Step 4 - Perform part 2 of install
- run install.sh again after reboot os to perform part 2 of install.  **NOTE:  May require one more reboot if missing /dev/kvmd-hid-[keyboard|mouse]**
```
cd kvmd-armbian
./install.sh
```
- Enjoy

# Tested device
 - Phicomm N1
 - TQC A01 (Ethernet port not working, only support wireless.)
 - RK322x based tvbox (MXQ, V88)
 - S905L2 based tvbox
 - Orange pi zero (tested by @MrSuicideParrot)
 - Orange Pi Zero and One (tested by @srepac)
 - Nano Pi Neo, Rock64, and Orange Pi Zero Plus (tested by @srepac)
 - Libre Computer Le Potato, La Frite 1GB, Renegade ROC-RK3328-CC and ALL-H3-CC H5 2GB (tested by @srepac)
 - Inovato Quadra tv box (tested by @srepac)
 - Big Tree Tech CB1+Rpi4 board (WIP by @srepac)
