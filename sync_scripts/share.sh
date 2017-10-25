#!/bin/bash

# требуется модуль dm-snapshot
sudo modprobe dm-snapshot


do_rsync () # snap_name, src_path, dst_path
{
    local SNAP_NAME=$1
    local SRC_PATH=$2
    local DST_PATH=$3

    local SNAP_PATH="${SNAP_NAME}-autosnap"
    local LOG_PATH="${SRC_PATH}/logs/${SNAP_NAME}_rsync.log"

    local RSYNC_CMD="sudo nice -n 20 rsync --verbose --log-file=${LOG_PATH} --ignore-times --human-readable --inplace --copy-links --copy-dirlinks --perms --executability --xattrs --owner --group --times --recursive --exclude=lost+found --exclude=logs --delete --checksum ${SRC_PATH}/ ${DST_PATH}/"

    SRC_LV_PATH=$(/bin/grep "${SRC_PATH}" /etc/fstab|/usr/bin/awk '{ print $1 }')
    DST_LV_PATH=$(/bin/grep "${DST_PATH}" /etc/fstab|/usr/bin/awk '{ print $1 }')

    echo "SRC_LV_PATH: ${SRC_LV_PATH}"
    echo "DST_LV_PATH: ${DST_LV_PATH}"

    echo "RSYNC: ${RSYNC_CMD}"

    eval ${RSYNC_CMD}
}

NAME=`date -u +GMT-%Y.%m.%d-%H.%M.%S`

do_rsync  ${NAME} "/mnt/data/share" "/mnt/mirror/share"
do_rsync  ${NAME} "/mnt/data/homes" "/mnt/mirror/homes"
do_rsync  ${NAME} "/mnt/data/dlna" "/mnt/mirror/dlna"

exit
DSTPOOL="/dev/mpool"
DSTLVNAME="mirror_$NAME"
DSTLVPATH="$DSTPOOL/$DSTLVNAME"

SNAPPATH="/mnt/snap/mirror/$NAME/"
SNAPLVNAME="snap_mirror_$NAME"
SNAPLVPATH="$DSTPOOL/$SNAPLVNAME"

LOGPATH="/var/log/rsync_backup_log"

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

CMD="date '+%Y/%m/%d %H:%M:%S [$$] START_BACKUP $SRCPATH $DSTPATH $SNAPPATH' > $LOGPATH"
sudo sh -c "$CMD"
sudo nice -n 20 rsync --verbose --log-file=$LOGPATH --ignore-times --human-readable --inplace --copy-links --copy-dirlinks --perms --executability --xattrs --owner --group --times --recursive --exclude=lost+found --delete --checksum $SRCPATH $DSTPATH

sudo umount -f $SNAPPATH && true
sudo lvremove -f $SNAPLVPATH

