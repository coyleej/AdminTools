#!/bin/bash

echo "This script must be run with sudo for it to work properly"

#### Install slurm ####
echo "Installing slurm on node "$HOSTNAME

read -p "Is "$HOSTNAME" part of the Marvel cluster? (Y/n): " checkname
if [ ${checkname} == "Y" ]; then
	clustername="Marvel"
else
	read -p "Enter cluster name: " clustername
fi

read -p "Is this the control node? (Y/n): " ctlnode
if [ ${ctlnode} == "Y" ]; then
	ctlname=$HOSTNAME
else
#	ctlname="magneto"
	read -p "Enter name of control node: " ctlname
fi

apt update
apt install munge libpam-slurm slurmd slurmdbd slurm-wlm-doc cgroup-tools mariadb-common mariadb-server mysql-common mysql-server

if [ ${ctlnode} == "Y" ]; then
	apt install slurmctld slurm-wlm
fi

read -p "How many GPUs on this node? : " numGPUs
if [ ${numGPUs} != 0 ]; then
	read -p "GPU type? (1: gtx1080ti, 2: gtx2080ti): " typeGPU

	if [ ${typeGPU} == 1 ]; then
		typeGPU="gtx1080ti"
	elif [ ${typeGPU} == 2 ]; then
		typeGPU="gtx2080ti"
	else
		typeGPU=""
	fi

fi

#### Creating log files ####
# Control node
if [ ${ctlnode} == "Y" ]; then
	logDir=/var/log/slurm-llnl/
	spoolDir=/var/spool/slurmctld

	mkdir $logDir $spoolDir
	chown slurm: $logDir $spoolDir
	chmod 755 $logDir $spoolDir

	logFile=$logDir/slurmctld.log
	if [ ! -e $logFile ]; then
		touch $logFile
	fi
	chown slurm: $logFile

	logFile=$logDir/slurm_jobacc.log
	touch $logFile
	chown slurm: $logFile

	logFile=$logDir/slurm_jobcomp.log
	touch $logFile
	chown slurm: $logFile
fi

# Compute nodes
logDir=/var/log
spoolDir=/var/spool/slurmd

mkdir $spoolDir
chown slurm: $spoolDir
chmod 755 $spoolDir

logFile=$logDir/slurmd.log
touch $logFile
chown slurm: $logFile

#### Config files ####
# Download files
cd /home/$HOSTNAME/Downloads

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
	-e "/SlurmctldPidFile=/ s/run/run\/slurm-llnl/" \
	-e "/SlurmdPidFile=/ s/run/run\/slurm-llnl/" \
	-e "/ProctrackType=/ s/pgid/cgroup/" \
	-e "/FirstJobId=/ a\RebootProgram=\"\/sbin\/reboot\"" \
	-e "/#Prop.*R.*L.*Except=/ s/#//" \
	-e "/Prop.*R.*L.*Except=/ s/=/=MEMLOCK/" \
	-e "/#TaskPlugin=/ s/#//" \
	-e "/TaskPlugin=/ s/=/=task\/cgroup/" \
	-e "/SchedulerType=/ a\DefMemPerNode=1000" \
	-e "/#SelectType=/ s/#//" \
	-e "/SelectType=/ s/linear/cons_res/" \
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

echo "If either of these fail, use slurmd -Dvvvv or slurmctld -Dvvvv"
echo "Slurm daemons are not enabled yet. Test slurm first."
echo "Any inter-machine communication must be set up manually!"
echo "This script does not perform any database setup."
