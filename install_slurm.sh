#!/bin/bash

#===================================================================================
#
#          FILE:  install_slurm.sh
#
#   DESCRIPTION:  Basic slurm installation for Ubuntu 18.04
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Eleanor Coyle, coyleej@protonmail.com
#       COMPANY:  Azimuth Corporation
#       VERSION:  1.0
#       CREATED:  2019-01-28
#      REVISION:  2019-05-29
#
#===================================================================================

echo "Installing slurm on node "$HOSTNAME

clustername="Marvel"
ctlname="magneto"
ctladdr="134.166.132.51"
backupname="nebula"
backupaddr="134.166.132.0"

### Create munge user ###
mungeUID=399

if (grep "munge.*$mungeUID:$mungeUID" /etc/passwd); then
	echo "munge user already set up"
else
	# If it's set up with the wrong IDs, I have no intention of tracking everything down
	sudo deluser munge
	
	if (grep "$mungeUID" /etc/passwd) || (grep "$mungeUID" /etc/group); then
		echo "ERROR: uid/gid $mungeUIU is claimed by another process, ABORTING SETUP!"
		echo "Choose a different uid/gid and try again"
		exit 1
	else
		echo "uid/gid $mungeUIU is unused, proceeding with setup"
		sudo groupadd -g $mungeUID munge
		sudo useradd -r -u $mungeUID -g $mungeUID -s /usr/sbin/nologin munge
		sudo usermod -d /nonexistent munge
		echo ""
	fi
fi

### Install the things ###
sudo apt update
sudo apt install munge libmunge-dev libpam-slurm slurmd slurm-wlm-doc \
	cgroup-tools mariadb-common mariadb-server #mysql-common mysql-server

if [ $ctlname == $HOSTNAME ]; then
	ctlnode="Y"
	sudo apt install slurmctld slurm-wlm slurmdbd
else
	ctlnode="N"
fi

### Detect GPUs ###
maxGPUs=$(ls -l /dev/nvidia[0-9]* | wc -l); echo $maxGPUs
echo "Detected $maxGPUs GPUs on this system"
read -p "How many GPUs can slurm use? : " numGPUs
echo ""

if [ $numGPUs -gt 0 ] && [ $numGPUs -le $maxGPUs ]; then
	echo "Available GPU types:      (GPU is available on)"
	echo "  1 : NVidia GTX 1080ti   (compute node)"
	echo "  2 : NVidia RTX 2080ti   (compute node)"
	echo "  3 : NVidia Quadro P640  (control node)"
	echo "  4 : NVidia GTX 1070     (Oryx Pro)"
	echo "  5 : omit GPU label      (any)"
	read -p "GPU type? (int) : " typeGPU

	if [ $typeGPU == 1 ]; then
		typeGPU="gtx1080ti"
	elif [ $typeGPU == 2 ]; then
		typeGPU="rtx2080ti"
	elif [ $typeGPU == 3 ]; then
		typeGPU="quadP640"
	elif [ $typeGPU == 4 ]; then
		typeGPU="gtx1070"
	else
		typeGPU=""
	fi
else
	echo "WARNING : Invalid number of GPUs specified!"
	echo "WARNING : Setting the number of GPUs = 0"
fi

echo ""

#### Creating log files ####
# Control node
if [ $ctlnode == "Y" ]; then
	logDir=/var/log
	pidDir=/var/log/slurm-llnl
	spoolDir=/var/spool/slurmctld

	sudo mkdir $logDir $spoolDir
	sudo chown slurm: $logDir $spoolDir
	sudo chmod 755 $logDir $spoolDir

	logFile=$logDir/slurmctld.log
	if [ ! -e $logFile ]; then
		sudo touch $logFile
	fi
	sudo chown slurm: $logFile

	logFile=$logDir/slurm_jobacct.log
	sudo touch $logFile
	sudo chown slurm: $logFile

	logFile=$logDir/slurm_jobcomp.log
	sudo touch $logFile
	sudo chown slurm: $logFile

	pidFile=$pidDir/slurmctld.pid
	sudo touch $pidFile
	sudo chown slurm: $pidFile
fi

# Compute nodes
logDir=/var/log
pidDir=/var/log/slurm-llnl
spoolDir=/var/spool/slurm

logFile=$logDir/slurmd.log
sudo touch $logFile
sudo chown slurm: $logFile

pidFile=$pidDir/slurmd.pid
sudo touch $pidFile
sudo chown slurm: $pidFile

sudo mkdir -p $spoolDir/d
sudo mkdir $spoolDir/ctld
sudo chown slurm: $spoolDir $spoolDir/d $spoolDir/ctld

#### Config files ####
# Download example config files
echo ""
cd /home/$USER/Downloads
wget https://github.com/SchedMD/slurm/archive/slurm-17-11-2-1.tar.gz 
tar -xzf slurm-17-11-2-1.tar.gz

sudo cp "./slurm-slurm-17-11-2-1/etc/"*".conf.example" "/etc/slurm-llnl/"

cd "/etc/slurm-llnl"

# Setup gres.conf
if [ $numGPUs != 0 ]; then
	sudo touch gres.conf
	sudo chown $USER: gres.conf

	sudo echo "Name=gpu Type="$typeGPU" File=/dev/nvidia0" > gres.conf

	ii=1
	while [ $ii -lt $numGPUs ]
	do
		sudo echo "Name=gpu Type="$typeGPU" File=/dev/nvidia"$ii >> gres.conf
		ii=$(( $ii + 1 ))
	done
	sudo chown root: gres.conf
fi

# Setup cgroup.conf
sudo chown $USER: cgroup.conf
cat "cgroup.conf.example" | sudo sed "s/ConstrainRAMSpace=no/ConstrainRAMSpace=yes/" > cgroup.conf
sudo chown root: cgroup.conf

# Edit grub settings for cgroup
grubFile="/etc/default/grub"
sudo cp $grubFile $grubFile".backup"

sudo chown $USER: $grubFile
grep "^GRUB_CMDLINE_LINUX=" /etc/default/grub | grep "cgroup_enable=memory"
if [ $? != 0 ]; then
	sudo sed '/GRUB_CMDLINE_LINUX=/ s/\"/ cgroup_enable=memory\"/2' <$grubFile >$grubFile
fi

grep "^GRUB_CMDLINE_LINUX=" /etc/default/grub | grep "swapaccount=1"
if [ $? != 0 ]; then
	sudo sed '/GRUB_CMDLINE_LINUX=/ s/\"/ swapaccount=1\"/2' <$grubFile >$grubFile
fi
sudo chown root: $grubFile

# Setup slurm.conf
slurmConf="slurm.conf"
sudo cp $slurmConf.example $slurmConf
sudo chown $USER: $slurmConf

# Autofills Oryx Pro values if slurmd -C fails
node_info=$(slurmd -C | grep NodeName || echo "NodeName="$HOSTNAME" CPUs=12 Boards=1 SocketsPerBoard=1 CoresPerSocket=6 ThreadsPerCore=2 State=UNKNOWN")

#	-e "/^[#]BackupController=/ c\BackupController=${backupname}\\ " \
#	-e "/^[#]*BackupAddr=/ c\BackupAddr=${backupaddr}\\ " \
sudo sed -i -e "/ClusterName=/ s/linux/${clustername}/" \
	-e "/ControlMachine=/ s/linux0/${ctlname}/" \
	-e "/^[#]*ControlAddr=/ c\ControlAddr=${ctladdr}\\ " \
	-e "/SlurmctldPidFile=/ s/run/run\/slurm-llnl/" \
	-e "/SlurmdPidFile=/ s/run/run\/slurm-llnl/" \
	-e "/ProctrackType=/ s/pgid/cgroup/" \
	-e "/FirstJobId=/ a\RebootProgram=\"\/sbin\/reboot\"" \
	-e "/^[#]*Prop.*R.*L.*Except=/ s/#//" \
	-e "/Prop.*R.*L.*Except=/ s/=.*/=MEMLOCK/" \
	-e "/^[#]*TaskPlugin=/ c\TaskPlugin=task\/cgroup\\ " \
	-e "/InactiveLimit=/ s/=.*/=600/" \
	-e "/SchedulerType=/ a\DefMemPerNode=1000" \
	-e "/^[#]SelectType=/ c\SelectType=select/cons_res\\ " \
	-e "/SchedulerAuth=/ a\SelectTypeParameters=CR_CPU_Memory" \
	-e "/FastSchedule=/ a\EnforcePartLimits=YES" \
	-e "/COMPUTE NODES/ i\# RESOURCES\\
GresTypes=gpu\\
#" \
	-e "/^NodeName=linux.*Procs.*State.*/ s/NodeName.*/${node_info} Gres=gpu:${numGPUs} State=UNKNOWN/" \
	-e "/^PartitionName=/ s/ALL Default/ALL OverSubscribe=NO Default/" \
	$slurmConf

sudo chown root: $slurmConf

# Start slurm
echo ""
echo "Initial slurm setup on $HOSTNAME finished."
echo "Attempting to start slurm..."

pidDir=/var/run/slurm-llnl
sudo mkdir /var/run/slurm-llnl

sudo touch $pidDir/slurmd.pid
sudo chown slurm: $pidDir/slurmd.pid
sudo systemctl start slurmd

if [ $ctlnode == "Y" ]; then
	sudo touch $pidDir/slurmcltd.pid
	sudo chown slurm: $pidDir/slurmcltd.pid
	sudo systemctl start slurmctld
fi

# Leaving the tarball alone, removing the extracted folder
rm -rf "/home/"$USER"/Downloads/slurm-slurm-17-11-2-1/"

echo ""
echo "Manual start commands are sudo slurmd -Dvvvv and sudo slurmctld -Dvvvv"
echo "Slurm daemons are not enabled yet. Test slurm first."
echo "Any inter-machine communication must be set up manually!"
echo "This script does not perform any database setup."
