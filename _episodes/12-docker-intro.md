---
title: "Basics of Docker"
teaching: 15
exercises: 10
questions:
objectives:
- Download container images
- Run commands from inside a container
- Discuss what are the most popular image registries
keypoints:
- Docker containers are widely used and available from a number of online repositories
    - The most commonly used registries are Docker Hub, Red Hat Quay and BioContainers
- Execute commands in containers with `docker run`
- Open a shell in a container with `docker run -it`
- Download a container image in a selected location with `docker pull`
#- You should not use the `latest` tag, as it may limit workflow reproducibility
---


### Docker

[Docker](https://hub.docker.com/search/?type=edition&offering=community) is a tool that allows you to easily create, deploy, and run applications on any architecture.  It does this via something called **containers**, which is a way for you to package up an application and all of its dependencies, into a single object that's easy to track, manage, share, and deploy. It has been the first container engine to get widespread popularity. It has achieved this mostly in the world of IT companies, where it can be a very effective tool in the hands of system administrators, to deploy all sorts of micro-services.  It can also be a useful engine for running containers in laptops, personal workstations, and cloud VMs.  Among its advantages:

* *root* execution allows for complete control and customisation;
* *isolation* over *integration*: by default Docker runs containers in complete isolation compared to the host, with highest security.  Users are in control of plugging in additional host features, such as directories/volumes, networks, communications ports;
* *docker-compose* to define and run multi-container applications, allowing to manage complex workflows; *e.g.* this can make Docker convenient for deploying long running services including Jupyter and RStudio servers;
* caching of exited containers, to eventually restart them;
* layered image format allows for caching of container building steps during build time, reducing development time.

On the other hand, some features make it not ideal for HPC.  These include:

* users need *root* privileges to run it, which is not really a good idea in a shared system;
* *isolation* over *integration* means users need to get used to a more articulated syntax to get things working with typical HPC applications;
* no support offered to interface Docker with MPI runtime, or HPC schedulers;
* usually requires an up-to-date kernel.

As you might encounter Docker in your container journey, let's have a quick look at how the syntax looks like for the most basic operations.

To get a more detailed introduction on Docker containers, see this other workshop on [Container workflows with Docker](https://pawseysc.github.io/container-workflows/).



> ## A word of warning: sudo ##
>
> Docker requires `sudo`, i.e. `root`, privileges to be used. The major implication is that commands and applications have the potential to damage the host operating system and filesystem, with no root password required. By default, no host directory is visible inside containers, which greatly reduces chances of harm. In a subsequent episode we'll see how to selectively map host directories to the container for input/output.
>
> A second consequence is that if you're running on a computer where you have limited user permissions (i.e. university/corporate computers), you might have troubles in running Docker, or even installing it. If this happens, you will need to get in touch with your IT services to figure out a workable solution.
>
> Third, to run Docker commands with `root` privileges on a Linux box, you will need to prepend them with `sudo`. There's a three-step procedure to follow if you want to avoid having to type `sudo` all the time (again, you might need IT support). See instructions at [Manage Docker as a non-root user](https://docs.docker.com/install/linux/linux-postinstall/).
>
> **Always** keep in mind that any Docker action is run as **root**!
{: .callout}


### Running a simple command in a container ###

Let's run a simple command:

```
$ docker run ubuntu cat /etc/os-release
```
{: .bash}

```
Unable to find image 'ubuntu:latest' locally
latest: Pulling from library/ubuntu
898c46f3b1a1: Pull complete
63366dfa0a50: Pull complete
041d4cd74a92: Pull complete
6e1bee0f8701: Pull complete
Digest: sha256:017eef0b616011647b269b5c65826e2e2ebddbe5d1f8c1e56b3599fb14fabec8
Status: Downloaded newer image for ubuntu:latest

NAME="Ubuntu"
VERSION="18.04.2 LTS (Bionic Beaver)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 18.04.2 LTS"
VERSION_ID="18.04"
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
VERSION_CODENAME=bionic
UBUNTU_CODENAME=bionic
```
{: .output}

Here's what we've done:

* Downloaded an Ubuntu Docker image (this wouldn't happen if the image had been downloaded previously)
* Created a container from our Ubuntu image
* The command we've run inside the Ubuntu container is `cat /etc/os-release`, which simply prints some info about the operating system

Docker images have a **name** and a **tag**. The default for the tag is 'latest', and can be omitted (but be careful...more on this later). If you ask docker to run an image that is not present on your system, it will download it from [Docker Hub](https://hub.docker.com) first, then run it.

Most Linux distributions have pre-built images available on Docker Hub, so you can readily find something to get you started. Let's start with the official Ubuntu linux image, and run a simple 'hello world'. The `docker run` command takes options first, then the image name, then the command and arguments to run follow it on the command line:


Note in our example Docker uses the 'ubuntu:latest' tag, since we didn't specify what version we want.  We can specify a specific version of ubuntu like this:

```
$ docker run ubuntu:17.04 cat /etc/os-release
```
{: .bash}

```
NAME="Ubuntu"
VERSION="17.04 (Zesty Zapus)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 17.04"
VERSION_ID="17.04"
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
VERSION_CODENAME=zesty
UBUNTU_CODENAME=zesty
```
{: .output}

Docker caches images on your local disk, so the next time you need to run your container it will be faster:

```
$ docker run ubuntu /bin/echo 'hello world'
```
{: .bash}

```
hello world
```
{: .output}

You can list all Docker containers on your system with

```
$ docker ps -a
```
{: .bash}

The `-a` (or `--all`) flag prints all containers, i.e. those currently running and any stopped containers.

Similarly, you can list all docker images you have with

```
$ docker images
```
{: .bash}

In the example above, Docker automatically downloaded the Ubuntu image.  If you want to explicitly download an image, you can use the `docker pull` command:

```
$ docker pull ubuntu
```
{: .bash}

Another handy Docker command line option is `docker search`.  You can use it to quickly search for available images on Docker Hub.  Note that you may still want to visit the [Docker Hub](https://hub.docker.com) webpage to find out more information about a particular image (e.g. run commands, configuration instructions, etc.).

```
$ docker search tensorflow
```
{: .bash}

```
NAME                                DESCRIPTION                                     STARS               OFFICIAL            AUTOMATED
tensorflow/tensorflow               Official Docker images for the machine learn…   1236
jupyter/tensorflow-notebook         Jupyter Notebook Scientific Python Stack w/ …   100
xblaster/tensorflow-jupyter         Dockerized Jupyter with tensorflow              52                                      [OK]
tensorflow/serving                  Official images for TensorFlow Serving (http…   31
floydhub/tensorflow                 tensorflow                                      15                                      [OK]
bitnami/tensorflow-serving          Bitnami Docker Image for TensorFlow Serving     13                                      [OK]
opensciencegrid/tensorflow-gpu      TensorFlow GPU set up for OSG                   7
tensorflow/tf_grpc_server           Server for TensorFlow GRPC Distributed Runti…   7
hytssk/tensorflow                   tensorflow image with matplotlib.pyplot.imsh…   3                                       [OK]
tensorflow/tf_grpc_test_server      Testing server for GRPC-based distributed ru…   3
mikebirdgeneau/r-tensorflow         RStudio and Tensorflow                          2                                       [OK]
lablup/kernel-python-tensorflow     TensorFlow container imager for Backend.Ai      2
bitnami/tensorflow-inception        Bitnami Docker Image for TensorFlow Inception   2                                       [OK]
```
{: .output}


### Running an interactive command in an image ###

Docker has the option to run containers interactively.  While this is convenient (and useful for debugging), in general you shouldn't use this model as your standard way of working with containers.  To run interactively, we just need to use the `-i` and `-t` flags, or `-it` for brevity:

```
$ docker run -i -t ubuntu /bin/bash
```
{: .bash}

```
root@c69d6f8d89bd:/# id
```
{: .bash}

```
uid=0(root) gid=0(root) groups=0(root)
```
{: .output}

```
root@c69d6f8d89bd:/# ls
```
{: .bash}

```
bin   dev  home  lib64  mnt  proc  run   srv  tmp  var
boot  etc  lib   media  opt  root  sbin  sys  usr
```
{: .output}

```
root@c69d6f8d89bd:/# exit   # or hit CTRL-D
```
{: .bash}

The `-t` and `-i` options make sure we allocate a terminal to the container, and keep its STDIN (standard input) open.

As you can see, you have root access in your container, and you are in what looks like a normal linux system. Now you can do whatever you like, e.g. install software and develop applications, all within the container of your choice.


> ## Pull and run a Python Miniconda container ##
>
> How would you pull the following container image, `continuumio/miniconda3:4.5.12`?
>
> Once you've pulled it, enquire the Python version inside the container by running `python --version`.
>
> Finally, open and then close an interactive Python console through the container.
>
> > ## Solution ##
> >
> > Pull:
> >
> > ```
> > $ docker pull continuumio/miniconda3:4.5.12
> > ```
> > {: .bash}
> >
> > Get Python version:
> >
> > ```
> > $ docker run continuumio/miniconda3:4.5.12 python --version
> > ```
> > {: .bash}
> >
> > Open and close an interactive console:
> >
> > ```
> > $ docker run -it continuumio/miniconda3:4.5.12 python
> > {: .bash}
> > ```
> > {: .bash}
> >
> > ```
> > >>> exit   # or hit CTRL-D
> > ```
> > {: .python}
> {: .solution}
{: .challenge}

### Exposing an image to the environment ###

As we mentioned above, lots of Docker defaults are about privileged runtime and container isolation.  Some extra syntax is required in order to achieve a container execution comparable to Singularity, *i.e.* with
* visibility of the host current working directory
* container working directory same as host one
* right user file ownership
* ability to pipe commands in the container

Long story short, this is what it takes:

```
$ sudo docker run --rm -v $(pwd):/data -w /data -u $(id -u):$(id -g) -i ubuntu:18.04 echo "Good Morning" >hello1.txt
$ ls -l hello1.txt
```
{: .bash}

```
-rw-r----- 1 ubuntu ubuntu 13 Nov  1 08:29 hello1.txt
```
{: .output}

Let's comment on the flags:
* `-v` is to bind mount host directories in the container
* `-w` is to set the container working directory
* `-u` is to set user/group in the container
* `-i` is to keep *STDIN* open in the container

What about the `--rm` flag? To respond to this, let's move on.

### Managing containers and images

By default, when containers exit, they remain cached in the system for potential future restart.  Have a look at a list of running and stopped containers with `docker ps -a` (remove `-a` to only list running ones):

```
$ sudo docker ps -a
```
{: .bash}

```
CONTAINER ID        IMAGE               COMMAND                 CREATED             STATUS                       PORTS               NAMES
375a021f8674        ubuntu:18.04        "bash"                  52 seconds ago      Exited (0) 4 seconds ago                         reverent_volhard
6000f459c132        ubuntu:18.04        "cat /etc/os-release"   57 seconds ago      Exited (0) 55 seconds ago                        hungry_bhabha

```
{: .output}

It's possible to clean up cached, exited containers by means of `docker rm`; there's also an idiomatic way to clean all of them at once:

```
$ sudo docker rm $(sudo docker ps -qa)
```
{: .bash}

```
375a021f8674
6000f459c132
```
{: .output}

If I know in advance I won't need to re-run a container after it exits, I can use the runtime flag `--rm`, as in `docker run --rm`, to clean it up automatically, as we did in the example above.


Docker stores container images in a hidden directory under its own control.  To get the list of downloaded images use `docker images`:

```
$ sudo docker images
```
{: .bash}

```
REPOSITORY                        TAG                      IMAGE ID            CREATED             SIZE
ubuntu                            18.04                    775349758637        10 hours ago        64.2MB
```
{: .output}

If you don't need an image any more and want to clear up disk space, use `docker rmi` to remove it:

```
$ sudo docker rmi ubuntu:18.04
```
{: .bash}

```
Untagged: ubuntu:18.04
Untagged: ubuntu@sha256:6e9f67fa63b0323e9a1e587fd71c561ba48a034504fb804fd26fd8800039835d
Deleted: sha256:775349758637aff77bf85e2ff0597e86e3e859183ef0baba8b3e8fc8d3cba51c
Deleted: sha256:4fc26b0b0c6903db3b4fe96856034a1bd9411ed963a96c1bc8f03f18ee92ac2a
Deleted: sha256:b53837dafdd21f67e607ae642ce49d326b0c30b39734b6710c682a50a9f932bf
Deleted: sha256:565879c6effe6a013e0b2e492f182b40049f1c083fc582ef61e49a98dca23f7e
Deleted: sha256:cc967c529ced563b7746b663d98248bc571afdb3c012019d7f54d6c092793b8b
```
{: .output}

> ## Best practices ##
>
> * Prefer official images over those built by third-parties. Docker runs with privileges, so you have to be a bit careful what you run
> * Good online documentation on Docker commands can be found at [Docker run reference](https://docs.docker.com/engine/reference/run/) and related pages
{: .callout}
