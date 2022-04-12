---
title: "Introduction to containers"
teaching: 10
exercises: 0
questions:
objectives:
- Define the term "container"
- Discuss when you would benefit from using containers in your workflow
keypoints:
- Containers enable you to package up an application and its dependencies.
- By using containers, you can better enforce reproducibility, portability and share-ability of your computational workflows.
---


### Containers vs Virtual Machines

A container is an entity providing an isolated software environment (or filesystem) for an application and its dependencies.  

If you have already used a Virtual Machine, or VM, you're actually already familiar with some of the concepts of a container.

<!-- ![Containers vs. VMs]({{ page.root }}/fig/container_vs_vm.png) -->
<img src="{{ page.root }}/fig/container_vs_vm.png" alt="Containers vs. VMs" width="619" height="331"/>

The key difference here is that VMs virtualise **hardware** while containers virtualise **operating systems**.  There are other differences (and benefits), in particular containers are:

* lighter weight to run (less CPU and memory usage, faster start-up times)
* smaller in size (thus easier to transfer and share)
* modular (possible to combine multiple containers that work together)

Since containers do not virtualise the hardware, containers must be built using the same architecture
as the machine they are going to be deployed on. For example, Pawsey systems use ubiquitous `x86_64` CPUs. There is a growing number of machines using `arm64` CPUs.
Containers built for one architecture cannot run on the other.

### Containers and your workflow

There are a number of reasons for using containers in your daily work:

* Data reproducibility/provenance
* Cross-system portability
* Simplified collaboration
* Simplified software dependencies and management
* Consistent testing environment

A few examples of how containers are being used at Pawsey include:

* Bioinformatics workflows
* Machine Learning
* Python apps in radio astronomy
* RStudio & Jupyter Notebook sessions
* Webservers
* OpenFoam simulations
* Cloud workflows (via Singularity or Docker)
* HPC workflows (via Singularity)

Here's an overview of what a typical workflow looks like:

<!-- ![Container Workflow]({{ page.root }}/fig/container_lifecycle.png) -->
<img src="{{ page.root }}/fig/container_lifecycle.png" alt="Container Workflow" width="716" height="298"/>

### Terminology

An **image** is a file (or set of files) that contains the application and all its dependencies, libraries, run-time systems, etc. required to run.  You can copy images around, upload them, download them etc.

A **container** is an instantiation of an image.  That is, it's a process in execution that got spawned out of an image.  You can run multiple containers from the same image, much like you might run the same application with different options or arguments.

In abstract, an image corresponds to a file, a container corresponds to a process.

A **registry** is a server application where images are stored and can be accessed by users.  It can be public (*e.g.* *Docker Hub*) or private.

To build an image we need a recipe.  A recipe file is called a **Definition File**, or **def file**, in the *Singularity* jargon and a **Dockerfile** in the *Docker* world.


### Container engines

A number of tools are available to create, deploy and run containerised applications.  Some of these will be covered throughout this tutorial:

* **Docker**: the first engine to gain popularity, still widely used in the IT industry.  Not very suitable for HPC as it requires *root* privileges to run. We'll use it mostly to build container images. See the extensive [online documentation](https://docs.docker.com/) for more information.

* **Singularity**: a simple, powerful *root*-less container engine for the HPC world. The main focus of this workshop. See the [user guide](https://sylabs.io/guides/latest/user-guide/) for extensive documentation.

* **Apptainer**: an open-source offshoot of **Singularity**. Provides all the same functionality as **Singularity** and moving forward will likely become the open-source standard. See the [user guide](https://apptainer.org/docs/user/main/) for extensive documentation.

Other container engines (not covered here) are

* **Shifter/Sarus**: a Docker-compatible container engine, suitable for HPC.  Can run containers, cannot build them.

* **Charliecloud**: a Docker-compatible tool for lightweight, user-defined software stacks for high-performance computing.

* **Enroot**: Nvidia's take on containers, a simple, yet powerful tool to turn traditional container/OS images into unprivileged sandboxes.

* **Podman**: a *root*-less alternative to Docker.  Catching up quickly with HPC requirements.

### Get ready for the hands-on

Before we start, let us ensure we have got the required files to run the tutorials.

If you haven't done it already, download the following Github repo.  Then `cd` into it, and save the current directory into a variable named `TUTO` for later use.

```
$ cd ~
$ git clone https://github.com/PawseySC/hpc-container-training
$ cd singularity-containers
$ export TUTO=$(pwd)
```
{: .bash}


> ## Want to save time later in the tutorial?
>
> > ## Read this
> > Open a second terminal in the machine where you're running the tutorial, then run the script `pull_big_images.sh` to start downloading a few images that you'll require later:
> >
> > ```
> > $ cd $TUTO/demos
> > $ nohup bash ./pull_big_images.sh &
> > ```
> > {: .bash}
> >
> > **Alternatively**, if you are running at Pawsey, *e.g.* on Zeus, submit this other script with Slurm instead:
> >
> > ```
> > $ cd $TUTO/demos
> > $ sbatch ./sbatch_pull_big_images.sh
> > ```
> > {: .bash}
> >
> > This pull process will take at least one hour. Meanwhile, you'll be able to keep on going with this episode in your main terminal window.
> >
> {: .solution}
{: .challenge}


> ## Are you running on a shared HPC system?
>
> If you're running this tutorial on a shared system (*e.g.* on Zeus or Magnus at Pawsey), you should use one of the compute nodes rather than the login node.  You can get this setup by using an interactive scheduler allocation, for instance on Zeus with Slurm:
>
> ```
> $ salloc -n 1 -t 4:00:00
> ```
> {: .bash}
>
> ```
> salloc: Granted job allocation 3453895
> salloc: Waiting for resource configuration
> salloc: Nodes z052 are ready for job
> ```
> {: .output}
{: .callout}
