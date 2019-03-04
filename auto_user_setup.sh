#!/bin/bash

etcpass=/etc/passwd

fullnames=("Strange" "Captain America" "Iron Man" "E C")
usernames=(strange cap ironman coyleej)
userids=(1000 1001 1002 1006)

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

		echo "hi"
		echo "${usernames[ii]}:x:${userids[ii]}:${userids[ii]}:${fullnames[ii]},,,:/home/${usernames[ii]}:/bin/bash"

		if [ -d /home/${usernames[ii]} ]; then
			cp /etc/skel/* "/home/${usernames[ii]}/"
		fi

		sudo passwd ${usernames[ii]}
	fi

	ii=$(( $ii+1 ))
done
