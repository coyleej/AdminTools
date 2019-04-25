#!/bin/bash

#===================================================================================
#
#          FILE:  auto_user_setup.sh
#
#   DESCRIPTION:  Automatically creates users on the servers
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Eleanor Coyle, coyleej@protonmail.com
#       COMPANY:  Azimuth Corporation
#       VERSION:  1.0
#       CREATED:  2019-03-01
#      REVISION:  2019-04-24
#
#===================================================================================

etcpass=/etc/passwd
adminsync=/home/$USER/Sync

fullnames=("Doctor Strange" "Captain America" "Iron Man" "E C")
usernames=(strange cap ironman coyleej)
userids=(1000 1001 1002 1006)

# Make sure that group "users" exists
grep "^users" /etc/group
if [ ! $? = 0 ]; then
	sudo groupadd users
fi

# Make sure that $USER is a member of "users"
grep $USER /etc/group | grep "^users"
if [ ! $? = 0 ]; then
	sudo usermod -a -G users $USER
fi

# Install syncthing if it's not already present
dpkg -l | grep syncthing
if [ ! $? = 0 ]; then 
	sudo apt install syncthing
	sudo chown $USER:users $adminsync
	sudo chmod 3770 /home/$USER/Sync
	echo ""
	echo "WARNING: Syncthing installed, but not configured!"
	echo "Please configure (add computers) manually!"
fi

# Backup /etc/passwd
sudo cp $etcpass $etcpass.backup
ii=0
while [ $ii -lt ${#usernames[*]} ]
do
	grep ${usernames[ii]} $etcpass
	if [ $? = 0 ]; then
		echo "User ${usernames[ii]} already exists!"
	else
		# Leaving it up to the user to pick a non-existing uid
		grep ${userids[ii]} $etcpass
		if [ $? = 0 ]; then
			echo "The uid ${userids[ii]} is already taken!"
			echo "Please claim one in the 1000s that is not listed below:"
			grep 100 $etcpass | cut -d ":" -f 3
			echo $userids
			read -p "Enter a new user id:" userids[ii]
			echo "New user id: " ${userids[ii]}
		fi

		sudo mkdir /home/${usernames[ii]}
		sudo chown ${usernames[ii]}: /home/${usernames[ii]}

		echo "${usernames[ii]}:x:${userids[ii]}:${userids[ii]}:${fullnames[ii]},,,:/home/${usernames[ii]}:/bin/bash" | sudo tee -a $etcpass

		if [ -d /home/${usernames[ii]} ]; then
			cp /etc/skel/* "/home/${usernames[ii]}/"
		fi

		sudo ln -s $adminsync /home/${usernames[ii]}/Syncthing
		sudo chmod 3770 $adminsync

		sudo usermod -a -G users ${usernames[ii]}

		if [ ${userids[ii]} = 1000 ]; then 
			sudo passwd ${usernames[ii]}
		else
			sudo passwd -dl ${usernames[ii]}
		fi
	fi

	ii=$(( $ii+1 ))
done


echo ""
echo "Confirm that the user setup was successful, then delete /etc/passwd.backup"

echo "WARNING: Only the admin account has a functioning password."
echo "All other logins are presently locked and disabled."
