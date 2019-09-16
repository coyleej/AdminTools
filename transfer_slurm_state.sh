#!/bin/bash

#===================================================================================
#
#          FILE:  transfer_slurm_state.sh
#
#   DESCRIPTION:  A script that transfers the slurm state to the other controller
#                 before issuing the takeover command and stopping the local slurm
#                 control daemon.
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  Variables need to be filled in or code will not work
#        AUTHOR:  Eleanor Coyle, coyleej@protonmail.com
#       COMPANY:  Azimuth Corporation
#       VERSION:  1.0
#       CREATED:  2019-08-22
#      REVISION:  2019-09-03
#
#===================================================================================

sshkey='/dev/null'
local_admin='/dev/null'
remote_admin='/dev/null'
remote_IP='/dev/null'

if [ $sshkey = '/dev/null' ]; then
	echo "WARNING: Code will not execute!"
	echo "Change variables within file!"
else
	echo "Transfering slurm state..."
	bash ~/Code/MiniClusterTools/copy_state.sh to_admin with_sudo
	rsync -au --fake-super -e "ssh -i $sshkey" "/home/$local_admin/slurm_state" $remote_admin@$remote_IP:/home/$remote_admin/
	ssh -i $sshkey -t $remote_admin@$remote_IP 'sudo bash ~/Code/MiniClusterTools/copy_state.sh to_root with_sudo'

	echo "Issuing takeover command and killing local controller daemon"
	sudo scontrol takeover
	sudo systemctl stop slurmctld
fi

