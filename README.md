# MiniCluster Tools
Collection of useful admin scripts for automating things

Please see the doc/ directory for all documentation. The following are brief descriptions of what everything does.

All shell scripts were written to work with bash. (I tried to maintain POSIX compliance, but I've not tested these in other shells.)

## Mandatory setup

### login_banner.sh 

Sets /etc/issue and /etc/issue.net. Creates the banner on the login screen (requires a reboot).

### set_passwd_policy.sh 

Configures the password settings and installs HBSS.

### set_unattended_upgrades.sh 

Sets up unattended upgrades.

### sshd_config.sh 

Configures sshd settings and sets the SSH login banner.

## Slurm-related

### copy_state.sh

Copies the slurm job state files between it's proper working location and a folder in the admin account. Used for transferring the slurm job state between control nodes. Can be set to copy in either direction and can optionally use sudo.

### distribute_slurm_conf.sh

Use to distribute updated slurm config files to the rest of the cluster.

### grab_slurm_mail.sh

This script is a workaround that is intended for systems WITHOUT a FQDN. You may still use it if you have a FQDN, but I don't know why you'd want to. It grabs slurm mail information and and distributes it to the relevant user as Slurm_mail.log. Users can delete Slurm_mail.log file as desired without harming operation of this script.

This script must run on the controller and makes no attempt to transfer files to another system. That is currently left to the user. Add it to root's crontab to make it run automatically once an hour.

### install_slurm.sh 

Sets up Slurm 17.11.2-1build1 on a machine running Ubuntu 18.04 based on given settings. It configures $HOSTNAME to be part of the cluster (adjusts slurm.conf, creates log and spool directories) and sets up everything locally. Manually append other nodes and partitions to slurm.conf if there is more than one node.

### slurmdb_initial_setup.sh 

Modifies slurm.conf and slurmdbd.conf to set up the slurm database. It attempts to start MariaDB to check installation success but does not modify MariaDB or create slurm accounting associations.

### test_sbatch.sh

Very simple script to test slurm installation.

## Other setup

### repo_download_w_some_setup.sh 

Downloads all of our git repos and automatically installs the ones that don't require compiling.

## Monitoring scripts

### check_passwd_expiry.sh

Standalone code to generate a warning if the user's password will expire in 7 or fewer days. May be incorporated into .bashrc if desired.

### downtime.py 

Monitors internet connection and tracks downtime.

### syncthing-warning

Automatically alert users when syncthing folders get too big. Place this file in /usr/share, then add the three lines of code mentioned in the header to /etc/bash.bashrc to activate.

### syncthing_usage.sh

User-run script to check syncthing usage.

## Required files called by the above (the files/ directory)

### banner_text.txt 

Banner text for sshd_banner and issue, required by login_banner.sh and sshd_config.sh

### banner_text_short.txt 

Short banner text for issue.net, required by login_banner.sh

### s4py.yml 

Conda environment setup, required by repo_download_w_some_setup.sh

## Documentation (the doc directory)

Hopefully self-explanatory. Contains a PDF and a number of .tex files.

NOTE: this documentation automatically pulls relevant information from a larger, actively updated document. As a result, some of the internal references point to information that is not or cannot be included. A few broken links seemed a reasonable compromise to ensure that all documentation is up to date.
