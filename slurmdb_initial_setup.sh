#!/bin/bash

#===================================================================================
#
#          FILE:  slurmdb_initial_setup.sh
#
#   DESCRIPTION:  Adjusts slurm config files for slurm database installation for 
#                 Ubuntu 18.04, must have slurm already installed and running
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Eleanor Coyle, coyleej@protonmail.com
#       COMPANY:  Azimuth Corporation
#       VERSION:  1.0
#       CREATED:  2019-02-13
#      REVISION:  2019-04-25
#
#===================================================================================

echo "This script must be run with sudo for it to work properly"
echo "This code assumes slurm was set up with install_slurm.sh"

#### Creating log and pid files ####
logDir=/var/log
logFile=$logDir/slurmd.log
touch $logFile
chown slurm: $logFile

pidDir=/var/run/slurm-llnl
pidFile=$pidDir/slurmdbd.pid
touch $pidFile
chown slurm: $pidFile

# Does slurmdbd not need a spool directory?

#### Config files ####

ctlname=$( scontrol show config | grep ControlNode | awk '{print $3}' )
ctladdr=$( scontrol show config | grep ControlAddr | awk '{print $3}' )

# Edit slurm.conf
cd /etc/slurm-llnl/
cp slurm.conf slurm.conf.backup

sed -e "/#JobAcctGatherType=/ s/#//" \
	-e "/#JobAcctGatherFrequency=/ s/#//" \
	-e "/#AccountingStorageType=/ s/#//" \
        -e "/^[#]*AccountingStorageHost=/ c\AccountingStorageHost=${ctladdr}\\ " \
        -e "/^[#]*Acco.*StorageLoc=/ c\AccountingStorageLoc=\/var\/lib\/mysql\\ " \
        -e "/^[#]*Acco.*StoragePass=/ c\AccountingStoragePass=\/var\/run\/munge\/munge.socket.2\\ " \
        -e "/AccountingStoragePass=/ a\AccountingStoragePort=3306" \
        -e "/^[#]AccountingStorageUser=/ c\AccountingStorageUser=slurm\\ " \
        -e "/AccountingStorageUser=/ a\AccountingStoreJobComment=YES\\
AccountingStorageEnforce=associations\\
AccountingStorageTRES=gres/gpu,gres/gpu:gtx1080ti" \
	<slurm.conf.backup >slurm.conf

# Adjusting AccountingStorageEnforce requires slurmctld restart
echo ""
echo "Restarting slurmctld daemon..."
systemctl restart slurmctld

# Setup slurmdbd.conf
sed -e "/DbdAddr=/ s/localhost/${ctladdr}/" \
	-e "/DbdHost=/ s/localhost/${ctlname}/" \
        -e "/DbdHost=/ a\#DbdBackupHost=" \
	-e "/LogFile=/ s/\/slurm//" \
	-e "/PidFile=/ s/run/run\/slurm-llnl/" \
	-e "/^[#]*StorageHost=/ c\StorageHost=${ctlname}\\ " \
	-e "/^[#]Storageport=/ c\Storageport=3306\\ " \
	-e "/StoragePass=/ s/password/some_pass/" \
	-e "/#StorageLoc=/ s/#//" \
	<slurmdbd.conf.example >slurmdbd.conf

echo "PurgeEventAfter=12months" >> slurmdbd.conf
echo "PurgeJobAfter=12months" >> slurmdbd.conf
echo "PurgeResvAfter=2months" >> slurmdbd.conf
echo "PurgeStepAfter=2months" >> slurmdbd.conf
echo "PurgeSuspendAfter=1month" >> slurmdbd.conf
echo "PurgeTXNAfter=12months" >> slurmdbd.conf
echo "PurgeUsageAfter=12months" >> slurmdbd.conf

scontrol reconfigure

# Edit mariadb config file
mdbconf=/etc/mysql/my.cnf

echo "" >> ${mdbconf}
echo "[mysqld]" >> ${mdbconf}
echo "skip-networking=0" >> ${mdbconf}
echo "skip-bind-address" >> ${mdbconf}

# Start database setup
echo ""
echo "Attempting to start MariaDB..."
systemctl start mariadb || echo "WARNING: MariaDB had issues starting: troubleshoot and/or reboot the node!"

echo ""
echo "Configure the database manually before attempting to start slurmdbd."
echo "Refer to the SysAdmin Guide for manual database configuration"
