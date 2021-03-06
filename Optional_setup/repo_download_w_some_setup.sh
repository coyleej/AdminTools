#!/bin/bash

#===================================================================================
#
#          FILE:  repo_download_w_some_setup.sh
#
#   DESCRIPTION:  Downloads all of our repositories and installs the ones that don't
#                 have to be compiled
#
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Eleanor Coyle, ecoyle@azimuth-corp.com
#       COMPANY:  Azimuth Corporation
#       VERSION:  1.0
#       CREATED:  2019-02-27
#      REVISION:  2019-12-12
#
#===================================================================================

### Download repos ###
mkdir ~/Code
cd ~/Code

echo "Downloading Pybind11, OpenBLAS, S4, MANTIS, and signac (develop branch) ..."

if [ ! -d pybind11 ]; then 
	git clone https://github.com/pybind/pybind11
fi
echo ""

if [ ! -d OpenBLAS ]; then 
	git clone https://github.com/xianyi/OpenBLAS
fi
echo ""

if [ ! -d S4 ]; then 
	git clone https://github.com/harperes/S4.git
fi
echo ""

if [ ! -d MANTIS ]; then 
	git clone https://github.com/harperes/MANTIS.git
fi
echo ""

if [ ! -d signac ]; then 
	git clone https://bitbucket.org/glotzer/signac.git
	cd signac
	git checkout develop
	cd ..
fi

### Sanity check ###
echo "Checking for conda installation..."
if [ -d /opt/miniconda ] || [ -d ~/.conda ]; then
	echo "Conda is installed. Setting up MANTIS and signac..."
	echo ""
else
	echo "ERROR: conda is NOT installed. Terminating setup..."
	exit 1;
fi

### Start setup ###
sudo apt install cmake cmake-curses-gui ninja-build gfortran libfftw3-dev libopenmpi-dev python3-dev python3-numpy python-dev python-numpy python3-mpi4py python3-pip python3-pytest

### MANTIS install ###
# Preserving Eric's needless pip3 paranoia
echo "Installing MANTIS..."
cd ~/Code/MANTIS
sudo pip3 install . --target="/opt" --no-deps --no-dependencies

# Update paths
envfile=/etc/environment
grep MANTIS $envfile || sudo sed -i.bak "/^PATH/ s|=\"|=\"/opt/MANTIS:|" $envfile
grep ^PYTHONPATH $envfile || sudo sed -i.bak "/^PATH/ a\PYTHONPATH=\/\"opt\"" $envfile
echo ""

### Signac install ###
# (path modification covered by MANTIS install) 
echo "Installing Signac..."
cd ~/Code/signac
sudo pip3 install . --target="/opt" --no-deps --no-dependencies

### Test MANTIS install ###
echo "Testing MANTIS install..."
echo ""
if [ ! -d ~/.conda/envs/s4py ]; then
	cd files
	conda env create -f s4py.yml;
	cd ../
fi

# Checks if you are already a conda environment
condaEnv=$(conda info | grep 'active enviro' | sed 's/ //g' | cut -d ':' -f 2)
if [ $condaEnv != None ]; then
	# fixes it if not
	condaVer=$(conda --version | cut -d " " -f 2)
	if [ $condaVer = "4.5.11" ]; then 
		source activate s4py;
	else
		conda activate s4py;
	fi
fi

# The unit test will only work after logging in again
#cd ~/Code/MANTIS/tests
#python -m unittest

# Print /etc/environment to the screen
echo ""
echo "Please doublecheck that /etc/environment is correct:"
cat $envfile
echo ""

echo "NOTE: All required dependencies have been downloaded with apt or git"
echo ""
echo "NOTE: Pybind11, OpenBLAS, and S4 have beeen downloaded but not installed"
echo "They must be compiled manually."
echo "MANTIS is useless without these three packages!"
echo ""

echo "If you wish to check that MANTIS installed properly you must"
echo "log out, log back in, and run the following:"
echo ""
echo "$ cd ~/Code/MANTIS/tests"
echo "$ python -m unittest"

