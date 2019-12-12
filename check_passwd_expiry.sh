#!/bin/bash

#===================================================================================
#
#          FILE:  check_passwd_expiry.sh
#
#   DESCRIPTION:  If added to .bashrc, it reports password expiration warning if 
#                 password will expire within a week every time a new terminal 
#                 window is opened. 
#
#                 Add to .bashrc
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Eleanor Coyle, ecoyle@azimuth-corp.com
#       COMPANY:  Azimuth Corporation
#       VERSION:  1.0
#       CREATED:  2019-09-16
#      REVISION:  2019-12-12
#
#===================================================================================


expDay=$(chage -l $USER | sed -e '/P.*expire/ !d' -e 's/^.*: //')
expDay=$(date -d"$expDay" "+%s")

Today=$(date "+%s")

timeDiff=$(( ($expDay - $Today)/86400 ))

if [ $timeDiff -le 7 ]; then
	echo "WARNING: Your password expires in $timeDiff days!!"
fi
