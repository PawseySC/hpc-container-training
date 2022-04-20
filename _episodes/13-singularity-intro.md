---
title: "Basics of Singularity"
teaching: 20
exercises: 10
questions:
objectives:
- Download container images
- Run commands from inside a container
- Discuss what are the most popular image registries
- Discuss how environment variables can be provide to containerized applications
keypoints:
- Singularity can run both Singularity and Docker container images
- Execute commands in containers with `singularity exec`
- Open a shell in a container with `singularity shell`
- Download a container image in a selected location with `singularity pull`
- Use `SINGULARITYENV_` and `SINGULARITY_BINDPATH` to setup desired runtime environment
- You should not use the `latest` tag, as it may limit workflow reproducibility
- The most commonly used registries are Docker Hub, Red Hat Quay and BioContainers
---


### Singularity

As of November 2021 (**update!**), Singularity is now two distinct projects:
* [Apptainer](https://apptainer.org), now part of the Linux Foundation project, is maintained by [Apptainer](https://apptainer.org) on their [GitHub](https://github.com/apptainer/apptainer). This is the open-source verison of Singularity and provides all the same functionality. For details about this transition see [here](https://apptainer.org/news/community-announcement-20211130/).
* [SingularityCE](https://sylabs.io/singularity), maintained by [Sylabs](https://sylabs.io) on their [GitHub](https://github.com/sylabs/singularity).

These two variants are equivalent up until version 3.8.5, released on May 2021.

Singularity was designed from scratch as a container engine for HPC applications, which is clearly reflected in some of its main features:

* *unprivileged* runtime: Singularity containers do not require the user to hold root privileges to run (the Singularity executable needs to be installed and owned by *root*, though);
* *integration*, rather than *isolation*, by default: same user as host, same shell variables inherited by host, current directory bind mounted, communication ports available; as a result, launching a container requires a much simpler syntax than Docker;
* interface with job schedulers, such as *Slurm* or *PBS*;
* ability to run MPI enabled containers using host libraries;
* native execution of GPU enabled containers;
* unfortunately, *root* privileges are required to build container images: users can build images on their personal laptops or workstations, on the cloud, or via a Remote Build service.

This tutorial assumes Singularity version 3.0 or higher.  Version **3.7.0 or higher** is recommended as it offers a smoother, more bug-free experience.


### Executing a simple command in a Singularity container

For these first exercises, we're going to use a plain *Ubuntu* container image.  It's small and quick to download, and will allow use to get to know how containers work by using common Linux commands.  

Within the tutorial directory, let us cd into `demos/singularity`:

```bash
$ cd $TUTO/demos/singularity
```
{: .source}

Running a command is done by means of `singularity exec`:

```bash
$ singularity exec library://ubuntu:16.04 cat /etc/os-release
```
{: .source}

```
INFO:    Downloading library image

NAME="Ubuntu"
VERSION="16.04.5 LTS (Xenial Xerus)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 16.04.5 LTS"
VERSION_ID="16.04"
HOME_URL="http://www.ubuntu.com/"
SUPPORT_URL="http://help.ubuntu.com/"
BUG_REPORT_URL="http://bugs.launchpad.net/ubuntu/"
VERSION_CODENAME=xenial
UBUNTU_CODENAME=xenial
```
{: .output}

Here is what Singularity has just done:

* downloaded a Ubuntu image from the Cloud Library (this would be skipped if the image had been downloaded previously);
* stored it into the default cache directory;
* instantiated a container from that image;
* executed the command `cat /etc/os-release`.

Container images have a **name** and a **tag**, in this case `ubuntu` and `16.04`.  The tag can be omitted, in which case Singularity will default to a tag named `latest`.


> ## Using the *latest* tag
>
> The practice of using the `latest` tag can be handy for quick typing, but is dangerous when it comes to reproducibility of your workflow, as under the hood the *latest* tag could point to different images over time.
{: .callout}


Here Singularity pulled the image from an online image registry, as represented
in this example by the prefix `library://`, that corresponds to the [**Sylabs Cloud Library**](https://cloud.sylabs.io).
Images in there are organised as: `<user>/<project>/<name>:<tag>`.  In the example
above we didn't specify the **user**, `library`, and the **project**, `default`.  
Why?  Because the specific case of `library/default/` can be omitted.  The full specification is used in the next example:

```bash
$ singularity exec library://library/default/ubuntu:16.04 echo "Hello World"
```
{: .source}

```
Hello World
```
{: .output}

Here we are also experiencing image caching in action: the output has no more mention of the image being downloaded.

### Executing a command in a Docker container

Interestingly, Singularity is able to download and run Docker images as well.  
Let's try and download a Ubuntu container from the [**Docker Hub**](https://hub.docker.com),
*i.e.* the main registry for Docker containers:

```bash
$ singularity exec docker://ubuntu:16.04 cat /etc/os-release
```
{: .source}

```
INFO:    Converting OCI blobs to SIF format
INFO:    Starting build...
Getting image source signatures
Copying blob sha256:22e816666fd6516bccd19765947232debc14a5baf2418b2202fd67b3807b6b91
 25.45 MiB / 25.45 MiB [====================================================] 1s
Copying blob sha256:079b6d2a1e53c648abc48222c63809de745146c2ee8322a1b9e93703318290d6
 34.54 KiB / 34.54 KiB [====================================================] 0s
Copying blob sha256:11048ebae90883c19c9b20f003d5dd2f5bbf5b48556dabf06c8ea5c871c8debe
 849 B / 849 B [============================================================] 0s
Copying blob sha256:c58094023a2e61ef9388e283026c5d6a4b6ff6d10d4f626e866d38f061e79bb9
 162 B / 162 B [============================================================] 0s
Copying config sha256:6cd71496ca4e0cb2f834ca21c9b2110b258e9cdf09be47b54172ebbcf8232d3d
 2.42 KiB / 2.42 KiB [======================================================] 0s
Writing manifest to image destination
Storing signatures
INFO:    Creating SIF file...
INFO:    Build complete: /data/singularity/.singularity/cache/oci-tmp/a7b8b7b33e44b123d7f997bd4d3d0a59fafc63e203d17efedf09ff3f6f516152/ubuntu_16.04.sif

NAME="Ubuntu"
VERSION="16.04.6 LTS (Xenial Xerus)"
ID=ubuntu
ID_LIKE=debian
PRETTY_NAME="Ubuntu 16.04.6 LTS"
VERSION_ID="16.04"
HOME_URL="http://www.ubuntu.com/"
SUPPORT_URL="http://help.ubuntu.com/"
BUG_REPORT_URL="http://bugs.launchpad.net/ubuntu/"
VERSION_CODENAME=xenial
UBUNTU_CODENAME=xenial
```
{: .output}

Rather than just downloading a SIF file, now there's more work for Singularity,
as it has to both:
* download the various layers making up the image, and
* assemble them into a single SIF image file.

Note that, to point Singularity to Docker Hub, the prefix `docker://` is required.

Docker Hub organises images only by users (also called *repositories*), not by
projects: `<repository>/<name>:<tag>`.  In the case of the Ubuntu image, the
repository was `library` and could be omitted.


> ## What is the *latest* Ubuntu image from Docker Hub?
>
> Write down a Singularity command that prints the OS version through the *latest* Ubuntu image from Docker Hub.
>
> > ## Solution
> >
> > ```bash
> > $ singularity exec docker://ubuntu cat /etc/os-release
> > ```
> > {: .source}
> >
> > ```
> > [..]
> > NAME="Ubuntu"
> > VERSION="20.04 LTS (Focal Fossa)"
> > [..]
> > ```
> > {: .output}
> >
> > It's version 20.04.
> {: .solution}
{: .challenge}


### Open up an interactive shell

Sometimes it can be useful to open a shell inside a container, rather than to execute commands, *e.g.* to inspect its contents.

Achieve this by using `singularity shell`:

```bash
$ singularity shell docker://ubuntu:16.04
```
{: .source}

```
Singularity>
```
{: .output}

Remember to type `exit`, or hit `Ctrl-D`, when you're done!


### Download and use images via SIF file names

All examples so far have identified container images using their registry name specification, *e.g.* `docker://ubuntu:16.04` or similar.

An alternative option to handle images is to download them to a known location, and then refer to their full directory path and file name.

Let's use `singularity pull` to save the image to a specified path (output might differ depending on the Singularity version you use):

```bash
$ singularity pull docker://ubuntu:16.04
```
{: .source}

By default, the image is saved in the current directory:

```bash
$ ls
```
{: .source}

```
ubuntu_16.04.sif
```
{: .output}

Then you can use this image file by:

```bash
$ singularity exec ./ubuntu_16.04.sif echo "Hello World"
```
{: .source}

```
Hello World
```
{: .output}

You can specify the storage location with the `--dir` flag:

```bash
$ mkdir -p sif_lib
$ singularity pull --dir ~/path/to/sif/lib docker://library/ubuntu:16.04
```
{: .source}

Being able to specify download locations allows you to keep the local set of images organised and tidy, by making use of a directory tree.  It also allows for easy sharing of images within your team in a shared resource.  In general, you will need to specify the location of the image upon execution, *e.g.* by defining a dedicated variable:

```bash
$ export image="~/path/to/sif/lib/ubuntu_16.04.sif"
$ singularity exec $image echo "Hello Again"
```
{: .source}

```
Hello Again
```
{: .output}


### Manage the image cache

When pulling images, Singularity stores images and blobs in a cache directory.

The default directory location for the image cache is `$HOME/.singularity/cache`.  This location can be inconvenient in shared resources such as HPC centres, where often the disk quota for the home directory is limited.  You can redefine the path to the cache dir by setting the variable `SINGULARITY_CACHEDIR`.

If you are running out of disk space, you can inspect the cache with this command (omit `-v` before Singularity version 3.4):

```bash
$ singularity cache list -v
```
{: .source}

```
NAME                     DATE CREATED           SIZE             TYPE
ubuntu_latest.sif        2020-06-03 05:48:16    28.11 MB         library
ubuntu_16.04.sif         2020-06-03 05:47:25    37.04 MB         library
ubuntu_16.04.sif         2020-06-03 05:48:50    37.08 MB         oci
53e3366ec435596bed2563   2020-06-03 05:48:39    0.17 kB          blob
8a8a00d36ef8c18c877a5d   2020-06-03 05:48:41    0.81 kB          blob
9387a5fd608d7a23de5064   2020-06-03 05:48:41    2.48 kB          blob
b9fd7cb1ff8f489cf08278   2020-06-03 05:48:37    0.53 kB          blob
e92ed755c008afc1863a61   2020-06-03 05:48:36    44.25 MB         blob
ee690f2d57a128744cf4c5   2020-06-03 05:48:38    0.85 kB          blob

There are 3 container file(s) using 102.24 MB and 6 oci blob file(s) using 44.25 MB of space
Total space used: 146.49 MB
```
{: .output}

we are not going to clean the cache in this tutorial, as cached images will turn out useful later on.  Let us just perform a dry-run using the `-n` option:

```bash
$ singularity cache clean -n
```
{: .source}

```
User requested a dry run. Not actually deleting any data!
Removing /home/ubuntu/.singularity/cache/library
Removing /home/ubuntu/.singularity/cache/oci-tmp
Removing /home/ubuntu/.singularity/cache/shub
Removing /home/ubuntu/.singularity/cache/oci
Removing /home/ubuntu/.singularity/cache/net
Removing /home/ubuntu/.singularity/cache/oras
```
{: .output}

If we really wanted to wipe the cache, we would need to use the `-f` flag instead (or, before Singularity version 3.4, the `-a` flag).


> ## Contextual help on Singularity commands
>
> Use `singularity help`, optionally followed by a command name, to print help information on features and options.
{: .callout}


### Files inside a container

What directories and files can we access from the container? First, let us assess
what the content of the root directory `/` looks like from outside *vs* inside the container,
to highlight the fact that a container runs on its own filesystem:

From a host system:
```bash
$ ls /
```
{: .bash}

```
bin  boot  dev  etc  home  lib  lib64  media  mnt  opt  proc  root  run  sbin  scratch  shared  srv  sys  tmp  usr  var
```
{: .output}

Inside a container:

```bash
$ singularity exec docker://ubuntu:18.04 ls /
```
{: .bash}

```
bin  boot  data  dev  environment  etc	home  lib  lib64  media  mnt  opt  proc  root  run  sbin  singularity  srv  sys  tmp  usr  var
```
{: .output}


> ## In which directory is the container running?
> The question that naturally occurs is what host directories are automatically bind
> mounted if any? Let's find out.
> ```bash
> $ mkdir -p $TUTO/foo
> $ cd $TUTO/foo
> $ pwd
> ```
> {: .source}
> ```
> /home/ubuntu/hpc-container-training/foo
> ```
> {: .output}
> Now inspect the container.  (**Hint**: you need to run `pwd` in the container)
> > ## Solution
> > ```bash
> > $ singularity exec docker://ubuntu:18.04 pwd
> > ```
> > {: .source}
> > ```
> > /home/ubuntu/hpc-container-training/foo
> > ```
> > {: .output}
> > The current working directory from where singularity is launched is
> > always bind mounted.
> {: .solution}
{: .challenge}

> ## How about other directories in the host?
>
> For instance, let us inspect `$TUTO/_episodes`.
>
> > ## Solution
> >
> > ```
> > $ singularity exec docker://ubuntu:18.04 ls $TUTO/_episodes
> > ```
> > {: .bash}
> >
> > ```
> > ls: cannot access '/home/ubuntu/hpc-containers/_episodes': No such file or directory
> > ```
> > {: .output}
> >
> > Host directories external to the current directory are not visible!  How can we fix this?  Read on...
> {: .solution}
{: .challenge}

### Bind mounting host directories

Singularity has the runtime flag `--bind`, `-B` in short, to mount host directories.

There is a long syntax, which allows to map the host dir onto a container dir with
a different name/path, `-B hostdir:containerdir`.  
There is also a short syntax, that just mounts the dir
using the same name and path: `-B hostdir`.

Let's use the latter syntax to mount `$TUTO` into the container and re-run `ls`.

```bash
$ singularity exec -B $TUTO docker://ubuntu:18.04 ls -Fh $TUTO/assets
```
{: .source}

```
css/   fonts/ img/   js/
```
{: .output}

Also, we can write files in a host dir which has been bind mounted in the container:

```bash
$ singularity exec -B $TUTO docker://ubuntu:18.04 touch $TUTO/my_example_file
$ ls my_example_file
```
{: .source}

```
my_example_file
```
{: .output}

If you need to mount multiple directories, you can either repeat the `-B` flag multiple times, or use a comma-separated list of paths, *i.e.*

```bash
singularity -B dir1,dir2,dir3 ...
```
{: .source}

Equivalently, directories to be bind mounted can be specified using the environment variable `SINGULARITY_BINDPATH`:

```bash
$ export SINGULARITY_BINDPATH="dir1,dir2,dir3"
```
{: .source}

> ## Mounting `$HOME`
>
> Depending on the site configuration of Singularity, user home directories might
> or might not be mounted into containers by default.  
> We do recommend that you **avoid mounting home** whenever possible, to avoid
> sharing potentially sensitive data, such as SSH keys, with the container, especially if exposing it to the public through a web service.
>
> If you need to share data inside the container home, you might just mount that specific file/directory, *e.g.*
>
> ```bash
> -B $HOME/.local
> ```
> {: .source}
>
> Or, if you want a full fledged home, you might define an alternative host directory to act as your container home, as in
>
> ```bash
> -B /path/to/fake/home:$HOME
> ```
> {: .source}
>
> Finally, you should also **avoid running a container from your host home**,
otherwise this will be bind mounted as it is the current working directory.
{: .callout}

### How about sharing environment variables with the host?

By default, shell variables are inherited in the container from the host:

```bash
$ export HELLO=world
$ singularity exec docker://ubuntu:18.04 bash -c 'echo $HELLO'
```
{: .source}

```
world
```
{: .output}

There might be situations where you want to isolate the shell environment of the container; to this end you can use the flag `-C`, or `--containall`:  
(Note that this will also isolate system directories such as `/tmp`, `/dev` and `/run`)

```bash
$ export HELLO=world
$ singularity exec -C docker://ubuntu:18.04 bash -c 'echo $HELLO'
```
{: .source}

```

```
{: .output}

If you need to pass only specific variables to the container, that might or might
not be defined in the host, you can define variables that start with `SINGULARITYENV_`;
this prefix will be automatically trimmed in the container:

```bash
$ export SINGULARITYENV_CIAO=mondo
$ singularity exec -C docker://ubuntu:18.04 bash -c 'echo $CIAO'
```
{: .source}

```
mondo
```
{: .output}

An alternative way to define variables is to use the flag `--env`:

```bash
$ singularity exec --env CIAO=mondo docker://ubuntu:18.04 bash -c 'echo $CIAO'
```
{: .source}

```
mondo
```
{: .output}


### Popular registries (*aka* image libraries)

At the time of writing, **Docker Hub** hosts a much wider selection of container images than **Sylabs Cloud**.  This includes Linux distributions, Python and R deployments, as well as a big variety of applications.

Bioinformaticians should keep in mind another container registry, [Red Hat Quay](https://quay.io) by Red Hat, that hosts thousands of applications in this domain of science.  These mostly come out of the [BioContainers](https://biocontainers.pro) project, that aims to provide automated container builds of all of the packages made available through [Bioconda](https://bioconda.github.io).

Nvidia maintains the [Nvidia GPU Cloud (NGC)](https://ngc.nvidia.com), hosting an increasing number of containerised applications optimised to run on Nvidia GPUs.

AMD has recently created [AMD Infinity Hub](https://www.amd.com/en/technologies/infinity-hub), to host containerised applications optimised for AMD GPUs.

Right now, the Sylabs Cloud Library does not contain a large number of images.  Still, it can turn useful for storing container images requiring features that are specific to Singularity (we will see some in the next episodes).
