#!/bin/bash

expDay=$(chage -l $USER | sed -e '/P.*expire/ !d' -e 's/^.*: //')
expDay=$(date -d"$expDay" "+%s")

Today=$(date "+%s")

timeDiff=$(( ($expDay - $Today)/86400 ))

if [ $timeDiff -le 7 ]; then
	echo "WARNING: Your password expires in $timeDiff days!!"
fi
