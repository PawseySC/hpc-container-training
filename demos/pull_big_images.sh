#!/bin/bash

# executing a dummy command just to cause images to be downloaded in the cache

# mpi
singularity exec docker://quay.io/repository/pawsey/mpich-base: echo ciao
singularity exec docker://quay.io/pawsey/openfoamlibrary:v2012 echo ciao

# python
singularity exec docker://python:3.9-slim echo ciao
singularity exec docker://jupyter/datascience-notebook:latest echo ciao

# r
#singularity exec docker://rocker/tidyverse:3.6.1 echo ciao

# bonus
# singularity exec docker://marcodelapierre/gnuplot:5.2.2_4 echo ciao
