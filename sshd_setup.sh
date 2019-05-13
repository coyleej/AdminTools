#!/bin/bash

#===================================================================================
#
#          FILE:  install_slurm.sh
#
#   DESCRIPTION:  Basic slurm installation for Ubuntu 18.04
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Eleanor Coyle, coyleej@protonmail.com
#       COMPANY:  Azimuth Corporation
#       VERSION:  1.0
#       CREATED:  2019-03-08
#      REVISION:  2019-05-08
#
#===================================================================================

# Installing everything
sudo apt install openssh-server fail2ban

sshdir=/etc/ssh
sshconfig=$sshdir/sshd_config
sshbanner=$sshdir/sshd_banner

# Banner text
sudo cp banner_text.txt $sshbanner

# Checking for all the values sed requires
arr=(Port LoginGraceTime PermitRootLogin StrictModes MaxAuthTries MaxSessions \
	IgnoreUserKnownHosts PermitEmptyPasswords X11Forwarding PrintLastLog \
	PermitUserEnvironment Compression ClientAliveInterval \
	ClientAliveCountMax Banner)

echo "Original settings, checking that all values are in the file:"
sudo cp $sshconfig $sshconfig.bak

ii=0
while [ $ii -lt ${#arr[*]} ]
do
	grep "^[#]*${arr[$ii]}" $sshconfig

	# Appends value to file for sed to catch if grep fails
	if [ $? -ne 0 ]; then
		echo "- Appending ${arr[$ii]} to file (currently missing)" 
		sudo echo "${arr[$ii]}" >>$sshconfig
	fi

	ii=$(( $ii + 1 ))
done

echo ""
echo "UsePrivilegeSeparation is depricated for openssh 7.5+!!"
echo ""

# Adjust settings
sudo sed -i \
	-e "/^[#]*Port / a\Protocol 2\\ " \
	-e "/^[#]*LoginGraceTime/ c\LoginGraceTime 1m\\ " \
	-e "/^[#]*PermitRootLogin/ c\PermitRootLogin no\\ " \
	-e "/^[#]*StrictModes/ c\StrictModes yes\\ " \
	-e "/^[#]*MaxAuthTries/ c\MaxAuthTries 3\\ " \
	-e "/^[#]*MaxSessions/ a\DenyUsers root\\
DenyGroups root\\
AllowGroups users slurm\\ " \
	-e "/^[#]*IgnoreUserKnownHosts/ c\IgnoreUserKnownHosts yes\\ " \
	-e "/^[#]*PermitEmptyPasswords/ c\PermitEmptyPasswords no\\ " \
	-e "/^[#]*X11forwarding/ c\^X11forwarding yes\\ " \
	-e "/^[#]*PrintLastLog/ c\PrintLastLog yes\\ " \
	-e "/^[#]*PermitUserEnvironment/ c\PermitUserEnvironment no\\ " \
	-e "/^[#]*Compression/ c\Compression delayed\\ " \
	-e "/^[#]*ClientAliveInterval/ c\ClientAliveInterval 600\\ " \
	-e "/^[#]*ClientAliveCountMax/ c\ClientAliveCountMax 1\\ " \
	-e "/^[#]*Banner/ c\Banner \/etc\/ssh\/sshd_banner\\ " \
	$sshconfig

# Check that changes are valid
sudo sshd -t

if [ $? = 0 ]; then
	echo "Valid sshd config: restarting daemon"
	sudo systemctl restart sshd

	echo "MUST add users to the ssh-approved group"
else
	echo "ERROR: invalid sshd config. Not restarting sshd!"
fi

