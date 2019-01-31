echo "Before starting change to root on /mnt: "
echo "» arch-chroot /mnt"

read -p "Continue with setup? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    pacman --noconfirm -Sy reflector
    echo ""
    echo "Installing base packages..."
    #mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
    #reflector -c Germany -f 10 -p http --save /etc/pacman.d/mirrorlist
   
    pacman --noconfirm -Sy openssh dosfstools unrar gptfdisk btrfs-progs netctl curl wget git avahi python3 uriparser nmap python-pip mc elinks htop
    systemctl enable sshd.service
    
    echo ""
    echo "Setting location and timezone..."
    sed -i 's/^#de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen
    sed -i 's/^#de_DE ISO-8859-1/de_DE ISO-8859-1/' /etc/locale.gen
    sed -i 's/^#de_DE@euro ISO-8859-15/de_DE@euro ISO-8859-15/' /etc/locale.gen
    locale-gen
    
    # Set timezone
    #timedatectl --no-ask-password set-timezone Europe/Berlin
    # .... host down??

    # Set NTP clock
    #timedatectl --no-ask-password set-ntp 1

    # Set locale
    #localectl --no-ask-password set-locale LANG="de_DE.UTF-8" LC_COLLATE="C" LC_TIME="de_DE.UTF-8"
    
    echo 'LANG=de_DE.UTF-8' > /etc/locale.conf
    ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
    hwclock --systohc
    timedatectl set-ntp true
    #localectl --no-ask-password set-keymap de
    #localectl --no-convert set-x11-keymap us,us pc104 ,intl grp:caps_toggle

    echo "KEYMAP=de-latin1" > /etc/vconsole.conf
    echo "FONT=lat9w-16" >> /etc/vconsole.conf

    #hostnamectl --no-ask-password set-hostname 'hserv'

    echo ""
    echo "Setting hostname..."
    echo 'hserv' > /etc/hostname
    
    # Disable PC speaker beep
    #echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf

    echo "127.0.0.1      localhost"         >> /etc/hosts
    echo "::1            localhost"         >> /etc/hosts
    echo "127.0.1.1      hserv.local hserv" >> /etc/hosts
    echo ""                                 >> /etc/hosts
    echo "185.228.138.42 io"                >> /etc/hosts
    
    echo ""
    echo "Installing bootloader..."
    pacman --noconfirm -S grub
    grub-install /dev/sda
    
    echo ""
    echo "Creating kernel..."
    mkinitcpio -p linux

    echo ""
    echo "Setting up the bootloader..."
    grub-mkconfig -o /boot/grub/grub.cfg
    
    echo ""
    echo "Setting up network connection..."
    echo "Interface=enp0s25" > /etc/netctl/ethernet-dhcp
    echo "Connection=ethernet" >> /etc/netctl/ethernet-dhcp
    echo "IP=static" >> /etc/netctl/ethernet-dhcp
    echo "#Address=('10.1.10.2/24')" >> /etc/netctl/ethernet-dhcp
    echo "#Gateway='10.1.10.1'" >> /etc/netctl/ethernet-dhcp
    echo "#DNS=('10.1.10.1')" >> /etc/netctl/ethernet-dhcp
    
    netctl enable ethernet-dhcp
    #netctl start ethernet-dhcp
    
    echo ""
    echo "Creating users..."
    useradd -m -g users -s /bin/bash stephan
    echo "Please enter a password for stephan:"
    passw stephan
    echo "stephan   ALL=(ALL) ALL" >> /etc/sudoers
    
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
    passwd
fi
