do_disk_to_pool () # disk, vg_name, lv_names
{
    local DISK="$1"
    local VG="$2"
    local LVS="$3"
    local SPPOOL="sp_$VG_NAME"

    echo "DISK=$DISK; VG=$VG; SPPOOL=$SPPOOL; LVS=$LVS"

    # Create phisical volumes
    sudo pvcreate $DISK
    sudo sync $DISK

    # Create volume groups
    sudo vgcreate $VG $DISK
    sudo sync $DISK

    # Create a thin pools
    SIZE=`sudo vgs -o vg_free_count --rows $VG | awk '{ print $2 }'`

    sudo lvcreate -L $SIZE -T $VG/$SPPOOL
    sudo sync $VG/$SPPOOL

    for $LV in $LV_NAMES
    do
        sudo lvcreate -V $SIZE -T $VG/$SSPOOL -n $LV
        sudo sync /dev/$VG/$LV
    done
}

do_disk_to_pool("/dev/sda", "share", "share dlna")
do_disk_to_pool("/dev/sdb", "mirror", "share dlna")

