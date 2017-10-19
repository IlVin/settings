
sudo apt-get update -y
sudo apt-get install -y lvm2
sudo apt-get install -y thin-provisioning-tools

# Remove prevision init
# sudo umount /mnt/data/* /mnt/mirror/* && sudo vgremove -y vg_data vg_mirror && sudo rm -rf /mnt/* && sudo vim /etc/fstab

do_disk_to_pool () # disk, vg_name, lv_name, mount_opts
{
    local DISK="$1"
    local VG_NAME="$2"
    local LV_NAMES="$3"
    local MOUNT_OPTS="$4"

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
        sudo chown ilvin:ilvin /mnt/$VG_NAME/$LV
        sudo chmod g+s /mnt/$VG_NAME/$LV

        sudo mkdir -p /mnt/snapshots/$VG_NAME/$LV
        sudo chown ilvin:ilvin /mnt/snapshots/$VG_NAME/$LV
        sudo chmod g+s /mnt/snapshots/$VG_NAME/$LV

        sudo sh -c "echo '/dev/$VG/$LV /mnt/$VG_NAME/$LV ext4 $MOUNT_OPTS 0 0' >> /etc/fstab"

        sudo mount /mnt/$VG_NAME/$LV
        sudo chown ilvin:ilvin /mnt/$VG_NAME/$LV
        sudo chmod g+s /mnt/$VG_NAME/$LV
    done
}

#do_disk_to_pool "/dev/sdb" "data" "homes share dlna" "rw,errors=remount-ro,noatime,noexec,async,suid"
#do_disk_to_pool "/dev/sda" "mirror" "homes share dlna" "rw,errors=remount-ro,noatime,noexec,async,suid"
