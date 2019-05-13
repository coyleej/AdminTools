# AdminTools
Collection of useful admin scripts for automating things

Mandatory setup:

* login_banner.sh : Creates the banner on the login screen (requires a reboot)

* banner_text.sh : Banner text for sshd_banner and issue

* banner_text_short.sh : Short banner text for issue.net

* install.sh : HBSS setup script

* set_passwd_policy : Configures the password setting

* set_unattended_upgrades.sh : Sets up unattended upgrades 

* sshd_config.sh : Configures sshd settings and banner

Slurm-related:

* install_slurm.sh : Initial install of slurm on Ubuntu 18.04

* slurmdb_initial_setup.sh : Sets up slurm database, minus the MariaDB parts

Other setup:

* auto_user_setup.sh : Automated user setup

* repo_download_w_some_setup.sh : Downloads all of our git repos and automatically installs the ones that don't require compiling

* s4py.yml : Conda environment setup required by repo_download*
