#!/bin/bash

### Download repos ###
mkdir ~/Code
cd ~/Code

git clone https://github.com/pybind/pybind11
git clone https://github.com/xianyi/OpenBLAS
git clone https:github.com/harperes/S4.git
git clone https://github.com/harperes/MANTIS.git
git clone https://bitbucket.org/glotzer/signac.git
git checkout develop

echo "Downloaded Pybind11, OpenBLAS, S4, MANTIS, and signac (checked out develop branch)"

### Sanity check ###
echo "Checking for conda installation..."
if [ -d /opt/miniconda || -d ~/.conda]; then
	echo "Conda is installed. Setting up MANTIS and signac..."
	echo ""
else
	echo "ERROR: conda is NOT installed. Terminating setup..."
	exit 1;
fi

### Start setup ###
envfile=/etc/environment
sudo apt install python3-pip

### MANTIS install ###
# Preserving Eric's needless pip3 paranoia
echo "Installing MANTIS..."
cd ~/Code/MANTIS
sudo pip3 install . --target="/opt" --no-deps --no-dependencies

# Update paths
grep MANTIS $envfile || sudo sed -i.bak "/^PATH/ s|=\"|=\"/opt/MANTIS:|" $envfile
grep ^PYTHONPATH $envfile || sudo sed -i.bak "/^PATH/ a\PYTHONPATH=\/opt/" $envfile

### Signac install ###
# (path modification covered by MANTIS install) 
echo "Installing Signac..."
cd ~/Code/signac
sudo pip3 install . --target="/opt" --no-deps --no-dependencies

# Test MANTIS install ###
echo "Testing MANTIS install..."
echo ""
if [ ! -d ~/.conda/envs/s4py ]; then
	conda env create -f s4py.yml;
fi

condaver=$(conda --version | cut -d " " -f 2)
if [ $condaver = "4.5.11" ]; then 
	source activate s4py;
else
	conda activate s4py;
fi

cd ~/Code/MANTIS/tests
python -m unittest

# Print /etc/environment to the screen
echo ""
echo "Please doublecheck that /etc/environment is correct:"
cat $envfile
echo ""

echo "NOTE: Pybind11, OpenBLAS, and S4 have beeen downloaded but not installed"
echo "They must be installed manually."
echo "MANTIS is useless without these three packages!"
