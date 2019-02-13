#!/bin/bash

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
chown slurm $pidDir/slurmdbd.pid

# Does slurmdbd not need a spool directory?

#### Config files ####

# Setup slurm.conf
cd /etc/slurm-llnl/
cp slurm.conf slurm.conf.backup

sed -e "/#JobAcctGatherType=/ s/#//" \
	-e "/#JobAcctGatherFrequency=/ s/#//" \
	-e "/#AccountingStorageType=/ s/#//" \
        -e "/#AccountingStorageHost=/ s/#//" \
        -e "/AccountingStorageHost=/ s/=/=localhost/" \
        -e "/#AccountingStorageLoc=/ s/#//" \
        -e "/AccountingStorageLoc=/ s/=/=slurm_acct_db/" \
        -e "/#AccountingStorageUser=/ s/#//" \
        -e "/AccountingStorageUser=/ s/=/=slurm/" \
        -e "/AccountingStorageUser=/ a\AccountingStoreJobComment=YES\\
AccountingStorageEnforce=associations\\
AccountingStorageTRES=gres/gpu,gres/gpu:gtx1080ti" \
	<slurm.conf.backup >slurm.conf

# Adjusting AccountingStorageEnforce requires slurmctld restart
echo ""
echo "Restarting slurmctld daemon..."
systemctl restart slurmctld

# Setup slurmdbd.conf
sed -e "/LogFile=/ s/\/slurm//" \
	-e "/PidFile=/ s/run/run\/slurm-llnl/" \
	-e "/#StorageHost=/ s/#//" \
	-e "/#StoragePass=/ s/password/some_pass/" \
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

echo "Initial slurm database setup finished. Attempting to start MariaDB..."

# Start database setup
echo ""
systemctl start mariadb || (echo "WARNING: MariaDB had issues starting: troubleshoot and/or reboot the node!"; echo "")

echo "Configure the database manually before attempting to start slurmdbd."
echo "Refer to the SysAdmin Guide for manual database configuration"
