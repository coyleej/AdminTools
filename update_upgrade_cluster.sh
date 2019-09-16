#!/bin/bash

#===================================================================================
#
#          FILE:  update_upgrade_cluster.sh
#
#   DESCRIPTION:  Updates and upgrades all nodes in the cluster. 
#                 Originally meant to run on the primary controller.
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Eleanor Coyle, coyleej@protonmail.com
#       COMPANY:  Azimuth Corporation
#       VERSION:  1.0
#       CREATED:  2019-09-11
#      REVISION:  2019-09-13
#
#===================================================================================

sshkey_name='.ssh/id_rsa'
admin='admin'
remote_IP=('server1' 'server2' 'server3')

# Primary controller
sudo apt update && sudo apt upgrade

# All remote machines
for server in ${remote_IP[*]}
do
        IP=$server
	sshkey="/home/$admin/$sshkey_name"
        ssh -i $sshkey -t $admin@$IP 'sudo apt update && sudo apt upgrade'
done


