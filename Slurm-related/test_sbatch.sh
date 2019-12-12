#!/bin/bash

#SBATCH --job-name=example
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --time=10:00
#SBATCH --mem=10
#SBATCH --partition=debug
#SBATCH --output=%x.o%j
#SBATCH --mail-user=coyleej
#SBATCH --mail-type=BEGIN,END,FAIL

echo "Hello World!"
echo "running job"
sleep 120
echo "bye"
