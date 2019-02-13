# some ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias lsdir='ls -d */'

# other aliases
#alias lp='lp -o sides=two-sided-long-edge'
alias rm='rm -i'
alias vi='vim'
alias lock='gnome-screensaver-command --lock'
alias suspend='pm-suspend-hybrid'
alias sync-nohup='nohup syncthing < /dev/null > /dev/null 2>&1 &'
alias sysadmin_pdf='evince ~/Syncthing/MANTISBIBLE/SysAdminGuide.pdf &'
alias needsreboot='if [ -e /var/run/reboot-required ]; then echo $HOSTNAME" needs to be rebooted!"; else echo "No reboot required";  fi'
