# BeagleBone Green Wireless Embedded Linux Build Guide

## Brief Introduction

This guide tutors how to build the embedded Linux operating system for the BeagleBone Green Wireless board.

## Implementation

### Development Environment

Set up the development environment using Ubuntu 18.04:

-   Create the project folders:

```sh
$ mkdir -p beaglelfs/{sources,rootfs_install,boot_mnt,rootfs_mnt}
$ cd beaglelfs/sources
```

-   Download all sources:

```sh
$ wget –c https://releases.linaro.org/components/toolchain/binaries/latest-7/arm-linux-gnueabihf/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf.tar.xz
$ wget –c https://github.com/u-boot/u-boot/archive/refs/tags/v2021.04-rc5.zip
$ wget –c https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.4.264.tar.xz
$ wget –c https://busybox.net/downloads/busybox-1.31.1.tar.bz2
```

-   Decompress all sources:

```sh
$ tar -xjf gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf.tar.xz
$ tar -xjf v2021.04-rc5.zip
$ tar -xjf linux-4.4.264.tar.xz
$ tar -xjf busybox-1.31.1.tar.bz2
```

-   Export `PATH`:

```sh
$ export PATH=$PWD/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf/bin:$PATH
```

### Build U-boot

Use these commands:

```sh
$ cd v2021.04-rc5/u-boot-2021.04-rc5/
$ make -j20 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- distclean
$ make -j20 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- am335x_evm_config
$ make -j20 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-
```

### Build Linux

Use these commands:

```sh
$ cd ../../linux-4.4.264
$ make -j20 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- distclean
$ make -j20 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- multi_v7_defconfig
$ make -j20 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- all
$ make -j20 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=/path/to/beaglelfs/rootfs_install modules_install
```

### Build Busybox

Use these commands:

```sh
$ cd ../busybox-1.31.1
$ make -j20 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- distclean
$ make -j20 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- defconfig
$ make -j20 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- menuconfig
```

In the `menuconfig`, enable `Settings > Build Options > Build static binary (no shared libs)`.

```sh
$ make -j20 ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- install
$ rsync -a _install/ ../../rootfs_install/
```

### Create Root File System

Use these commands:

```sh
$ cd ../../rootfs_install
```

```sh
$ mkdir dev
$ sudo mknod dev/console c 5 1
$ sudo mknod dev/null c 1 3
```

```sh
$ mkdir etc
$ cat >> etc/inittab
null::sysinit:/bin/mount -t proc proc /proc
null::sysinit:/bin/hostname -F /etc/hostname
null::respawn:/sbin/getty -L ttyO0 115200 vt100
null::shutdown:/sbin/mount -a -r
^D
```

```sh
$ mkdir proc
$ mkdir root
$ cat >> etc/passwd
root:x:0:0:root:/root:/bin/sh
^D
$ cat >> etc/shadow
root::10933:0:99999:7:::
^D
```

```sh
$ mkdir -p usr/share/udhcpc
$ cp ../sources/busybox-1.31.1/examples/udhcp/simple.script usr/share/udhcpc/default.script
$ cat >> etc/hostname
beaglegreen
^D
```

### Create SD Image

Use these commands:

```sh
$ cd ..
$ dd if=/dev/zero of=sdcard.img bs=1M count=128
$ echo "Cylinders: " `du -b sdcard.img | awk '{print int($1/255/63/512)}'`
$ fdisk sdcard.img
```

Select these options:

```sh
x ⏎                     # select expert mode
h ⏎ 255 ⏎               # set heads to 255
s ⏎ 63 ⏎                # set sectors to 63
c ⏎ 63 ⏎                # set cylinders to 63
r ⏎                     # return to normal mode
n ⏎ p ⏎ 1 ⏎ ⏎ +16M ⏎    # new partition: primary, number 1, default first sector, +16M size
t ⏎ c ⏎                 # set type of partition with code: c (W95 FAT32 LBA)
a ⏎                     # mark bootable partition number 1
n ⏎ p ⏎ 2 ⏎ ⏎ ⏎         # new partition: primary, number 2, default first sector, default full size
w ⏎                     # write the partition table
```

```sh
$ sudo modprobe loop
$ sudo losetup /dev/loop999 sdcard.img
$ sudo kpartx -av /dev/loop999
$ sudo mkfs.vfat -F 16 -n "boot" /dev/mapper/loop999p1
$ sudo mkfs.ext4 -L "rootfs" /dev/mapper/loop999p2
```

```sh
$ cd /path/to/beaglelfs/
$ sudo mount /dev/mapper/loop999p1 boot_mnt
$ sudo mount /dev/mapper/loop999p2 rootfs_mnt
$ sudo cp sources/v2021.04-rc5/u-boot-2021.04-rc5/MLO boot_mnt/
$ sudo cp sources/v2021.04-rc5/u-boot-2021.04-rc5/u-boot.img boot_mnt/
$ sudo cp sources/linux-4.4.264/arch/arm/boot/zImage boot_mnt/
$ sudo cp sources/linux-4.4.264/arch/arm/boot/dts/am335x-bone*.dtb boot_mnt/
```

```sh
$ cat >> uEnv.txt
bootdir=
bootfile=zImage
fdtfile=am335x-bonegreen.dtb
loadaddr=0x80007fc0
fdtaddr=0x80F80000
loadfdt=fatload mmc 0:1 ${fdtaddr} ${fdtfile}
loaduimage=fatload mmc 0:1 ${loadaddr} ${bootfile}
mmc_args=setenv bootargs console=ttyO0,115200n8 ${optargs}
root=/dev/mmcblk0p2 rw rootfstype=ext4 rootwait
uenvcmd=mmc rescan; run loaduimage; run loadfdt; run fdtboot
fdtboot=run mmc_args; bootz ${loadaddr} - ${fdtaddr}
^D
```

```sh
$ sudo cp uEnv.txt boot_mnt/
$ sudo umount boot_mnt
$ sudo rsync -a rootfs_install/ rootfs_mnt/
$ sudo chown -R root:root rootfs_mnt/*
$ sudo umount rootfs_mnt
$ sudo kpartx -d /dev/loop999
$ sudo losetup -d /dev/loop999
```

### Load To SD Card

Find the SD partition (sdcardblockdevice) using the command `lsblk` and run this command:

```sh
$ sudo dd if=sdcard.img of=/dev/sdcardblockdevice bs=1M
```

> [!NOTE]
> Default username is `root` with no password.

## References

-   [Building for BeagleBone](https://elinux.org/Building_for_BeagleBone)
-   [Busybox "Embedded Linux from Scratch" Distribution for the Beaglebone](https://gist.github.com/vsergeev/2391575)
