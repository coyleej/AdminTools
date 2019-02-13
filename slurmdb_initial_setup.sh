#!/bin/bash

echo "This script must be run with sudo for it to work properly"

echo "Partial slurm database setup on node "$HOSTNAME

echo "This code assumes slurm was set up with install_slurm.sh"
echo "It may not work properly otherwise."

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
	<slurm.conf.backup >slurm.conf

# Setup slurmdbd.conf
sed -e "/LogFile=/ s/\/slurm//" \
	-e "/PidFile=/ s/run/run\/slurm-llnl/" \
	-e "/#StorageHost=/ s/#//" \
	-e "/#StoragePass=/ s/password/some_pass/" \
	-e "/#StorageLoc=/ s/#//" \
	<slurmdbd.conf.backup >slurmdbd.conf

echo "PurgeEventAfter=12months" >> slurmdbd.conf
echo "PurgeJobAfter=12months" >> slurmdbd.conf
echo "PurgeResvAfter=2months" >> slurmdbd.conf
echo "PurgeStepAfter=2months" >> slurmdbd.conf
echo "PurgeSuspendAfter=1month" >> slurmdbd.conf
echo "PurgeTXNAfter=12months" >> slurmdbd.conf
echo "PurgeUsageAfter=12months" >> slurmdbd.conf

scontrol reconfigure

echo "Initial slurm database setup on $HOSTNAME finished.\nAttempting to start MariaDB..."

# Start database setup
echo ""
systemctl start mariadb

echo "If MariaDB has issues starting, troubleshoot and/or reboot the node."
echo "Configure the database manually before attempting to start slurmdbd."
echo "Refer to the SysAdmin Guide for manual database configuration"
