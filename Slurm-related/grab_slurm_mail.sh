#!/bin/bash

#===================================================================================
#
#          FILE:  grab_slurm_mail.sh
#
#   DESCRIPTION:  This script is a workaround that is only intended for systems 
#                 WITHOUT a FQDN. You may still use it if you have a FQDN, but I
#                 don't know why you'd want to.
#
#                 Grabs slurm mail information and and distributes it to the 
#                 relevant user as Slurm_mail.log. Users can delete Slurm_mail.log 
#                 file as desired without harming operation of this script.
#
#                 This script must run on the controller and makes no attempt to 
#                 transfer files to another system. That is currently left to the 
#                 user.
#
#                 Add to root's crontab to make it run automatically once an hour.
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Eleanor Coyle, ecoyle@azimuth-corp.com
#       COMPANY:  Azimuth Corporation
#       VERSION:  1.0
#       CREATED:  2019-11-20
#      REVISION:  2019-12-12
#
#===================================================================================

# File where mail can be found
mail_file="/var/spool/mail/slurm"

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

