#!/bin/bash -l

#SBATCH --job-name=pull_images
#SBATCH --ntasks=1
#SBATCH --time=06:00:00

# r
singularity exec docker://rocker/tidyverse:3.6.1 echo ciao

# python
singularity exec docker://jupyter/datascience-notebook:latest echo ciao

# mpi
singularity exec docker://quay.io/pawsey/openfoamlibrary:v2012 echo ciao

# bonus
singularity exec docker://marcodelapierre/gnuplot:5.2.2_4 echo ciao
