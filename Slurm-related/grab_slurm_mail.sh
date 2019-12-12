#!/bin/bash

# File where mail can be found
mail_file="/var/spool/mail/slurm"
#mail_file="var_mail_example.txt" ## For testing only

# Make sure destination file exists for all human users
userlist=$(grep "^users" /etc/group | sed -e "s/,/ /g" -e "s/^.*[0-9]*://" -e "s/nessus//" -e "s/slurm//" -e "s/mfe//")

for user in $userlist;
do 
	filename="/home/$user/Slurm_mail.log"
	touch ${filename}
	chown ${user}: ${filename}
done

# Script will check for new information hourly
# Using timezone trickery to grab the previous hour's messages
hour=$(TZ=CST6CDT date +"%a, %_d %b %Y %_H")
#hour="Fri, 15 Nov 2019 14"	## For testing only

# Find the line(s) for the previous hour (grep will grab all matches)
line_num=$(grep -n "^Date.*${hour}" ${mail_file} | cut -d ":" -f 1 | tr "\n" " ")
count=$(echo ${line_num} | wc -w)

# Send info to the relevant user
if [ ${count} -gt 0 ]; then

	# Numbering starts at 1
	ii=1
	while [ $ii -le ${count} ];
	do
		# Grab the line number of interest
		line=$(echo "${line_num}" | cut -d ' ' -f $ii)
		user_line=$(( ${line} - 6 ))
		subj_line=$(( ${line} - 5 ))
		subj=$(sed "${subj_line} q;d" ${mail_file})

		# Only extract stuff if the message is from slurm
		if [[ ${subj} =~ .*"SLURM".* ]]; then
			# Extract relevant info
			from_source=$(sed "${line} q;d" ${mail_file})
			notifying=$(sed "${user_line} q;d" ${mail_file})
			user=$(sed "${user_line} q;d" ${mail_file} | awk -F'[ @]' '{print $2}')

			# APPEND relevant info to appropriate files
			filename="/home/${user}/Slurm_mail.log"

			echo ${from_source} >> ${filename}
			echo ${notifying} >> ${filename}
			echo ${subj} >> ${filename}
			echo "" >> ${filename}
		fi

		# Infinite loops are bad
		ii=$(( $ii + 1 ))
	done
fi

