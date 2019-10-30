#!/bin/bash

#===================================================================================
#
#          FILE:  update_upgrade_cluster.sh
#
#   DESCRIPTION:  Updates and upgrades all nodes in the cluster. 
#                 Recommend running this on the primary controller.
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Eleanor Coyle, ecoyle@azimuth-corp.com
#       COMPANY:  Azimuth Corporation
#       VERSION:  1.0
#       CREATED:  2019-09-11
#      REVISION:  2019-09-18
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
	sshkey="/home/$admin/$sshkey_name"
        ssh -i $sshkey -t $admin@$server 'sudo apt update && sudo apt upgrade'
done

