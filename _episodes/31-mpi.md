---
title: "MPI containers"
teaching: 15
exercises: 10
questions:
objectives:
- Discuss the steps required to configure and run MPI applications from a container
- Discuss the performance of parallel applications inside containers *versus* regular runs
keypoints:
- You need to build your application in the container with an MPI version which is ABI compatible with MPI libraries in the host
- Appropriate environment variables and bind mounts are required at runtime to make the most out of MPI applications (sys admins can help)
- Singularity interfaces almost transparently with HPC schedulers such as Slurm
- MPI performance of containerised applications almost coincide with those of a native run when host MPI properly exposed to container
---

### Let's run a MPI-enabled application in a container!

We're going to start this episode with actually running a practical example, and then discuss the way this all works later on. We're using OpenFoam, a widely popular package for Computational Fluid Dynamics simulations, which is able to massively scale in parallel architectures up to thousands of processes, by leveraging an MPI library.  The sample inputs come straight from the OpenFoam installation tree, namely `$FOAM_TUTORIALS/incompressible/pimpleFoam/LES/periodicHill/steadyState/`.

First, cd into a demo directory and download the OpenFoam (computational fluid dynamics simulation code) container image from [quay.io](https://quay.io/repository/pawsey/openfoam?tab=info):

```
$ cd $TUTO/demo/openfoam/
$ singularity pull docker pull quay.io/pawsey/openfoam
```
{: .bash}

Now, let us run the sample simulation. OpenFoam first generates initial conditions in serial and then runs a simulation with MPI. A sample script for running the container is provided in the demo directory (to directly copy the script without cloning this tutorial repo, copy [this file](https://github.com/PawseySC/hpc-container-training/blob/gh-pages/demos/openfoam/mpi_mpirun.sh)). Run the script:

```
$ ./mpi_mpirun.sh
```
{: .bash}

**Alternatively**, if you're running this example on Pawsey systems (*e.g.* Magnus or Zeus), achieve the same result by using the Slurm scheduler to submit the job script `mpi_slurm.sh`:

```
$ sbatch mpi_slurm.sh
```
{: .bash}

The run will take a couple of minutes. When it's finished, the directory contents will look a bit like this one:

```
$ ls -ltr
```
{: .bash}

```
total 80
-rwxr-xr-x 1 user000 tutorial  1304 Nov 16 17:36 update-settings.sh
drwxr-xr-x 2 user000 tutorial   141 Nov 16 17:36 system
-rw-r--r-- 1 user000 tutorial   871 Nov 16 17:36 mpi_pawsey.sh
-rwxr-xr-x 1 user000 tutorial   789 Nov 16 17:36 mpi_mpirun.sh
drwxr-xr-x 2 user000 tutorial    59 Nov 16 17:36 0
drwxr-xr-x 4 user000 tutorial    72 Nov 16 22:45 dynamicCode
drwxr-xr-x 3 user000 tutorial    77 Nov 16 22:45 constant
-rw-rw-r-- 1 user000 tutorial  3493 Nov 16 22:45 log.blockMesh
-rw-rw-r-- 1 user000 tutorial  1937 Nov 16 22:45 log.topoSet
-rw-rw-r-- 1 user000 tutorial  2300 Nov 16 22:45 log.decomposePar
drwxr-xr-x 8 user000 tutorial    70 Nov 16 22:47 processor1
drwxr-xr-x 8 user000 tutorial    70 Nov 16 22:47 processor0
-rw-rw-r-- 1 user000 tutorial 18569 Nov 16 22:47 log.simpleFoam
drwxr-xr-x 3 user000 tutorial    76 Nov 16 22:47 20
-rw-r--r-- 1 user000 tutorial 28617 Nov 16 22:47 slurm-10.out
-rw-rw-r-- 1 user000 tutorial  1529 Nov 16 22:47 log.reconstructPar
```
{: .output}

We ran using *2 MPI* processes, who created outputs in the directories `processor0` and `processor1`, respectively.  The final reconstruction creates results in the directory `20` (which stands for the *20th* and last simulation step in this very short demo run).

What has just happened?


### A batch script for MPI applications with containers

Let's get back to the directory path for the first example:

```
$ cd $TUTO/demos/openfoam
```
{: .bash}

and have a look at the content of the script `mpi_mpirun.sh`:

```
#!/bin/bash

NTASKS="2"

# this configuration depends on the host
export MPICH_ROOT="/opt/mpich/mpich-3.1.4/apps"

export SINGULARITY_BINDPATH="$MPICH_ROOT"
export SINGULARITYENV_LD_LIBRARY_PATH="$MPICH_ROOT/lib:\$LD_LIBRARY_PATH"


# pre-processing
singularity exec openfoam_v2012.sif \
  blockMesh | tee log.blockMesh

singularity exec openfoam_v2012.sif \
  topoSet | tee log.topoSet

singularity exec openfoam_v2012.sif \
  decomposePar -fileHandler uncollated | tee log.decomposePar


# run OpenFoam with MPI
mpirun -n $NTASKS \
  singularity exec openfoam_v2012.sif \
  simpleFoam -fileHandler uncollated -parallel | tee log.simpleFoam


# post-processing
singularity exec openfoam_v2012.sif \
  reconstructPar -latestTime -fileHandler uncollated | tee log.reconstructPar
```
{: .bash}


### How does Singularity interplay with the MPI launcher?

We'll comment on the environment variable definitions soon, now let's focus on the set of commands that make the simulation happen.

In particular, the fourth command is the only one using multiple processors through MPI:

```
mpirun -n $NTASKS \
  singularity exec openfoam_v2012.sif \
  simpleFoam -fileHandler uncollated -parallel | tee log.simpleFoam
```
{: .bash}

Here, `mpirun` is the MPI launcher, *i.e.* the tool that is in charge for spawning the multiple MPI processes that will make the workflow run in parallel.  
Note how `singularity` can be executed through the launcher as any other application would.

Similarly, for running MPI applications through Slurm, the `srun` command is used in `mpi_slurm.sh`:

```
#!/bin/bash -l

#SBATCH --job-name=mpi
#SBATCH --ntasks=2
#SBATCH --ntasks-per-node=2
#SBATCH --time=00:20:00

image="docker://quay.io/pawsey/openfoamlibrary:v2012"

# this configuration depends on the host
module load singularity

# pre-processing
srun -n 1 \
  singularity exec $image \
  blockMesh | tee log.blockMesh

srun -n 1 \
  singularity exec $image \
  topoSet | tee log.topoSet

srun -n 1 \
  singularity exec $image \
  decomposePar -fileHandler uncollated | tee log.decomposePar


# run OpenFoam with MPI
srun -n $SLURM_NTASKS \
  singularity exec $image \
  simpleFoam -fileHandler uncollated -parallel | tee log.simpleFoam


# post-processing
srun -n 1 \
  singularity exec $image \
  reconstructPar -latestTime -fileHandler uncollated | tee log.reconstructPar
```
{: .bash}

Under the hood, the MPI processes outside of the container (spawned by `mpirun` or `srun`) will work in tandem with the containerized MPI code to instantiate the job.  
There are a few implications here ...

### Requirements for the MPI + container combo

Let's discuss what the above mentioned implications are.
* A host MPI installation must be present to spawn the MPI processes.
* An MPI installation is required in the container, to compile the application. Also, during build the application must be linked *dynamically* to the MPI libraries, so as to have the capability of using the host ones at runtime.
    * *Statically* linking MPI libraries at compilation time will force the application to use the MPI library present inside the container, which may lead to compatibility issues with the hosts MPI library and neglect any optimisations present in the host MPI installation. Note: dynamic linking is typically the default behaviour on Linux systems.

A specific section of the recipe file needs to take care of this, or in alternative the base image for the recipe needs to have the MPI libraries.  Either way, if we take the example of a *def file* for the *MPICH* flavour of MPI, the code would look like:

```
%post

[..]

MPICH_VERSION="3.1.4"
MPICH_CONFIGURE_OPTIONS="--enable-fast=all,O3 --prefix=/usr"

mkdir -p /tmp/mpich-build
cd /tmp/mpich-build

wget http://www.mpich.org/static/downloads/${MPICH_VERSION}/mpich-${MPICH_VERSION}.tar.gz
tar xvzf mpich-${MPICH_VERSION}.tar.gz

cd mpich-${MPICH_VERSION}

./configure ${MPICH_CONFIGURE_OPTIONS}
make
make install

ldconfig

[..]
```
{: .bash}


> ## Base MPI image at Pawsey
>
> Pawsey maintains an MPICH base image at [pawsey/mpich-base](https://quay.io/pawsey/mpich-base).  
> At the moment, only a Docker image is provided, which of course can also be used by Singularity.
{: .callout}


* The container and host MPI installations need to be *ABI* (Application Binary Interface) *compatible*. This is because the application in the container is built with the former but runs with the latter.  
At present, there are just two families of MPI implementations not ABI compatible with each other: MPICH (with IntelMPI and MVAPICH) and OpenMPI.  If you anticipate your application will run in systems with non ABI compatible libraries, you will need to build variants of the image for the two MPI families.

> ## MPI implementations at Pawsey
>
> At present, all Pawsey systems have installed at least one MPICH ABI compatible implementation: CrayMPICH on the Crays (*Setonix* *Magnus* and *Galaxy), IntelMPI on *Zeus* and *Topaz*.  Therefore, MPICH is the recommended MPI library to install in container images.  
> Zeus and Topaz also have OpenMPI, so images built over this MPI family can run in these clusters, upon appropriate configuration of the shell environment (see below).
{: .callout}


* Bind mounts and environment variables need to be setup so that the containerised MPI application can use the host MPI libraries at runtime. Bind mounts can be configured by the administrators, or set up through variables. We're discussing the latter way here. The current example script has:

```
export MPICH_ROOT="/opt/mpich/mpich-3.1.4/apps"

export SINGULARITY_BINDPATH="$MPICH_ROOT"
export SINGULARITYENV_LD_LIBRARY_PATH="$MPICH_ROOT/lib:\$LD_LIBRARY_PATH"
```
{: .bash}

Here, `SINGULARITY_BINDPATH` bind mounts the host path where the MPI installation is (MPICH in this case).  The second variable, `SINGULARITYENV_LD_LIBRARY_PATH`, ensures that at runtime the container's `LD_LIBRARY_PATH` has the path to the MPICH libraries.

> ## Interconnect libraries and containers
>
> If the HPC system you're using has high speed interconnect infrastructure, than it will also have some system libraries to handle that at the application level.  These libraries will need to be exposed to the containers, too, similar to the MPI libraries, to ensure maximum performance are achieved.  
> This can be a challenging task for a user, as it requires knowing details on the installed software stack.  System administrators should be able to assist in this regard.
{: .callout}

> ## Singularity environment variables at Pawsey
>
> In all Pawsey systems, the Singularity module sets up all of the required variables for MPI and interconnect libraries.  So this will do the job:
>
> ```
> $ module load singularity
> ```
> {: .bash}
{: .callout}



### MPI performance: container *vs* bare metal

What's the performance overhead in running an MPI application through containers? So long as the container engine has been run to utilise the host's MPI library, the difference is typically quite small.
The benchmark figures using the OSU MPI test suite below reveal percent differences.

> ## Performance of MPI communication using OSU test using host MPI libraries
> <!-- ![OSU bandwidth test]({{ page.root }}/fig/OSU_Bandwidth.png) --> <img src="{{ page.root }}/fig/OSU_Bandwidth.png" alt="OSU bandwidth test" width="651" height="489"/>
> <!-- ![OSU point-to-point latency test]({{ page.root }}/fig/OSU_Latency_P2P.png) --> <img src="{{ page.root }}/fig/OSU_Latency_P2P.png" alt="OSU point-to-point latency test" width="651" height="489"/>
> <!-- ![OSU collective latency test]({{ page.root }}/fig/OSU_Latency_Coll.png) --> <img src="{{ page.root }}/fig/OSU_Latency_Coll.png" alt="OSU collective latency test" width="651" height="489"/>
{: .callout}

### How you should build containers requiring MPI
The benchmarking provided by OSU test suite actually provides an excellent way of checking that MPI is running correctly in a container. Poor performance or MPI errors can be identified early in the container build process by including these tests in the container.
> ## Recommendations for MPI applications
> - Build base MPI containers, one for each ABI MPI library (e.g., OpenMPI and MPICH)
> - Build MPI tests suite, [OSU micro-benchmarks](https://ulhpc-tutorials.readthedocs.io/en/latest/parallel/mpi/OSU_MicroBenchmarks/) for each of these MPI containers
> - Build your application for each variant of MPI using the OSU base container.
{: .checklist}
