do_disk_to_pool () # disk, vg_name, lv_names
{
    local DISK="$1"
    local VG_NAME="$2"
    local LV_NAMES="$3"

    local VG="vg_$VG_NAME"
    local LVP="lvp_$VG_NAME"

    # Create phisical volumes
    sudo pvcreate $DISK

    # Create volume groups
    sudo vgcreate $VG $DISK

    # Create a thin pools
    SIZE=`sudo vgs -o vg_free_count --rows $VG | awk '{ print $2 }'`

    sudo lvcreate -L $SIZE -T $VG/$LVP

    for LV in $LV_NAMES
    do
        sudo lvcreate -V $SIZE -T $VG/$LVP -n $LV
        sudo mkfs -t ext4 /dev/$VG/$LV
        sudo sync /dev/$VG/$LV
    done
}

do_disk_to_pool "/dev/sda" "data" "share dlna"
do_disk_to_pool "/dev/sdb" "mirror" "share dlna"

