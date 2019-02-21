#!/bin/bash
export LANG=C.UTF-8
MIRROR_HOST=${MIRROR_HOST:-http://deb.debian.org/debian/}

# Disk info
IMAGE_FILE=${IMAGE_FILE:-disk.qcow2}
IMAGE_SIZE=${IMAGE_SIZE:-$((1024*1024*1024*10))} # 10G
SYSIMG_SIZE=${SYSIMG_SIZE:-$((4096*512))}
MAIN_UUID=${MAIN_UUID:-27428078-ba16-45d5-8338-47e105b4fc7c}

# Directory
WORKSPACE=/workspace
TARGET_DIR=/mnt/target

# Device
DEVID=${DEVID:-7}
LOOP_DEV=/dev/loop$(($DEVID+1))
NBD_DEV=/dev/nbd$DEVID

# Load devices
losetup -D
if [[ ! -e /dev/loop$DEVID ]]; then
  mknod /dev/loop$DEVID b 7 $DEVID
fi
if [[ ! -e $LOOP_DEV ]]; then
  mknod $LOOP_DEV b 7 $DEVID
fi
if [[ ! -e $NBD_DEV ]]; then
  mknod $NBD_DEV -m660 b 43 $DEVID
fi


# WORKSPACE
cd "$WORKSPACE"
