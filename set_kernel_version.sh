#!/bin/bash

newKernel="4.15.0-62-generic"

sudo apt update && sudo apt upgrade

# Check if desired kernel is currently in use
# Script exits if true
uname -r | grep $newKernel > /dev/null
if [ $? == 0 ]; then
	echo "Currently running chosen kernel"
	exit 0
fi

# Check if desired kernel is installed
dpkg -l | grep "ii.*linux-image-$newKernel" > /dev/null
if [ $? != 0 ]; then
	echo "Installing kernel linux-image-$newKernel"
	sudo apt install linux-image-$newKernel linux-headers-$newKernel
fi

# Determine which grub entry it is and adjust to grub's 0-based indexing
grubEntry=$(sed -e 's/--.*//' -e '/menuentry.*Linux/ !d' /boot/grub/grub.cfg \
	| grep -n "$newKernel" | sed -e '/recovery/ d' -e 's/:.*//')
grubEntry=$(( $grubEntry - 1 ))

echo "Updating grub file"

# Adjust grub file
#grubFile="/home/$USER/test.txt"     ## TEST
grubFile="/etc/default/grub"

sudo cp -v $grubFile $grubFile.bak
sudo sed -i "/^GRUB_DEFAULT=/ s/=.*/=\"1\>$grubEntry\"/" $grubFile

sudo update-grub

echo ""
echo "Reboot required!!"
echo "Confirm that changes are correct before rebooting."

#sudo shutdown -r +1 "Computer will reboot in 1 minute!"

