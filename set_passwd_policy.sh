#!/bin/bash

#===================================================================================
#
#          FILE:  set_passwd_policy.sh
#
#   DESCRIPTION:  Adjusts password requirements and forces the user to change 
#                 their password. Also sets up McAfee.
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Eleanor Coyle, coyleej@protonmail.com
#       COMPANY:  Azimuth Corporation
#       VERSION:  1.0
#       CREATED:  2019-03-06
#      REVISION:  2019-05-14
#
#===================================================================================

# SET PASSWORD POLICY
logindefs="/etc/login.defs"
pwquality="/etc/security/pwquality.conf"
hbssSetup="install.sh"

# Setup HBSS
echo "Installing McAfee and HBSS ..."
sudo bash $hbssSetup -i

echo ""
echo "Adjusting password requirements ..."

sudo chown $USER: $pwquality $logindefs
sudo chmod 664 $pwquality $logindefs

sudo sed -i.bak -e "/^PASS_MAX_DAYS/ s/[0-9].*/60/" \
	-e "/^PASS_WARN_AGE/ s/[0-9].*/7/" \
	$logindefs

sudo sed -i.bak -e "/^# difok/ c\difok = 2" \
	-e "/^# minlen/ c\minlen = 15" \
	-e "/^# dcredit/ c\dcredit = -2" \
	-e "/^# ucredit/ c\ucredit = -2" \
	-e "/^# lcredit/ c\lcredit = -2" \
	-e "/^# ocredit/ c\ocredit = -2" \
	-e "/^# minclass/ c\minclass = 4" \
	-e "/^# maxrepeat/ c\maxrepeat = 2" \
	-e "/^# usercheck/ c\usercheck = 1 " \
	$pwquality

sudo chown root: $pwquality $logindefs
sudo chmod 644 $pwquality $logindefs

echo
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
