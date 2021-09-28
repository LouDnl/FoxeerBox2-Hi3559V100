# Foxeer Box 2 - HI3559
### Goals
* Persistent root access ✔
* Gyro access ✘
* Export gyro data ✘

# Precaution
This page contains a log with parts of what I tried and was able to find out (and ofcourse not all my failures lol), I take no responsibility for the files or methods herein.
If you want to try this you break your warranty and you are responsible if your device breaks and/or no longer works.
The internet is full of usefull websites with methods and tutorials for webcams, security cameras, action cameras that have weak security. This page is just one of many.

## About
I recently purchased a Foxeer Box 2 in hoping to use it with [GYROflow](https://elvinchen.com/gyroflow/) - [Git](https://github.com/ElvinC/gyroflow).
Since Foxeer advertises it having EIS using a [BMI160](https://www.bosch-sensortec.com/products/motion-sensors/imus/bmi160/) on their [website](https://www.foxeer.com/foxeer-box-2-4k-hd-action-fpv-camera-supervison-g-222) I hoped it to be able to write the gyro data to the SD card.
Unfortunatly that is not the case, the only thing you can do is enable or disable image stabilisation in the settings through an app.
I double checked and even informed with someone from Foxeer if it would be possible to get the gyro data out of the device.
This was not possible said the person from Foxeer and it was too old to support. Besides that, they didn't manufacture it so they have no control.

## First steps
### WiFi
The device receives settings from an app on your phone whilst being connected the the WiFi accesspoint that is provided by the device.
I captured all TCP and UDP packets the app sent to and got from the device using [Packet Capture](https://play.google.com/store/apps/details?id=app.greyshirts.sslcapture) for Android.
The device uses a webservice to receive and send information.
Multiple cgi files are used to transfer information between the app and the device. The app translates this information to readable settings.
Example link: http://192.168.0.1/cgi-bin/hi3510/getparameter.cgi?&-workmode=11&-type=0

From previous adventures I knew that most of these cameras are not very secure and I recognised a familiar similarity in the url.
Earlier this year I came across a Hisilicon Hi3518 chip when trying to get root access to a security camera that I bought.
More about that here [BazzDoorbell](https://github.com/guino/BazzDoorbell/issues/2).

### Portscan
Instead of connecting to the device with my phone I used my Kali laptop.
After connecting and I ran nmap to see what ports were open for manipulation. 
Output:
```bash
Starting Nmap 7.91 ( https://nmap.org ) at 2021-09-$$ $$:$$ CEST
Nmap scan report for 192.168.0.1
Host is up (0.018s latency).
Not shown: 65532 closed ports
PORT    STATE SERVICE
80/tcp  open  http
443/tcp open  https
554/tcp open  rtsp

Nmap done: 1 IP address (1 host up) scanned in 22.81 seconds
```
Bummer, no telnet and no way to activate it (tried all sorts of cgi combinations). My old Escam G02 security camera had a cgi weblink to activate Telnet, but alas no luck.

## Firmware
### Downloading and unpacking
Fortunatly Foxeer provides the firmware for the Box2 on their [website](https://www.foxeer.com/foxeer-box-2-4k-hd-action-fpv-camera-supervison-g-222#nav-n6) and [Facebook page](https://m.facebook.com/FOXEERTECH/posts/896336937376957?locale2=zh_CN), albeit no new firmwares.
The website has the most recent [firmware](https://download.foxeer.com/BOX_2_Firmware_V1.4_APP_Guide_Manual.zip) version with Android App APK and upgrade manual explaining how to upgrade the firmware.
After downloading multiple firmware versions I unpacked the most recent one I had and to my surprise it seemed fairly easy to change the rootfs and add malicious files.
Firmware file contents:
```bash
-rwxrwxr-x 1 sb sb     871 Nov 27  2018  config
-rwxrwxr-x 1 sb sb 2464821 Jun 24  2019  media_app_zip.bin
-rwxrwxr-x 1 sb sb   60234 Nov 29  2018  mini-u-boot.bin
-rwxrwxr-x 1 sb sb 2478816 Jun 24  2019  miniuImage
-rwxrwxr-x 1 sb sb  125828 Jun 24  2019  paramdef
-rwxrwxr-x 1 sb sb     124 Jun 24  2019  privatefs.jffs2
-rwxrwxr-x 1 sb sb   65536 Jun 24  2019  rawparam
-rwxrwxr-x 1 sb sb   65536 Jun 24  2019  rawparam1
-rwxrwxr-x 1 sb sb  100352 Jul 11  2019 'read me.doc'
-rwxrwxr-x 1 sb sb 7348224 Jun 24  2019  rootfs.squashfs
-rwxrwxr-x 1 sb sb  267816 Nov 23  2018  u-boot.bin
-rwxrwxr-x 1 sb sb    1249 Jun 24  2019  usb-burn.xml
````
#### Firmware file description
**usb-burn.xml**  - firmware burn instructions \
**config**  - u-boot load commands and kernel commandlines \
**u-boot.bin**  - u-boot for the Cortex-A7 \
**miniuImage**  - Linux kernel \
**rootfs.squashfs**  - Linux rootfs \
**privatefs.jffs2**  - Linux writeable fs (no contents) \
**mini-u-boot.bin**  - u-boot for the Cortex-A17 \
**media_app_zip**  - Huawei LiteOs kernel, rootfs and camera application \
**paramdef**  - Camera side settings \
**rawparam**  - Default settings \
**rawparam1**  - Default settings (copy) \

### Reverse engineering the firmware
I scanned all files in the firmware with the tools that I have and found that the easiest way (and most obvious) in would be through the file rootfs.squashfs
```bash
$ file rootfs.squashfs
rootfs.squashfs: Squashfs filesystem, little endian, version 4.0, lzo compressed, 7344204 bytes, 435 inodes, blocksize: 131072 bytes, created: Mon Jun 24 10:00:50 2019
```
```bash
$ binwalk rootfs.squashfs
DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------
0             0x0             Squashfs filesystem, little endian, version 4.0, compression:gzip (non-standard type definition), size: 7344204 bytes, 435 inodes, blocksize: 131072 bytes, created: 2019-06-24 10:00:50
```
```bash
$ unsquashfs -s rootfs.squashfs
Found a valid SQUASHFS 4:0 superblock on rootfs.squashfs.
Creation or last append time Mon Jun 24 12:00:50 2019
Filesystem size 7344204 bytes (7172.07 Kbytes / 7.00 Mbytes)
Compression lzo
Block size 131072
Filesystem is exportable via NFS
Inodes are compressed
Data is compressed
Uids/Gids (Id table) are compressed
Fragments are compressed
Always-use-fragments option is not specified
Xattrs are compressed
Duplicates are removed
Number of fragments 24
Number of inodes 435
Number of ids 4
Number of xattr ids 0
```
Unpacking the file with unsquashfs unfolded the rootfs and made it available for manipulation.
```bash
$ unsquashfs -d _rootfs/ -x rootfs.squashfs
Parallel unsquashfs: Using 4 processors
394 inodes (484 blocks) to write

[================================================================================================================================================================================================|] 484/484 100%

created 257 files
created 41 directories
created 137 symlinks
created 0 devices
created 0 fifos
created 0 sockets
```

### Rootfs
#### Scanning the rootfs for more information
With the rootfs extracted I could now try to find if there is an entrypoint without modifying the firmware.
The file system is pretty straightforward and seems like a default busybox setup.
I used qemu to test the ELF files on my linux box and [exported strings](strings/) to find out more about them.

Busybox itself did not have netcat or telnetd so access was not possible through that.
```bash
BusyBox v1.20.2 (2019-06-14 09:30:16 CST) multi-call binary.

Currently defined functions:
        arp, ash, cat, chmod, chown, cp, cttyhack, date, dd, dhcprelay, diff, dmesg, dumpleases, echo, egrep, false, fdisk, fgrep, find, free, fsync, getty, grep, gunzip, gzip, halt, hd, hexdump, ifconfig,
        init, insmod, ip, ipaddr, iplink, iproute, iprule, iptunnel, kill, killall, killall5, less, ln, login, ls, lsmod, lsof, mesg, mkdir, mkdosfs, mkfs.vfat, mknod, modprobe, more, mount, mv, netstat,
        passwd, ping, pkill, poweroff, printenv, printf, ps, pwd, reboot, rm, rmdir, rmmod, route, sed, sh, sleep, stat, stty, sync, syslogd, tail, telnet, tftp, tftpd, time, touch, true, tty, ubiattach,
        ubidetach, ubimkvol, ubirmvol, ubirsvol, ubiupdatevol, udhcpc, udhcpd, umount, uname, unzip, usleep, vi, wget, zcat
```
The rootfs contained some ELF executable files that were not related to busybox.
***main_app***  - main application daemon
***hostapd***  - wifi daemon
***sharefs***  - file sharing daemon used to share files between the main linux layer and the liteos layer
***btools***  - tool that contains commands to manipulate the memory, video, ddr, l2 cache, extended device and  i2c / spi bus

Being that there seems no obvious and straight forward entrypoint without having to modify the firmware I needed a compatible busybox executable to pack into the firmware.
#### passwd
Examination of the passwd file revealed that the only user on the system is root.
```bash
$ cat passwd
root:$1$$qRPK7m23GJusamGpoGLby/:0:0::/root:/bin/sh
```
The password hash is md5crypt but an online search quickly revealed that this is an empty password hash so no root password is needed.

### Other firmware files
I noticed that there were 2 u-boot files, 1 kernel and 1 rootfs.
This specific HiSilicon chip has two CPUs, a [Cortex-A7](https://en.wikipedia.org/wiki/ARM_Cortex-A7) and a [Cortex-A17](https://en.wikipedia.org/wiki/ARM_Cortex-A17).
The brief [datasheet](docs/Hi3559V100.pdf) states 'Linux+Huawei LiteOS dual-system heterogeneous architecture'.
Interesting, so that means there are two linux systems on this device and there should be two file systems.
After exporting the strings of the **media_app_zip** file it was clear to me that this file contained alle the liteos information.

I have not yet been able to decompile this file for manipulating. Tips are welcome.

## Root access
### Toolchain
Since there was no straightforward entry to the rootfs I needed information to find out what kind of busybox ELF I needed.
```bash
$ file busybox
busybox: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), statically linked, for GNU/Linux 2.6.32, stripped
```
```bash
$ readelf -A busybox
Attribute Section: aeabi
File Attributes
  Tag_CPU_name: "Cortex-A7"
  Tag_CPU_arch: v7
  Tag_CPU_arch_profile: Application
  Tag_ARM_ISA_use: Yes
  Tag_THUMB_ISA_use: Thumb-2
  Tag_FP_arch: VFPv4
  Tag_Advanced_SIMD_arch: NEONv1 with Fused-MAC
  Tag_ABI_PCS_wchar_t: 4
  Tag_ABI_FP_rounding: Needed
  Tag_ABI_FP_denormal: Needed
  Tag_ABI_FP_exceptions: Needed
  Tag_ABI_FP_number_model: IEEE 754
  Tag_ABI_align_needed: 8-byte
  Tag_ABI_align_preserved: 8-byte, except leaf SP
  Tag_ABI_enum_size: int
  Tag_ABI_HardFP_use: Deprecated
  Tag_CPU_unaligned_access: v6
  Tag_MPextension_use: Allowed
  Tag_DIV_use: Allowed in v7-A with integer division extension
  Tag_Virtualization_use: TrustZone and Virtualization Extensions
```
None of the precompiled busybox binaries I had were compatible so I needed the right toolchain.
A simple objdump on one of the proprietary binaries revealed the package name of the toolchain that was used.
```bash
$ objdump -s --section .comment btools

btools:     file format elf32-little

Contents of section .comment:
 0000 4743433a 20284869 73696c69 636f6e5f  GCC: (Hisilicon_
 0010 76363030 5f323031 37303631 35292034  v600_20170615) 4
 0020 2e392e34 20323031 35303632 39202870  .9.4 20150629 (p
 0030 72657265 6c656173 652900             rerelease).
```
Running 'Hisilicon_v600_20170615' through an online search lead me to the [OpenIPC github](https://github.com/OpenIPC/camerasrnd/blob/master/toolchains.md) where if found toolchain name, but for another chip.
Now that I knew the toolchain name (arm-hisiv600-linux) I searched for it in the files from the firmware to confirm it and got multiple hits in the rootfs.
Another online search online lead me to a docker image that contained the toolchain that I needed.
### Busybox
I downloaded the same version used in the rootfs and compiled it with the toolchain obtained from the docker image. It took some trial and error to get it to compile, mostly because the busybox version they used had a bug that needed a patch.
After running ./configure to enable netcat and telnetd plus a static compilation i ran make.
```bash
make ARCH=arm \
CROSS_COMPILE=arm-hisiv600-linux-gnueabi- \
CFLAGS="-mcpu=cortex-a7 -mfloat-abi=softfp -mfpu=vfpv4"
O=../out \
-j 4 
```
This gave me a compatible binary to pack into the firmware.
At first I tried to run the binary from the SD card with a payload script in the rootfs, this did not work because the sd card was mounted with 'no-exec'.
I tried replacing the busybox binary in the firmware, this did not work and the device wouldn't boot anymore.

### Repacking the firmware
What did work was adding the binary to the /bin folder as 'busybox-new'.
In the /app folder in the rootfs there is a shell script named 'bootapp' that is run at boot to start the main application.
I tried adding my payload here but this would just make the device crash.

In the folder /etc/Wireless there is a shell script named 'ap.sh' that is run when the WiFi is enabled with the device buttons.
Herein I added the command to start netcat.
```bash
#ifconfig wlan0 up
#usleep 50000
hostapd -e /etc/Wireless/entropy.bin /app/private/hostapd.conf &
#usleep 50000
#ifconfig wlan0 up
usleep 50000
#ifconfig wlan0 192.168.0.1
ifconfig wlan0 192.168.0.1 netmask 255.255.255.0
route add default gw 192.168.0.1
usleep 50000
udhcpd /etc/Wireless/udhcpd.conf

# netcat payload
/bin/busybox-new nc -nvlp 23 -e /bin/sh &
```
I tried running a telnetd service at first but this did not work because there was no /dev/pts folder and no devpts mountpoint.

To repack the firmware I ran the 'mksquashfs' command with the info I collected earlier to create a new rootfs.squashfs.
```bash 
$ mksquashfs _rootfs rootfs.squashfs -comp lzo -b 131072
Parallel mksquashfs: Using 4 processors
Creating 4.0 filesystem on rootfs.squashfs, block size 131072.
[================================================================================================================================================================================================/] 357/357 100%

Exportable Squashfs 4.0 filesystem, lzo compressed, data block size 131072
        compressed data, compressed metadata, compressed fragments,
        compressed xattrs, compressed ids
        duplicates are removed
Filesystem size 7907.44 Kbytes (7.72 Mbytes)
        47.22% of uncompressed filesystem size (16745.38 Kbytes)
Inode table size 5134 bytes (5.01 Kbytes)
        33.61% of uncompressed inode table size (15276 bytes)
Directory table size 5056 bytes (4.94 Kbytes)
        53.11% of uncompressed directory table size (9520 bytes)
Xattr table size 84 bytes (0.08 Kbytes)
        29.79% of uncompressed xattr table size (282 bytes)
Number of duplicate files found 13
Number of inodes 437
Number of files 258
Number of fragments 24
Number of symbolic links 138
Number of device nodes 0
Number of fifo nodes 0
Number of socket nodes 0
Number of directories 41
Number of ids (unique uids + gids) 1
Number of uids 1
        sb (1000)
Number of gids 1
        sb (1000)
```
### Deploying the modified firmware
Now that I had a modified rootfs I put all the files on an sd card and flashed the device.
After the flashing was finished I rebooted the device and enabled WiFi.
Time to see if we can netcat into the device and find out if we have root access.
```bash
$ nc 192.168.0.1 23
/bin/sh -li
/app # /bin/busybox-new id
uid=0 gid=0
```
***BINGO!***
### socat
Know that nc is very limited and kills itself after disconnect I needed a better way to access the device as root.
I downloaded a socat static binary from [github](https://github.com/therealsaumil/static-arm-bins) and deployed that through the sd card.
Since there was no /dev/pts it needed a few preparation steps through netcat to get it to work:
```bash
mount -o remount,exec /app/sd
mkdir /dev/pts
mount devpts /dev/pts -t devpts
cd /app/sd
./socat TCP-LISTEN:1337,reuseaddr,fork EXEC:/bin/sh,pty,stderr,setsid,sigint,sane &
```
On my linux laptop:
```bash
socat FILE:`tty`,raw,echo=0 TCP:192.168.0.1:1337
```
And there we have it, a reusable root access connection for as long as the device is on.
I did not make this persistent as it needed the socat binary and the memory space in the firmware was full.
Ofcourse I could have replaced the compiled busybox binary with the socat binary but I didnt need it to be persistent.
Now that I had root access I could go and explore the device to try and get access to the gyro.

## Huawei LiteOS
### media_app
The media_app file runs the camera side of the device. By examining the strings in this file I know that this part of the device also controls the gyro.
Since I have not been able to get access to this part of the device nor have I been able to unpack this file into a rootfs I have run into a wall.

### Gyro - BMI160
#### datasheet
I downloaded the BMI160 datasheet from the [Bosch-Sensortech website](https://www.bosch-sensortec.com/media/boschsensortec/downloads/datasheets/bst-bmi160-ds000.pdf) to learn more about the device, it is able to communicate with I2C and SPI
#### access
Unfortunatly I have not been able to gain access to the gyro and have put this part project on hold for now.
The tools available on the linux rootfs to communicate through i2c and spi did not give me access to the gyro and my guess is that its not accessible from the linux side.
I downloaded [i2c-tools](https://github.com/mozilla-b2g/i2c-tools) and cross compiled that to use i2cdetect, but unfortunatly the i2c bus did not have detection enabled.

## SDK
### proprietary
The HiSilicon SDK's are not opensource and are not freely available online. There are ofcourse ways to get access to these SDKs if one searches online.
I managed to get an SDK that gave me more information about how the two Cortex cores communicate with each other.
The first SDK that I got turned out the for the Hi3559A version of the chip. This chip is 64bit and the one in this device is 32bit.
Another quest through several Chinese websites lead me back to a link on an English forum with a link to almost the right SDK _Hi3559V100R003_SDK_V2.0.0.9_, only the version was off.
### ipcm
The SDK contains multiple parts and one of them is 'osdrv'. The 'osdrv' contains a components folder with 'sharefs' and 'ipcm'. 
Outtake from the ipcm readme: _The Inter-Processor Communication Module (IPCM) is used for communication among multiple cores._

The rootfs contains scripts to enable the network part of the ipcm and enabling this would work just fine except for the access part.
I kept running in circles when trying to work this out and came up empty handed.
This must be the way to get access to the gyro but I have run out of time to dig deeper into this.

## Other
### Modifying the WiFi and IP-address
Every attempt on modifying WiFi and IP settings made the device not accessible.
The WiFi would turn on but it would not be possible to connect to it.
Most of the settings are hardcoded into the system and the parameters.
### Enabling network over USB
The rootfs contains scripts to enable network over USB.
After enabling and connecting the usb to my pc a RNDIS (Remote Network Driver Interface Specification) device would appear.
Although it seems to add a network, no network connection would be possible.
I tried connecting the usb to my linux laptop and it would also add an ACM device, no information came on screen after connecting though.
### portscan
I created a simple [bash script](scripts/port.sh) to scan the ports of the IPCM network device. For this I also needed a static bash binary, fortunatly this is available on [Github](https://github.com/DethByte64/Bash-for-ARM).
The portscan came up empty and so another deadend.
### exports and logs
I exported the contents of dmesg and multiple linux files into text files.
For easy research I created a [bash script](scripts/fullcat.sh) to export the contents of multiple files at once into a text file.
All exports I made are available in the [exports](exports/) folder.
### strings
I exported strings from multiple files, these are available in the [strings](strings/) folder.