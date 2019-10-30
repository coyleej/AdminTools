#!/bin/bash

#===================================================================================
#
#          FILE:  distribute_slurm_conf.sh
#
#   DESCRIPTION:  Distributes an updated slurm.conf to all other nodes.
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

sshkey='/dev/null'
admin='admin'
remote_IP=('server1' 'server2' 'server3')

for IP in ${remote_IP[*]}
do
        rsync -au --fake-super -e "ssh -i $sshkey" "/etc/slurm-llnl/slurm.conf" $admin@$IP:/home/$admin/
        ssh -i $sshkey -t $admin@$IP 'sudo cp slurm.conf /etc/slurm-llnl/slurm.conf; sudo chown slurm: /etc/slurm-llnl/slurm.conf'
done

