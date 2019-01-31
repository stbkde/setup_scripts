echo "Base setup script for hserv (Thinkpad T60)"

read -p "Continue and format the disc? [Y/n]: " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo ""
    echo "Preparing setup..."
    pacman -Sy reflector
    mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
    reflector -c Germany -f 10 -p http --save /mnt/etc/pacman.d/mirrorlist
    timedatectl set-ntp true
    pacman --noconfirm -Sy git

    echo ""
    echo "Partition the hard drive"
    parted /dev/sda --script -- mklabel dos
    # /dev/sda1 - root/boot
    parted /dev/sda --script -- mkpart primary ext4 1MiB 25.0GiB
    parted /dev/sda --script -- set 1 boot on
    # /dev/sda2 - swap
    parted /dev/sda --script -- mkpart primary linux-swap 25.0GiB 33.0GiB
    # /dev/sda3 - home
    parted /dev/sda --script -- mkpart primary 33.0GiB 100%

    echo ""
    echo "Make filesystems p_arch and p_home"
    mkfs.ext4 -q -L p_arch /dev/sda1
    mkfs.btrfs -q -L p_home /dev/sda3
    
    echo ""
    echo "Configuring swap..."
    mkswap -L p_swap /dev/sda2
    swapon -L p_swap
    
    echo ""
    echo "Mounting filesystems..."
    # root
    mount /dev/sda1 /mnt

    # home
    mkdir /mnt/home
    mount /dev/sda3 /mnt/home
        
    echo ""
    echo "Installation of base system is running..."
    pacstrap /mnt base base-devel
    
    genfstab -U /mnt >> /mnt/etc/fstab
    
    cp /root/setup_scripts/hserv_setup_chroot.sh /mnt/root/hserv_setup_chroot.sh 
    arch-chroot /mnt sh /root/hserv_setup_chroot.sh 
        
    echo "***** DONE! ******"
    echo "Rebooting in 30 seconds"
    sleep 30
    
    echo "Unmounting partitions..."
    umount -R /mnt/boot
    umount -R /mnt
    
    reboot
fi
