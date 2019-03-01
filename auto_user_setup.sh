#!/bin/bash

etcpass=/etc/passwd

fullname=coyleej
userid=1008
#uid=gid

grep $userid $etcpass
if [ $? = 0 ]; then 
	echo "this uid already exists"; 
else 
	echo "unclaimed"; 
fi

echo ""
fullnames=("Strange" "Eric Harper" "Jonathan Thompson" "Meghan Weber" "Ighodalo Idehenre" "Heidi Nelson-Quillin" "Eleanor Coyle" "Matt Mills")
usernames=(strange harperes thompsonjr webermn idehenreiu nelsonquillinhd coyleej millsms)
userids=(1000 1001 1002 1003 1004 1005 1006 1007)

ii=0
while [ $ii -lt ${#usernames[*]} ]
do
	grep ${usernames[ii]} $etcpass
	if [ $? = 0 ]; then
		echo "The uid ${userids[ii]} is already taken!"
		#echo "Please claim one that is not listed below:"
		#grep ${userids[ii]} $etcpass #| cut -d "d" -f 3
		#read -p "Enter a new user id:" ${userids[ii]}
	fi

#	## working code
#	mkdir sudo /home/${usernames[ii]}

	echo "${usernames[ii]}:x:${userids[ii]}:${userids[ii]}:${fullnames[ii]},,,:/home/${usernames[ii]}:/bin/bash"
	cat /etc/passwd | grep ${usernames[ii]}

#	## working code
#	if [ -d /home/${usernames[ii]} ]; then
#		cp /etc/skel/* "/home/${usernames[ii]}/"
#	fi

	sudo passwd -x60 ${usernames[ii]}

	ii=$(( $ii+1 ))
done
