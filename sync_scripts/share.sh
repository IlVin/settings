#!/bin/sh


# требуется модуль dm-snapshot
sudo modprobe dm-snapshot

NAME="share"

SRCPATH="/mnt/$NAME/"

DSTPATH="/mnt/mirror/$NAME/"
DSTPOOL="/dev/mpool"
DSTLVNAME="mirror_$NAME"
DSTLVPATH="$DSTPOOL/$DSTLVNAME"

SNAPPATH="/mnt/snap/mirror/$NAME"
SNAPLVNAME="snap_mirror_$NAME"
SNAPLVPATH="$DSTPOOL/$SNAPLVNAME"


if [ -e $SNAPLVPATH ]
then
    sudo umount -f $SNAPPATH && true
    sudo lvremove -f $SNAPLVPATH
fi

sudo lvcreate -vs $DSTLVPATH -L 2G -n $SNAPLVNAME
sudo mkdir -p $SNAPPATH
sudo mount -o ro $SNAPLVPATH $SNAPPATH

echo "mod" >> /mnt/share/home/ilvin/mod.txt
echo "mod" >> /mnt/share/home/ilvin/mod2.txt
echo "mod" >> /mnt/share/home/ilvin/mod3.txt
rm -f /mnt/mirror/share/home/ilvin/mod2.txt
echo "mod3" >> /mnt/mirror/share/home/ilvin/mod3.txt
echo "mod4" >> /mnt/mirror/share/home/ilvin/mod4.txt

CMD="date '+%Y/%m/%d %H:%M:%S [0000] START BACKUP: $SRCPATH => $DSTPATH' >> /var/log/rsync_log"
echo $CMD
sudo sh -c "$CMD"
sudo nice -n 20 rsync --verbose --log-file=/var/log/rsync_log --ignore-times --human-readable --inplace --copy-links --copy-dirlinks --perms --executability --xattrs --owner --group --times --recursive --exclude=lost+found --delete --checksum $SRCPATH $DSTPATH

sudo umount -f $SNAPPATH && true
sudo lvremove -f $SNAPLVPATH

