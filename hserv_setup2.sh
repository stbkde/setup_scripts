echo "Before starting this script: "
echo "$ arch-chroot /mnt"

read -p "Continue and format the whole disc? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo ""
    echo "Installing base packages..."
    pacman -Sy dosfstools gptfdisk btrfs-progs netctl curl wget git avahi python3 uriparser nmap python-pip mc elinks htop
    
    echo ""
    echo "Setting location and timezone..."
    # nano /etc/locale.gen
    ## uncomment
        #de_DE.UTF-8 UTF-8
        #de_DE ISO-8859-1
        #de_DE@euro ISO-8859-15
    
    echo LANG=de_DE.UTF-8 > /etc/locale.conf
    locale-gen
    ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
    hwclock --systohc

    echo "KEYMAP=de-latin1" > /etc/vconsole.conf
    echo "FONT=lat9w-16" >> /etc/vconsole.conf

    echo ""
    echo "Setting hostname..."
    echo hserv > /etc/hostname

    echo "127.0.0.1	      localhost" >> /etc/hosts
    echo "::1	          localhost" >> /etc/hosts
    echo "127.0.1.1	      hserv.local	hserv" >> /etc/hosts
    echo "" >> /etc/hosts
    echo "185.228.138.42  io" >> /etc/hosts
    
    echo ""
    echo "Installing bootloader..."
    pacman -S grub-bios
    grub-install /dev/sda
    
    echo ""
    echo "Create kernel..."
    mkinitcpio -p linux

    echo ""
    echo "Setting up the bootloader..."
    grub-mkconfig -o /boot/grub/grub.cfg
    genfstab -U /mnt >> /mnt/etc/fstab
    
    echo ""
    echo "Fast geschafft!"
    echo "Please a password for root:"
    passwd
fi
