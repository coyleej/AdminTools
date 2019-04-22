#!/bin/bash

# Make sure packages are installed
sudo apt install openssh-server fail2ban

#### SSH banner setup ####

#### Adjust sshd settings ####
echo "Adjusting sshd settings"

sshdir=/etc/ssh
sshconfig=$sshdir/sshd_config

# Create banner text
sudo cp banner_text.txt $sshdir/sshd_banner

sudo sed -i.bak \
	-e "/Port 22/ a\Protocol 2\\ " \
	-e "/^LoginGraceTime/ s/2m/1m/" \
	-e "/^#PermitRootLogin/ s/#//" \
	-e "/^PermitRootLogin/ s/Login.*/Login no/" \
	-e "/^#StrictModes/ s/#//" \
	-e "/^StrictModes/ s/Modes.*/Modes yes/" \
	-e "/^MaxAuthTries/ s/6/3/" \
	-e "/MaxSessions/ a\DenyUsers root\\
DenyGroups root\\
AllowGroups users slurm\\ " \
	-e "/IgnoreUserKnownHosts/ s/#//" \
	-e "/IgnoreUserKnownHosts/ s/Hosts.*/Hosts yes/" \
	-e "/^#PermitEmptyPasswords/ s/#//" \
	-e "/^PermitEmptyPasswords/ s/words.*/words no/" \
	-e "/^#X11forwarding/ s/#//" \
	-e "/^X11forwarding/ s/rding.*/rding yes/" \
	-e "/^#PrintLastLog/ s/#//" \
	-e "/^PrintLastLog/ s/stLog.*/stLog yes/" \
	-e "/^#PermitUserEnvironment/ s/#//" \
	-e "/^PermitUserEnvironment/ s/nment.*/nment no/" \
	-e "/^#Compression/ s/#//" \
	-e "/^Compression/ s/ssion.*/ssion delayed/" \
	-e "/^#ClientAliveInterval/ s/#//" \
	-e "/^ClientAliveInterval/ s/erval.*/erval 600/" \
	-e "/^#ClientAliveCountMax/ s/#//" \
	-e "/^ClientAliveCountMax/ s/ntMax.*/ntMax 1/" \
	-e "/^#Banner/ s/#//" \
	-e "/^Banner/ s/Banner.*/Banner \/etc\/ssh\/sshd_banner/" \
	-e "/^#ChrootDirectory/ a/UsePrivilegeSeparation sandbox \\ " \
	$sshconfig

# Check that changes are valid
sudo sshd -t

if [ $? = 0 ]; then
	echo "Valid sshd config: restarting daemon"
	sudo systemctl restart sshd
else
	echo "ERROR: invalid sshd config. Not restarting sshd!"
fi

