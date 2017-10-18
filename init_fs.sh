
sudo apt-get update -y
sudo apt-get install -y lvm2
sudo apt-get install -y thin-provisioning-tools

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
        sudo mkdir -p /mnt/$VG_NAME/$LV
        sudo mkdir -p /mnt/snapshots/$VG_NAME/$LV
        sudo sh -c "echo '/dev/$VG/$LV /mnt/$VG_NAME/$LV ext4 errors=remount-ro 0 0' >> /etc/fstab"
        sudo mount /mnt/$VG_NAME/$LV
    done
}

#do_disk_to_pool "/dev/sda" "data" "homes share dlna backup"
#do_disk_to_pool "/dev/sdb" "mirror" "homes share dlna backup"
