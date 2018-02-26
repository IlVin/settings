#!/bin/bash

# требуется модуль dm-snapshot
sudo modprobe dm-snapshot

LOG_PATH="/mnt/data/logs/backup.log"

function log () # message
{
    local MESSAGE=$1

    echo ">>> ${MESSAGE}"
}

function do_rsync () # schadow_copy_name, folder_name
{
    local SHADOW_SOPY_NAME=$1
    local FOLDER_NAME=$2

    local SRC_PATH="/mnt/data/$FOLDER_NAME"
    local DST_PATH="/mnt/mirror/$FOLDER_NAME"
    local LOG_PATH="/mnt/data/logs/${FOLDER_NAME}/${SHADOW_COPY_NAME}_rsync.log"

    local SNAP_PATH="${SHADOW_COPY_NAME}-autosnap"

    #local RSYNC_CMD="sudo nice -n 20 rsync -Epogt --checksum --log-file=${LOG_PATH} --partial --human-readable --inplace --copy-links --copy-dirlinks --recursive --exclude=lost+found --delete --no-whole-file ${SRC_PATH}/ ${DST_PATH}/"
    local RSYNC_CMD="sudo nice -n 20 rsync -Epogt --log-file=${LOG_PATH} --partial --human-readable --inplace --copy-links --copy-dirlinks --recursive --exclude=lost+found --delete --no-whole-file ${SRC_PATH}/ ${DST_PATH}/"

    log "RSYNC: ${RSYNC_CMD}"

    eval ${RSYNC_CMD}
}

function do_snapshot () # schadow_copy_name, folder_name
{
    local SHADOW_COPY_NAME=$1
    local FOLDER_NAME=$2

    local SRC_PATH="/mnt/data/$FOLDER_NAME"
    local SRC_SNAP_PATH="/mnt/data/.$FOLDER_NAME/${SHADOW_COPY_NAME}"
    local DST_PATH="/mnt/mirror/$FOLDER_NAME"
    local DST_SNAP_PATH="/mnt/mirror/.$FOLDER_NAME/${SHADOW_COPY_NAME}"

    local LOG_PATH="/mnt/data/logs/${FOLDER_NAME}/${SHADOW_COPY_NAME}_snapshot.log"

    SRC_LV_PATH=$(/bin/grep "${SRC_PATH}" /etc/fstab|/usr/bin/awk '{ print $1 }')
    DST_LV_PATH=$(/bin/grep "${DST_PATH}" /etc/fstab|/usr/bin/awk '{ print $1 }')

    log "SRC_LV_PATH: ${SRC_LV_PATH}"
    log "DST_LV_PATH: ${DST_LV_PATH}"
    log "SRC_SNAP_PATH: ${SRC_SNAP_PATH}"
    log "DST_SNAP_PATH: ${DST_SNAP_PATH}"
}

SHADOW_COPY_NAME=`date -u +GMT-%Y.%m.%d-%H.%M.%S`

do_rsync  ${SHADOW_COPY_NAME} "share"
do_rsync  ${SHADOW_COPY_NAME} "homes"
do_rsync  ${SHADOW_COPY_NAME} "dlna"

do_snapshot ${SHADOW_COPY_NAME} "share"

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

