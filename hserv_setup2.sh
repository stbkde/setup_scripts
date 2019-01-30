echo "Before starting this script: "
echo "$ arch-chroot /mnt"

read -p "Continue and format the whole disc? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Preparing setup..."
