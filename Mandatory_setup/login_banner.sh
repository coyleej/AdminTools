#!/bin/bash

#===================================================================================
#
#          FILE:  login_banner.sh
#
#   DESCRIPTION:  Adds a banner to the login screen.
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  The control nodes do not have a display manager installed.
#        AUTHOR:  Eleanor Coyle, ecoyle@azimuth-corp.com
#       COMPANY:  Azimuth Corporation
#       VERSION:  1.0
#       CREATED:  2019-05-06
#      REVISION:  2019-12-12
#
#===================================================================================
 
miniTools=$(cd ..; pwd)

# Create /etc/issue and /etc/issue.net
sudo chown $USER: /etc/issue /etc/issue.net
sudo cat ${miniTools}/files/banner_text.txt >> /etc/issue
sudo cat ${miniTools}/files/banner_text_short.txt >> /etc/issue.net
sudo chown root: /etc/issue /etc/issue.net

if [ -d /etc/dconf ] && (dpkg -l | grep gdm); then
	# Applies to everything but the control nodes
	echo "Display manager installed. Setting up banner."

	# Disable wayland or it kills the nvidia drivers
	customConf=/etc/gdm3/custom.conf
	sudo sed -i.bak -e "/WaylandEnable/ s/^#//" $customConf

	if ( ! grep "^WaylandEnable=false" $customConf >/dev/null); then
		echo "Error: "$customConf" did not update successfully!"
		echo "Error: Wayland is still enabled, will cause login issues!"
		echo ""
	fi

	# Create directory and files
	gdmProfile=/etc/dconf/profile/gdm
	gdmDir=/etc/dconf/db/gdm.d
	gdmBanner=$gdmDir/01-banner-message

	sudo touch $gdmProfile
	sudo mkdir -p $gdmDir
	sudo touch $gdmBanner

	sudo chown $USER: $gdmProfile $gdmBanner

	# Create dconf profile
	sudo echo "user-db:user" > $gdmProfile
	sudo echo "system-db:gdm" >> $gdmProfile
	sudo echo "file-db:/usr/share/gdm/greeter-dconf-defaults" >> $gdmProfile

	# Create banner message
	sudo echo "[org/gnome/login-screen]" > $gdmBanner
	sudo echo "banner-message-enable=true" >> $gdmBanner
	sudo echo "banner-message-text='I have read & consent to terms in IS user agreement.'" >> $gdmBanner

	sudo chown root: $gdmProfile $gdmBanner

	# Reconfigure things
	echo "Updated files, now reconfiguring..."
	sudo dconf update
	sudo dpkg-reconfigure gdm3

	# Notify user that a reboot is required.
	echo "This workstation must be restarted for these changes to take effect"

else
	# Control nodes only
	echo "No display manager installed"
	echo "Only /etc/issue and /etc/issue.net updated"

fi
