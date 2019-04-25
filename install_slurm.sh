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
#      REVISION:  2019-04-25
#
#===================================================================================

echo "This script must be run with sudo for it to work properly"

#### Install slurm ####
echo "Installing slurm on node "$HOSTNAME

read -p "Is "$HOSTNAME" part of the Marvel cluster? (Y/n): " checkname
if [ ${checkname} == "Y" ]; then
	clustername="Marvel"
	ctlname=$HOSTNAME
	ctlhost="10.0.10.43"
else
	read -p "Enter cluster name: " clustername
	read -p "Enter name of control node: " ctlname
	read -p "Enter IP of control node: " ctlhost
fi

apt update
apt install munge libmunge-dev libpam-slurm slurmd slurmdbd slurm-wlm-doc cgroup-tools mariadb-common mariadb-server #mysql-common mysql-server

if [ ${ctlname} == $HOSTNAME ]; then
	ctlnode="Y"
	apt install slurmctld slurm-wlm
fi

read -p "How many GPUs on this node? : " numGPUs
if [ ${numGPUs} != 0 ]; then
	read -p "GPU type? (1: gtx1080ti, 2: gtx2080ti, 3:gp107gl, 4:none): " typeGPU

	if [ ${typeGPU} == 1 ]; then
		typeGPU="gtx1080ti"
	elif [ ${typeGPU} == 2 ]; then
		typeGPU="gtx2080ti"
	elif [ ${typeGPU} == 3 ]; then
		typeGPU="gp107gl"
	else
		typeGPU=""
	fi

fi

#### Creating log files ####
# Control node
if [ ${ctlnode} == "Y" ]; then
	logDir=/var/log
	pidDir=/var/log/slurm-llnl
	spoolDir=/var/spool/slurmctld

	mkdir $logDir $spoolDir
	chown slurm: $logDir $spoolDir
	chmod 755 $logDir $spoolDir

	logFile=$logDir/slurmctld.log
	if [ ! -e $logFile ]; then
		touch $logFile
	fi
	chown slurm: $logFile

	logFile=$logDir/slurm_jobacct.log
	touch $logFile
	chown slurm: $logFile

	logFile=$logDir/slurm_jobcomp.log
	touch $logFile
	chown slurm: $logFile

	pidFile=$pidDir/slurmctld.pid
	touch $pidFile
	chown slurm: $pidFile
fi

# Compute nodes
logDir=/var/log
pidDir=/var/log/slurm-llnl
spoolDir=/var/spool/slurm

#mkdir $spoolDir
#chown slurm: $spoolDir
#chmod 755 $spoolDir

logFile=$logDir/slurmd.log
touch $logFile
chown slurm: $logFile

pidFile=$pidDir/slurmd.pid
touch $pidFile
chown slurm: $pidFile

mkdir -p $spoolDir/d
mkdir $spoolDir/ctld
chown slurm: $spoolDir $spoolDir/d $spoolDir/ctld

#### Config files ####
# Download files
cd /home/$USER/Downloads

wget https://github.com/SchedMD/slurm/archive/slurm-17-11-2-1.tar.gz 
tar -xzvf slurm-17-11-2-1.tar.gz

cp "./slurm-slurm-17-11-2-1/etc/"*".conf.example" "/etc/slurm-llnl/"

cd "/etc/slurm-llnl"

# Setup gres.conf
if [ ${numGPUs} != 0 ]; then
	echo "Name=gpu Type="${typeGPU}" File=/dev/nvidia0" > gres.conf

	ii=1
	while [ $ii -lt ${numGPUs} ]
	do
		echo "Name=gpu Type="${typeGPU}" File=/dev/nvidia"${ii} >> gres.conf
		ii=$(( $ii + 1 ))
	done
fi

# Setup cgroup.conf
cat "cgroup.conf.example" | sed "s/ConstrainRAMSpace=no/ConstrainRAMSpace=yes/" > cgroup.conf

# Edit grub settings for cgroup
grubFile="/etc/default/grub"
cp ${grubFile} ${grubFile}".backup"

grep "^GRUB_CMDLINE_LINUX=" /etc/default/grub | grep "cgroup_enable=memory"
if [ $? != 0 ]; then
	sed '/GRUB_CMDLINE_LINUX=/ s/\"/ cgroup_enable=memory\"/2' <${grubFile} >${grubFile}
fi

grep "^GRUB_CMDLINE_LINUX=" /etc/default/grub | grep "swapaccount=1"
if [ $? != 0 ]; then
	sed '/GRUB_CMDLINE_LINUX=/ s/\"/ swapaccount=1\"/2' <${grubFile} >${grubFile}
fi

# Setup slurm.conf
#node_info=$(slurmd -C | grep NodeName)
node_info=$(slurmd -C | grep NodeName || echo "NodeName="$HOSTNAME" CPUs=12 Boards=1 SocketsPerBoard=1 CoresPerSocket=6 ThreadsPerCore=2 State=UNKNOWN")

sed -e "/ClusterName=/ s/linux/${clustername}/" \
	-e "/ControlMachine=/ s/linux0/${ctlname}/" \
	-e "/^[#]*ControlAddr=/ c\ControlAddr=${ctlhost}\\ " \
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
	<slurm.conf.example >slurm.conf

echo "Initial slurm setup on $HOSTNAME finished.\nAttempting to start slurm..."

pidDir=/var/run/slurm-llnl
chown slurm: $pidDir/slurmd.pid
systemctl start slurmd
if [ ${ctlnode} == "Y" ]; then
	chown slurm: $pidDir/slurmcltd.pid
	systemctl start slurmctld
fi

rm -rf "/home/"$USER"/Downloads/slurm-slurm-17-11-2-1/"

echo "If either of these fail, use slurmd -Dvvvv or slurmctld -Dvvvv"
echo "Slurm daemons are not enabled yet. Test slurm first."
echo "Any inter-machine communication must be set up manually!"
echo "This script does not perform any database setup."
