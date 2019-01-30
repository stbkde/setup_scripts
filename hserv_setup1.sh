echo "Base setup script for hserv (Thinkpad T60)"

read -p "Continue and format the whole disc? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo ""
    echo "Preparing setup..."
    timedatectl set-ntp true
    pacman -Sy git

    echo ""
    echo "Partition the hard drive"
    parted /dev/sda --script -- mklabel gpt

    parted /dev/sda --script -- mkpart primary ext4 1MiB 25GiB
    parted /dev/sda --script -- set 1 boot on
    parted /dev/sda --script -- mkpart primary linux-swap 25.5GiB 33.5GiB
    parted /dev/sda --script -- mkpart primary 28.5GiB 100%

    echo ""
    echo "Make filesystems p_arch and p_home"
    mkfs.ext4 -L p_arch /dev/sda2
    mkfs.btrfs -L p_home /dev/sda3
    
    echo ""
    echo "Configuring swap..."
    mkswap -L p_swap /dev/sda1
    swapon -L p_swap
    
    echo ""
    echo "Mounting filesystems..."
    # root
    mount /dev/sda2 /mnt

    # home
    mkdir /mnt/home
    mount /dev/sda3 /mnt/home
    
    mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
    grep -E -A 1 ".*Germany.*$" /etc/pacman.d/mirrorlist.bak | sed '/--/d' > /etc/pacman.d/mirrorlist
    
    cp hserv_setup2.sh /mnt/root/
    
    echo ""
    echo "Installation of base system is running..."
    pacstrap /mnt base base-devel
    
    
    echo ""
    echo "Base installation done!"
    echo "Now enter:" 
    echo "'arch-chroot /mnt'"
    echo "and run setup part 2 with:"
    echo "'sh hserv_setup2.sh'"
fi
