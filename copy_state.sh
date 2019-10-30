#!/bin/bash

#===================================================================================
#
#          FILE:  copy_state.sh
#
#   DESCRIPTION:  Copies the slurm state admin->state_folder or state_foler->admin
#                 Has the option to use sudo
#
#       OPTIONS:  Requires one or two options. Format is
#
#                 bash copy_state.sh DEST [sudo]
#
#                 DEST is the direction of copying; the only accepted values are 
#                 to_root and to_admin.
#
#                 You may optionally run with sudo privileges by specifying 
#                 sudo or with_sudo as the second option.
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Eleanor Coyle, ecoyle@azimuth-corp.com
#       COMPANY:  Azimuth Corporation
#       VERSION:  1.0
#       CREATED:  2019-08-22
#      REVISION:  2019-08-22
#
#===================================================================================

# Setting usernames
local_admin=$HOSTNAME

# Check the user-input function parameters
if [ $# -eq 0 ] || [ $# -ge 3 ]; then
	echo "ERROR: Invalid number of parameters passed to copy_state.sh"
	exit 1
fi

if [ $1 != "to_root" ] && [ $1 != "to_admin" ]; then
	echo "ERROR: First argument must be to_root or to_admin" 
	exit 1
fi

# Nested if statements to avoid "unary operator expected"
sudo_=""
if [ $# -eq 2 ]; then
	if [ $2 = sudo ] || [ $2 = with_sudo ]; then
		sudo_="sudo"
	fi
fi

# Copy and chown all the things
if [ $1 = "to_root" ]; then
#	echo "$sudo_ Copying to root directory"
	$sudo_ chown -R slurm: /home/$local_admin/slurm_state
	$sudo_ rsync -au --chmod="o-rw" /home/$local_admin/slurm_state/* /var/spool/slurm/ctld
	$sudo_ chown -R $local_admin: /home/$local_admin/slurm_state
elif [ $1 = "to_admin" ]; then
#	echo "$sudo_ Copying to local admin directory"
	$sudo_ rsync -rlptDu --chmod="o+rw" /var/spool/slurm/ctld/ /home/$local_admin/slurm_state/
	$sudo_ chown -R $local_admin: /home/$local_admin/slurm_state
else
	exit 1
fi
