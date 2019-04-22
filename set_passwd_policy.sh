#!/bin/bash

# SET PASSWORD POLICY
logindefs="/etc/login.defs"
pwquality="/etc/security/pwquality.conf"

sudo sed -i.bak -e "/^PASS_MAX_DAYS/ s/[0-9]{1,}/60/" \
	-e "/^PASS_WARN_AGE/ s/[0-9]{1,}/7/" \
	$logindefs

sudo sed -i.bak -e "/^# difok = 8/minlen = 2/" \
	-e "/^# minlen = 8/minlen = 15/" \
	-e "/^# dcredit = 0/dcredit = -2/" \ 
	-e "/^# ucredit = 0/ucredit = -2/" \ 
	-e "/^# lcredit = 0/lcredit = -2/" \ 
	-e "/^# ocredit = 0/ocredit = -2/" \ 
	-e "/^# minclass = 0/minclass = 4/" \ 
	-e "/^# maxrepeat = 0/maxrepeat = 2/" \ 
	-e "/^# usercheck/usercheck/ " \ 
	$pwquality

echo "Please set your new password. It must meet the following criteria:"
echo "* At least 15 characters long"
echo "* Contain at least 2 numbers"
echo "* Contain at least 2 lowercase letters"
echo "* Contain at least 2 uppercase letters"
echo "* Contain at least 2 special characters"
echo "* Not contain more than two of the same character in a row"
echo "* Contain at least 2 characters not in the previous password"
echo "* Not contain your username"

passwd

if [ $? = 0 ]; then
	echo "Successfully set new password"
	echo "Deleting $logindefs.bak and $pwquality.bak"
	sudo rm $logindefs.bak $pwquality.bak
else
	echo "Something went wrong. Please fix the issue, then manually delete"
	echo "the backup files $logindefs.bak and $pwquality.bak"
fi

# UPDATE LOGIN SCREEN
bgDir="/usr/share/backgrounds/"
bgImage="login-banner.png"
cssfile="/usr/share/gnome-shell/theme/ubuntu.css"

sudo cp $bgImage $bgDirSbImage
sudo cp $cssfile $cssbak

# Find lines to set background image
startline=$(grep -n "^#lockDialogGroup" $cssfile | cut -d ":" -f 1)
blanklines=( $(grep -n "^$" $cssfile | cut -d ":" -f 1) )

ii=0
until [ ${blanklines[$ii]} -gt $startline ]
do
        ii=$(( $ii + 1 ))
done
endline=$(( ${blanklines[$ii]} - 1 ))

# Comment out old code
sudo sed -i -e "$startline s/#/\/*#/" \
        -e "$endline s/}/}*\//" \
        $cssfile

# Add code to set background image
startline=$(( ${blanklines[$ii]} ))

sudo sed -i "$startline a\
#lockDialogGroup { \\
  background: #000000 url(file:///usr/share/backgrounds/login-banner.png); \\
  background-repeat: no-repeat; \\
  background-size: cover; \\
  background-position: left top; } \\ \\
   " $cssfile

# Set box color
startline=$(grep -n ".login-dialog-user-list:expanded .login-dialog-user-list-item:selected" $cssfile | cut -d ":" -f 1)
startline=$(( $startline + 1 ))

sudo sed -n "$startline p" $cssbak | grep "background-color"

if [ $? = 0 ]; then
        sed -i "$startline s/#[A-Za-z0-9]*/#000000/" $cssfile
else
        sudo echo "ERROR: did not find expected line when setting box color"
fi

# UNATTENDED UPGRADES
ulog="/var/log/UNATTENDED-upgrades/unattended-upgrades.log"
uulog="/var/log/unattended-upgrades/unattended-upgrades.log"
dpkglog="/var/log/unattended-upgrades/unattended-upgrades-dpkg.log"

if [ ! -e $ulog ]; then
	echo "NOPE"
fi

# UNATTENDED-UPGRADES
uusettings="/etc/apt/apt.conf.d/20auto-upgrades"
#uulog="/var/log/unattended-upgrades/unattended-upgrades.log"
#dpkglog="/var/logdd/unattended-upgrades/unattended-upgrades-dpkg.log"

dpkg -l | grep unattended-upgrades
if [ $? = 1 ]; then
        sudo apt install unattended-upgrades
fi

if [ ! -e $uusettings ]; then
        echo "Unattended-upgrades is not set up on your machine."
        read -p "Are you setting up a server? (Y/N): " autosetup
else
        # Already set up
        autosetup=0
fi

if [[ $autosetup = 0 ]]; then
        echo "Unattended-upgrades is already set up on your machine."

elif [[ $autosetup = [Yy] ]]; then
        echo "Beginning server setup..."
        echo "Installing mail; choose 'local only' and use the hostname as ther mail server host"
        sudo apt install bsd-mailx

        cd /etc/apt/apt.conf.d/
        settingsConf="50unattended-upgrades"
        upgradesConf="20auto-upgrades"

        sudo cp $settingsConf $settingsConf.bak
        # Uncomment Unattended-Upgrade::Mail
        # Change the address to $HOSTNAME
        lineNum==$(grep -n "^//Unattended-Upgrade::Mail " /etc/apt/apt.conf.d/50unattended-upgrades | cut -d ":" -f 1)
        sudo sed -i \
                -e "$lineNum s,//,," \
                -e "$lineNum s,[\"].*[\"],\"$HOSTNAME\","
                $settingsConf

        sudo cp $upgradesConf $upgradesConf.bak
        # No sed abuse here due to laziness
        sudo echo 'APT::Periodic::Update-Package-Lists "1";' >$upgradesConf
        sudo echo 'APT::Periodic::Download-Upgradeable-Packages "1";' >>$upgradesConf
        sudo echo 'APT::Periodic::AutocleanInterval "7";' >>$upgradesConf
        sudo echo 'APT::Periodic::Unattended-Upgrade "1";' >>$upgradesConf

        sudo unattended-upgrades --dry-run --debug
        if [ ]; then
                sudo rm -f $settingsConf.bak $settingsConf.bak
        else
                echo "The code encountered a problem with the setup"
                echo "Once the problem has been resolved, please run"
                echo "rm" $settingsConf.bak $settingsConf.bak
else
        echo "Beginning laptop setup..."
        sudo dpkg-reconfigure unattended-upgrades
fi

echo ""
echo "If you wish to make any changes, please refer to the SysAdmin Guide"
echo "Unattended-upgrade logs are stored in /var/log/unattended-upgrades/"
echo "Apt logs are stored in /var/log/apt/"
