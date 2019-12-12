#!/bin/bash

#===================================================================================
#
#          FILE:  set_unattended_upgrades.sh
#
#   DESCRIPTION:  Sets up unattended_upgrades
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Eleanor Coyle, ecoyle@azimuth-corp.com
#       COMPANY:  Azimuth Corporation
#       VERSION:  1.0
#       CREATED:  2019-04-25
#      REVISION:  2019-12-11
#
#===================================================================================

sudo dpkg-reconfigure unattended-upgrades
