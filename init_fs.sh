
SDISK='/dev/sda'
MDISK='/dev/sdb'

SVG='sgroup'
MVG='mgroup'

SPOOL='spool'
MPOOL='mpool'

SLVSHARE='sshare'
SLVDLNA='sdlna'
MLVSHARE='mshare'
MLVDLNA='mdlna'

# Create phisical volumes
sudo pvcreate $SDISK
sudo pvcreate $MDISK
sudo sync $SDISK
sudo sync $MDISK

# Create volume groups
sudo vgcreate $SVG $SDISK
sudo vgcreate $MVG $MDISK
sudo sync $SDISK
sudo sync $MDISK

# Create a thin pools
SSIZE=`sudo vgs -o vg_free_count --rows $SVG | awk '{ print $2 }'`
MSIZE=`sudo vgs -o vg_free_count --rows $MVG | awk '{ print $2 }'`
sudo lvcreate -L $SSIZE -T $SVG/$SPOOL
sudo lvcreate -L $MSIZE -T $MVG/$MPOOL

# Create logical volume
sudo lvcreate -V $SSIZE -T $SVG/$SPOOL -n $SLVSHARE
sudo lvcreate -V $SSIZE -T $SVG/$SPOOL -n $SLVDLNA

sudo lvcreate -V $MSIZE -T $MVG/$MPOOL -n $MLVSHARE
sudo lvcreate -V $MSIZE -T $MVG/$MPOOL -n $MLVDLNA

sudo sync /dev/$SVG/$SLVSHARE
sudo sync /dev/$SVG/$SLVDLNA

sudo sync /dev/$MVG/$MLVSHARE
sudo sync /dev/$MVG/$MLVDLNA

# Create file systems
sudo mkfs -t ext4 /dev/$SVG/$SLVSHARE
sudo mkfs -t ext4 /dev/$SVG/$SLVDLNA

sudo mkfs -t ext4 /dev/$MVG/$MLVSHARE
sudo mkfs -t ext4 /dev/$MVG/$MLVDLNA

sudo sync /dev/$SVG/$SLVSHARE
sudo sync /dev/$SVG/$SLVDLNA

sudo sync /dev/$MVG/$MLVSHARE
sudo sync /dev/$MVG/$MLVDLNA


