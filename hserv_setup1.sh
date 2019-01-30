echo "Base setup script for hserv (Thinkpad T60)"

read -p "Continue and format the disc? [Y/n]: " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo ""
    echo "Preparing setup..."
    timedatectl set-ntp true
    pacman --noconfirm  -Sy git

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
        
    echo ""
    echo "Installation of base system is running..."
    pacstrap /mnt base base-devel
    
    echo ""
    echo "Installing base packages..."
    arch-chroot /mnt pacman --noconfirm  -Sy openssh dosfstools unrar gptfdisk btrfs-progs netctl curl wget git avahi python3 uriparser nmap python-pip mc elinks htop
    
    arch-chroot /mnt systemctl enable sshd.service
    
    echo ""
    echo "Setting location and timezone..."
    arch-chroot /mnt sed -i 's/^#de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen
    arch-chroot /mnt sed -i 's/^#de_DE ISO-8859-1/de_DE ISO-8859-1/' /etc/locale.gen
    arch-chroot /mnt sed -i 's/^#de_DE@euro ISO-8859-15/de_DE@euro ISO-8859-15/' /etc/locale.gen
    arch-chroot /mnt locale-gen
    
    # Set timezone
    arch-chroot /mnt timedatectl --no-ask-password set-timezone Europe/Berlin

    # Set NTP clock
    arch-chroot /mnt timedatectl --no-ask-password set-ntp 1

    # Set locale
    arch-chroot /mnt localectl --no-ask-password set-locale LANG="de_DE.UTF-8" LC_COLLATE="C" LC_TIME="de_DE.UTF-8"
    
    arch-chroot /mnt echo 'LANG=de_DE.UTF-8' > /etc/locale.conf
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
    arch-chroot /mnt hwclock --systohc
    arch-chroot /mnt timedatectl set-ntp true
    arch-chroot /mnt localectl --no-ask-password set-keymap de
    #arch-chroot /mnt localectl --no-convert set-x11-keymap us,us pc104 ,intl grp:caps_toggle

    arch-chroot /mnt echo "KEYMAP=de-latin1" > /etc/vconsole.conf
    arch-chroot /mnt echo "FONT=lat9w-16" >> /etc/vconsole.conf

    arch-chroot /mnt hostnamectl --no-ask-password set-hostname 'hserv'

    echo ""
    echo "Setting hostname..."
    arch-chroot /mnt echo 'hserv' > /etc/hostname
    
    # Disable PC speaker beep
    arch-chroot /mnt echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf

    arch-chroot /mnt echo "127.0.0.1      localhost"         >> /etc/hosts
    arch-chroot /mnt echo "::1            localhost"         >> /etc/hosts
    arch-chroot /mnt echo "127.0.1.1      hserv.local hserv" >> /etc/hosts
    arch-chroot /mnt echo ""                                 >> /etc/hosts
    arch-chroot /mnt echo "185.228.138.42 io"                >> /etc/hosts
    
    echo ""
    echo "Installing bootloader..."
    arch-chroot /mnt pacman --noconfirm -S grub-bios
    arch-chroot /mnt grub-install /dev/sda
    
    echo ""
    echo "Create kernel..."
    arch-chroot /mnt mkinitcpio -p linux

    echo ""
    echo "Setting up the bootloader..."
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
    arch-chroot /mnt genfstab -U /mnt >> /mnt/etc/fstab
    
    echo ""
    echo "Setting up network connection..."
    arch-chroot /mnt echo "Interface=enp1s0" > /etc/netctl/ethernet-dhcp
    arch-chroot /mnt echo "Connection=ethernet" >> /etc/netctl/ethernet-dhcp
    arch-chroot /mnt echo "IP=static" >> /etc/netctl/ethernet-dhcp
    arch-chroot /mnt echo "#Address=('10.1.10.2/24')" >> /etc/netctl/ethernet-dhcp
    arch-chroot /mnt echo "#Gateway='10.1.10.1'" >> /etc/netctl/ethernet-dhcp
    arch-chroot /mnt echo "#DNS=('10.1.10.1')" >> /etc/netctl/ethernet-dhcp
    
    arch-chroot /mnt netctl start ethernet-dhcp
    arch-chroot /mnt netctl enable ethernet-dhcp
    
    echo ""
    echo "Creating users..."
    arch-chroot /mnt useradd -m -g users,wheel -s /bin/bash stephan
    arch-chroot /mnt passw stephan
    arch-chroot /mnt echo "stephan   ALL=(ALL) ALL" >> /etc/sudoers
    
	#echo "$username:$password" | chpasswd
	#chsh -s /bin/zsh $username
    # Add sudo no password rights
    #sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
    # Remove no password sudo rights
    #sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
    # Add sudo rights
    #sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

    echo ""
    echo ""
    echo "Please enter a password for root:"
    arch-chroot /mnt passwd
    
    
    echo "Unmounting partitions..."
    umount -R /mnt/boot
    umount -R /mnt
    
    echo "***** DONE! ******"
    
    reboot
fi
