#!/bin/bash

#===================================================================================
#
#          FILE:  set_passwd_policy.sh
#
#   DESCRIPTION:  Adjusts password requirements and forces the user to change 
#                 their password. Also sets up HBSS on base.
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Eleanor Coyle, coyleej@protonmail.com
#       COMPANY:  Azimuth Corporation
#       VERSION:  1.0
#       CREATED:  2019-03-06
#      REVISION:  2019-04-25
#
#===================================================================================

# SET PASSWORD POLICY
logindefs="/etc/login.defs"
pwquality="/etc/security/pwquality.conf"
hbssSetup="install.sh"

# Setup HBSS
sudo bash $hbssSetup -i

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
