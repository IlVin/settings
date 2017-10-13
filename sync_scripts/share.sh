#!/bin/sh

# требуется модуль dm-snapshot
sudo modprobe dm-snapshot

DST="mirror_share"

if [ -e /dev/mpool/$DST\_snap ]
then
    sudo umount -f /mnt/snap/$DST && true
    sudo lvremove -f /dev/mpool/$DST\_snap
fi

sudo lvcreate -vs /dev/mpool/$DST -L 2G -n $DST\_snap
sudo mkdir -p /mnt/snap/$DST
sudo mount -o ro /dev/mpool/$DST\_snap /mnt/snap/$DST

sudo nice -n 20 rsync -av --delete --checksum /mnt/share/home /mnt/$DST/
sudo nice -n 20 rsync -av --delete --checksum /mnt/share/share /mnt/$DST/

sudo umount -f /mnt/snap/$DST && true
sudo lvremove -f /dev/mpool/$DST\_snap

