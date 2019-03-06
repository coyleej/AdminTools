#!/bin/bash

logindefs=/etc/login.defs
pwquality=/etc/security/pwquality.conf

cp $logindefs $logindefs.backup

sed -e "/^PASS_MAX_DAYS/ s/[0-9]{1,}/60/" \
	-e "/^PASS_WARN_AGE/ s/[0-9]{1,}/7/" \
	<$logindefs.backup >$logindefs

sed -e "/^# difok = 8/minlen = 2/" \
	-e "/^# minlen = 8/minlen = 15/" \
	-e "/^# dcredit = 0/dcredit = -2/" \ 
	-e "/^# ucredit = 0/ucredit = -2/" \ 
	-e "/^# lcredit = 0/lcredit = -2/" \ 
	-e "/^# ocredit = 0/ocredit = -2/" \ 
	-e "/^# minclass = 0/minclass = 4/" \ 
	-e "/^# maxrepeat = 0/maxrepeat = 2/" \ 
	-e "/^# usercheck/usercheck/ " \ 
	<$pwquality >$pwquality

echo "Please set your new password. It must meet the following criteria:"
echo "* At least 15 characters long"
echo "* Contain at least 2 numbers"
echo "* Contain at least 2 lowercase letters"
echo "* Contain at least 2 uppercase letters"
echo "* Contain at least 2 special characters"
echo "* Not contain more than two of the same character in a row"
echo "* Contain at least 2 characters not in the previous password"
echo "* Not contain your username"

passwd
