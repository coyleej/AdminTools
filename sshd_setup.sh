#!/bin/bash

## Still NEED to add check that openssh-server is installed

sudo apt install fail2ban

sshdir=/etc/ssh

# Create banner text
sudo cp DoD_banner_text.txt $sshdir/sshd_banner

# Adjust sshd_config
#sudo sed -i.backup ""
