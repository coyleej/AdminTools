#!/bin/bash

#===================================================================================
#
#          FILE:  set_kernel_version.sh
#
#   DESCRIPTION:  Updates kernel to the version specified in the newKernel variable
#                 Originally developed to roll back to older kernels.
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Eleanor Coyle, ecoyle@azimuth-corp.com
#       COMPANY:  Azimuth Corporation
#       VERSION:  1.0
#       CREATED:  2019-09-16
#      REVISION:  2019-12-12
#
#===================================================================================

#!/bin/bash

newKernel="4.15.0-62-generic"
grubFile="/etc/default/grub"
grubCfg="/boot/grub/grub.cfg"
kernelFam=$(echo $newKernel | sed 's/\.0.*$//')

sudo apt update; sudo apt upgrade

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

# Determine which grub entry it is
#grep "menuentry" /boot/grub/grub.cfg | sed -e "1,4 d" -e "s/--.*//"

grubEntry=$(sed -e 's/--.*//' -e '/menuentry.*Linux/ !d' $grubCfg \
	| grep -n "$newKernel" | sed -e '/recovery/ d' -e 's/:.*//')

# Check that $grubEntry is not NULL. If it is, try a different approach:
if [ ! $grubEntry ]; then

       if (grep $kernelFam $grubCfg > /dev/null); then
		# Grab the latest kernel in that family (e.g. 4.15) available

		echo "Grabbing latest similar kernel"
		grubEntry=$(sed -e 's/--.*//' -e '/menuentry.*Linux/ !d' $grubCfg \
			| grep -n "$kernelFam" | sed -e '/recovery/ d' -e 's/:.*//')
		grubEntry=$(echo $grubEntry | cut -d ' ' -f 1)

	else
		# Grab the oldest kernel in the file
		# The -1 is to ignore the recovery mode entry
		# NOTE: this is a catch-all that should never have to run

		echo "Grabbing oldest kernel (catch-all should other conditions fail)"
		grubEntry=$(( $(grep -c "^\smenuentry" $grubCfg) - 1 ))
	fi
fi

# Adjust to grub's 0-based indexing
grubEntry=$(( $grubEntry - 1 ))

echo ""
echo "Using grub entry 1>$grubEntry"
echo ""

# Adjust grub file
if [ $grubEntry -ge 0 ]; then
	sudo cp -v $grubFile $grubFile.bak
	sudo sed -i "/^GRUB_DEFAULT=/ s/=.*/=\"1\>$grubEntry\"/" $grubFile
	sudo update-grub
	echo "Reboot required!!"
	echo "Confirm that changes to $grubFile are correct before rebooting."
	echo "After reboot, check that you are running $newKernel with 'uname -r"
##	sudo shutdown -r +2 "Computer will reboot in 1 minute!"

else
	echo "ERROR: Negative grub entry detected."
	echo "Please check the file manually or ask your admin for help!"
	exit 1
fi
