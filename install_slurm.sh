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
#      REVISION:  2019-07-15
#
#===================================================================================

echo "Installing slurm on node "$HOSTNAME

clustername="Marvel"
ctlname="magneto"
ctladdr="XXX.XXX.XXX.XX"
backupname="nebula"
backupaddr="XXX.XXX.XXX.XX"

### Create munge user ###
mungeUID=399

if (grep "munge.*$mungeUID:$mungeUID" /etc/passwd); then
	echo "munge user already set up"
else
	# If it's set up with the wrong IDs, I have no intention of tracking everything down
	sudo deluser munge
	
	if (grep "$mungeUID" /etc/passwd) || (grep "$mungeUID" /etc/group); then
		echo "ERROR: uid/gid $mungeUID is claimed by another process, ABORTING SETUP!"
		echo "Choose a different uid/gid and try again"
		exit 1
	else
		echo "uid/gid $mungeUID is unused, proceeding with setup"
		sudo groupadd -g $mungeUID munge
		sudo useradd -r -u $mungeUID -g $mungeUID -s /usr/sbin/nologin munge
		sudo usermod -d /nonexistent munge
	fi
fi

### Set system clock ###
echo ""
sudo timedatectl set-timezone America/New_York
timedatectl
echo ""
echo "Pausing install to clearly display system clock"
echo "Installation will continue in 5 seconds..."
sleep 5

### Install the things ###
sudo apt update

# Checking NVidia drivers, installing from the PPA
echo ""
if [ ! -e /etc/apt/trusted.gpg.d/graphics-drivers_ubuntu_ppa.gpg ]; then
	sudo add-apt-repository ppa:graphics-drivers/ppa
	sudo apt update
fi

# The version you currently have
echo ""
nvidiaVer==$(dpkg -l | grep "nvidia-driver" | cut -d " " -f 3 | cut -d "-" -f 3)

# Make sure version nvidia-driver-418 or newer is installed
if [ ! $nvidiaVer ]; then
	# No NVidia driver installed
	echo "Installing new NVidia driver"
	sudo apt install nvidia-driver-418

elif [ $nvidiaVer -ge 418 ]; then 
	echo "Valid driver installed"

else
	echo "Purging old NVidia driver"
	sudo apt purge nvidia-driver-$nvidiaVer
	echo ""
	echo "Installing new NVidia driver"
	sudo apt install nvidia-driver-418
fi

# OpenMPI
echo ""
sudo apt install libopenmpi2 libopenmpi-dev openmpi-common openmpi-doc

# Slurm and MariaDB
echo ""
sudo apt install munge libmunge-dev libpam-slurm slurmd slurm-wlm-doc \
	slurm-wlm-basic-plugins cgroup-tools mariadb-common mariadb-server 
	#mysql-common mysql-server

echo ""
if [ $ctlname == $HOSTNAME ]; then
	ctlnode="Y"
	sudo apt install slurmctld slurm-wlm slurmdbd
elif [ $backupname == $HOSTNAME ]; then
	ctlnode="Y"
	sudo apt install slurmctld slurm-wlm slurmdbd
else
	ctlnode="N"
	sudo apt install slurm-client
fi

### Detect GPUs ###
echo ""
maxGPUs=$(ls -l /dev/nvidia[0-9]* | wc -l)
echo $maxGPUs
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
	read -p "GPU type? (integer) : " typeGPU

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

#### Create log and state save files ####
echo ""
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

spoolDir=/var/spool/slurmd
sudo mkdir $spoolDir
sudo chown slurm: $spoolDir

#### Config files ####
# Download example config files from github
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
# got sick of troubleshooting why sed wasn't generating the file
sudo cp files/cgroup.conf /etc/slurm-llnl/cgroup.conf
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
sudo update-grub

#### Setup slurm.conf ####
slurmConf="slurm.conf"
sudo cp $slurmConf.example $slurmConf
sudo chown $USER: $slurmConf

# Autofills Oryx Pro values if slurmd -C fails
node_info=$(slurmd -C | grep NodeName || echo "NodeName="$HOSTNAME" CPUs=12 Boards=1 SocketsPerBoard=1 CoresPerSocket=6 ThreadsPerCore=2 State=UNKNOWN")

sudo sed -i -e "/ClusterName=/ s/linux/${clustername}/" \
	-e "/ControlMachine=/ s/linux0/${ctlname}/" \
	-e "/^[#]*ControlAddr=/ c\ControlAddr=${ctladdr}\\ " \
	-e "/^[#]BackupController=/ c\BackupController=${backupname}\\ " \
	-e "/^[#]*BackupAddr=/ c\BackupAddr=${backupaddr}\\ " \
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

#### Start slurm ####
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
echo "Inter-machine communication must be set up manually!"
echo "This script does not perform any database setup."
