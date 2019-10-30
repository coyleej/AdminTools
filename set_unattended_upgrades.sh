#!/bin/bash

#===================================================================================
#
#          FILE:  set_unattended_upgrades.sh
#
#   DESCRIPTION:  Sets up unattended_upgrades
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Eleanor Coyle, ecoyle@azimuth-corp.com
#       COMPANY:  Azimuth Corporation
#       VERSION:  1.0
#       CREATED:  2019-04-25
#      REVISION:  2019-05-20
#
#===================================================================================

# UNATTENDED UPGRADES
logfile="/var/log/unattended-upgrades/unattended-upgrades.log"
#dpkglog="/var/log/unattended-upgrades/unattended-upgrades-dpkg.log"
settings="/etc/apt/apt.conf.d/20auto-upgrades"

# Check if installed
if (! dpkg -l | grep "unattended-upgrades" >/dev/null); then
        sudo apt install unattended-upgrades
fi

# Check if configured
if [ ! -e $settings ] && [ ! -e $logfile ] ; then
        echo "Unattended-upgrades is not set up on your machine."
        read -p "Are you setting up a server? (Y/N): " autosetup

        if [[ $autosetup = [Yy] ]]; then
                echo "Beginning server setup..."
                echo "Installing mail; choose 'local only' and use the hostname as ther mail server host"
                sudo apt install bsd-mailx

                cd /etc/apt/apt.conf.d/
                settingsConf="50unattended-upgrades"
                upgradesConf="20auto-upgrades"

                sudo cp $settingsConf $settingsConf.bak
                sudo cp $upgradesConf $upgradesConf.bak

                # Uncomment Unattended-Upgrade::Mail and change address to $HOSTNAME
                lineNum==$(grep -n "^//Unattended-Upgrade::Mail " /etc/apt/apt.conf.d/50unattended-upgrades | cut -d ":" -f 1)
                sudo sed -i \
                        -e "$lineNum s,//,," \
                        -e "$lineNum s,[\"].*[\"],\"$HOSTNAME\"," \
                        $settingsConf

                sudo sed -i '/::MailOnlyOnError/ c\Unattended-Upgrade::MailOnlyOnError \"true\"  ' $settingsConf

       	        # Not using sed when echo will suffice
       	        sudo echo 'APT::Periodic::Update-Package-Lists "1";' >$upgradesConf
       	        sudo echo 'APT::Periodic::Download-Upgradeable-Packages "1";' >>$upgradesConf
                sudo echo 'APT::Periodic::AutocleanInterval "7";' >>$upgradesConf
                sudo echo 'APT::Periodic::Unattended-Upgrade "1";' >>$upgradesConf

                # Check that things work
                if (sudo unattended-upgrades --dry-run --debug >/dev/null); then
                        sudo rm -f $settingsConf.bak $settingsConf.bak
                        echo "Successfully set up unattended-upgrades!!"
                else
                        echo "The code encountered a problem with the setup"
        	        echo "Once the problem has been resolved, please run"
                	echo "rm" $settingsConf.bak $settingsConf.bak
		fi
        else
                echo "Beginning laptop setup..."
                sudo dpkg-reconfigure unattended-upgrades
        fi

else
        # Already set up
        echo "Unattended-upgrades is already set up on your machine."
fi

echo ""
echo "If you wish to make any changes, please refer to the SysAdmin Guide"
echo "Unattended-upgrade logs are stored in /var/log/unattended-upgrades/"
echo "Apt logs are stored in /var/log/apt/"
