#!/bin/bash

#===================================================================================
#
#          FILE:  syncthing_usage/sh
#
#   DESCRIPTION:  Reports the size of all syncthing folders, including the Default 
#                 folder and all other shared folders visible on $HOSTNAME. For the 
#                 Default folder, it also reports the size of all immediate child
#                 directories.
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Eleanor Coyle, ecoyle@azimuth-corp.com
#       COMPANY:  Azimuth Corporation
#       VERSION:  1.0
#       CREATED:  2019-08-06
#      REVISION:  2019-08-06
#
#===================================================================================

# Set up data collection
tempfile=~/sync.data
echo "FOLDER SIZE" > $tempfile
echo "---------- -----" >> $tempfile

# Size of individual folders
syncDir=/path/to/syncthing/common/Sync
syncFolders=$(ls $syncDir)
for eachDir in $syncFolders; do 
	checkDir=$syncDir/$eachDir
	spaceUsed=$(du -sh $checkDir | sed "s/\t.*//g")
	echo "$eachDir $spaceUsed" >> $tempfile
done

# Total size of syncthing directory
echo "---------- -----" >> $tempfile
spaceUsed=$(du -sh $syncDir | sed "s/\t.*//g")
echo "DEFAULT $spaceUsed" >> $tempfile

# Check for non-default directories
syncDir=/path/to/psyncthing/common
syncFolders=$(ls $syncDir | grep -v "syncthing" | grep -v "Sync")
for eachDir in $syncFolders; do 
	checkDir=$syncDir/$eachDir
	spaceUsed=$(du -sh $checkDir | sed "s/\t.*//g")
	echo "$eachDir $spaceUsed" >> $tempfile
done

# Make it look pretty
column -t $tempfile | sed "/[0-9][A-Z]$/ s/[A-Z]$/ &/" | tee $tempfile

#rm -f $tempfile
