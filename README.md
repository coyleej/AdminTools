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

### install_slurm.sh 

Sets up Slurm 17.11.2-1build1 on a machine running Ubuntu 18.04 based on given settings. It configures $HOSTNAME to be part of the cluster (adjusts slurm.conf, creates log and spool directories) and sets up everything locally. Manually append other nodes and partitions to slurm.conf if there is more than one node.

### slurmdb_initial_setup.sh 

Modifies slurm.conf and slurmdbd.conf to set up the slurm database. It attempts to start MariaDB to check installation success but does not modify MariaDB or create slurm accounting associations.

## Other setup

### auto_user_setup.sh

Automated user setup. REMOVED in latest commit, as it was never used and modifying the files directly as it does can be unwise!

### repo_download_w_some_setup.sh 

Downloads all of our git repos and automatically installs the ones that don't require compiling.

## Monitoring scripts

### check_passwd_expiry.sh

Standalone code to generate a warning if the user's password will expire in 7 or fewer days. May be incorporated into .bashrc if desired.

### downtime.py 

Monitors internet connection and tracks downtime.

## Required files called by the above (the files/ directory)

### banner_text.txt 

Banner text for sshd_banner and issue, required by login_banner.sh and sshd_config.sh

### banner_text_short.txt 

Short banner text for issue.net, required by login_banner.sh

### install.sh 

HBSS setup script, called by set_passwd_policy.sh

### s4py.yml 

Conda environment setup, required by repo_download_w_some_setup.sh

### test_sbatch.sh

Very simple script to test slurm installation.

## Documentation (the doc/ directory)

Hopefully self-explanatory. Contains a PDF and a number of .tex files.

NOTE: this documentation automatically pulls relevant information from a larger, actively updated document. As a result, some of the internal references point to information that is not or cannot be included. A few broken links seemed a reasonable compromise to ensure that all documentation is up to date.
