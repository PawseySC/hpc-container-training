---
title: "Streamline the user experience: bash wrappers, modules and SHPC"
teaching: 15
exercises: 15
questions:
objectives:
- Simplify containers usage by means of bash wrappers
- Discuss how to deploy containers and their wrappers using modules
- Discuss how to deploy container modules using SHPC
keypoints:
- It is possible to devise a fairly general wrapper template for containerised applications
- The key information to setup the wrappers is the container image, and the commands one needs to run from that image
- It is possible to write a minimal modulefile, that allows to setup the shell environment to use containerised applications through wrappers
- SHPC uses bash functions and automates the process of creating container modules
---


### Can we standardise the use of containers, to simplify the required syntax?

Running containers using the host MPI requires setting a number of environment
variables along with the additional standard syntax to run the container itself.
There are several possible ways of simplifying commands: bash wrappers; modules
and [SHPC](https://singularity-hpc.readthedocs.io/en/latest/),
which provides a framework combining the former two methods.

Now, let's think about the typical usage of a containerised application.  
Once the container image is available in the local disk, in the vast majority of
cases you'll use it to execute some command in this way.
As a practical example, let's grab the `lolcow` container used in earlier episodes.

```bash
singularity exec ./lolcow.sif <CMD> <ARGS>
```
{: .source}

As a plain, useful example, let's suppose we want to get the help output from the `cowsay` command:

```bash
$ singularity exec ./lolcow.sif cowsay -h
```
{: .source}

We can break this into logical parts; let's write a script called `cowsay.1` for convenience:

```bash
#!/bin/bash

# point to the image directory
# and the name of the container respectively
image_dir="."
image_name="lolcow.sif"

# define the command
cmd="cowsay"

# and grab all commands passed to the script via the command line
args="$@"

# call singularity
singularity exec $image_dir/$image_name $cmd $args
```
{: .source}

Shell variables express tool- and command- specific information, such as the image
location `image_dir` and name `image_name`.  The command name, `cmd`, might change
from command to command. How about the value we assigned to the command arguments
variable, `args`?  Well, that's bash syntax.  If you execute this script, bash will
assign to `$@` the full list of arguments that you append to the script in the command line.  

To see this in practice,make the `cowsay.1` script executable (using `chmod`) and run it with the `-h` argument:

```bash
$ chmod +x cowsay.1
$ ./cowsay.1 -h
```
{: .source}

```
cow{say,think} version 3.03, (c) 1999 Tony Monroe
Usage: cowsay [-bdgpstwy] [-h] [-e eyes] [-f cowfile]
          [-l] [-n] [-T tongue] [-W wrapcolumn] [message]
```
{: .output}

The generality of the wrapper script means that to write a script for the command
`lolcat`, we need only change that line:

```bash
#!/bin/bash

image_dir="."
image_name="lolcow.sif"

cmd="lolcat"

args="$@"

singularity exec $image_dir/$image_name $cmd $args
```
{: .source}


From the output, you can see that the `cowsay` command actually got the `-h` flag right, and this was thanks to the usage of `$@` in the script.

So to summarise this section, we've written a simple bash script that wraps around the Singularity `exec` approach, so that to run `cowsay` from a container you simply type:

```bash
$ ./cowsay.1 <ARGS>
```
{: .source}

Why the `.1` extension?  Well, this is just because the story is not over...


### A (quite) general bash wrapper for containerised applications

In the first iteration of a bash wrapper for containerised commands, we need to provide 3 pieces of information in the script: image location, image name and command name.  Can we further simplify and generalise this?

**Yes**.  With a couple of extra bash commands and assumptions, we can make it so that the only required information will be the **container image name**.

First, let's get rid of the command name. Let's assume that we're calling the
wrapper with the same name of the command we want it to execute.  Then, we're
going to use the bash variable `$0`; used inside a script, it contains the full
path of the script itself; we're also using the bash command `basename`, that
extract a file or directory name out of its full path.  The `cmd` variable becomes:

```bash
cmd="$(basename $0)"
```
{: .source}

Now let's generalise the image location.  Let's assume that we're storing the
wrappers in the same directory where the image is located. Then, we can use the
bash command `dirname` to extract the location of a file or directory out of its
full path. The `image_dir` variable becomes:

```bash
image_dir="$(dirname $0)"
```
{: .source}

So we can now have a general bash wrapper for the commands from the container image `lolcow.sif`:

```bash
#!/bin/bash

image_dir="$(dirname $0)"
image_name="lolcow.sif"

cmd="$(basename $0)"

args="$@"

singularity exec $image_dir/$image_name $cmd $args
```
{: .source}

To create a wrapper for `cowsay`, all we have to do is to create a script named
`cowsay` with that content.  Then, we can do the same for any other commands such as
`fortune`, `lolcat`, and so on. In fact, we need not even create files for each
command. Instead we create a single script, *e.g.* named `.lolcow_commands.sh`, and
then create appropriately named symbolic links for the commands, for instance:

```bash
$ ln -s .lolcow_commands.sh cowsay
$ ln -s .lolcow_commands.sh lolcat
```
{: .source}

### How general is this approach?

Well, quite general probably. It can be used every time you would use containers with this Singularity syntax:

```bash
singularity exec <IMAGE> <CMD> <ARGS>
```
{: .source}

This will also work with MPI containers and Slurm, as the corresponding syntax does not impact such form:

```bash
mpirun -n <NTASKS> singularity exec <IMAGE> <CMD> <ARGS>
srun -n <NTASKS> singularity exec <IMAGE> <CMD> <ARGS>
```
{: .source}

So that now things become :
```bash
mpirun -n <NTASKS> <CMD> <ARGS>
srun -n <NTASKS> <CMD> <ARGS>
```
{: .source}

Of course there are some corner cases:
* GPU enabled containers require extra singularity arguments: after `exec` in the wrapper you will need to add `--nv` (Nvidia) or `--rocm` (AMD).
* Using overlays requires adding `--overlay <OVERLAY FILEPATH>`, with the file path possibly specified using a shell variable that you can define prior to executing the wrapper.  
* Wrappers to launch GUI sessions will also require some tweaking.  
* Applications where environment variables along with command line arguments impact how commands run.
* Applications that need to bind mount a dynamic set of host directories along with command line arguments.

> ## How to address dynamic bind mount set
> Specifying the paths to be bind mounted as additional flags in the wrappers is
> not really general nor portable. What you want to do here is to use `$SINGULARITY_BINDPATH`
> to define the maximal required paths prior to execution of the application.  
> If you have a standard setup on your system, where all the data go under the
> same parent directory (*e.g.* `/data`), you might even want to define the
> variable in the startup scripts (`~/.sourcerc`,...).  This can be quite a good
> practice in simplifying your production environment, and making it more robust.  
>
> The singularity module provided on Pawsey HPC systems adds `/group` and `/scratch`
> to the the bind path, so you don't have to worry about bind mounting data directories at all.
{: .callout}

### Using modules to handle bash wrappers

So far in this episode, we've devised a scenario to deploy a containerised application in a streamlined way:

1. define the container image you need;
2. pull it in a directory;
3. in that same directory, create bash wrappers for the commands you need to execute from that container.

If you're in a system with lots of other applications, you might want to tidy up
the environment by using modules.  Here, we're using the [Environment Modules](http://modules.sourceforge.net)
implementation; an alternative one is the [Lmod](https://lmod.readthedocs.io)
module system. This tutorial provides Linux template installation scripts for
both: see [Environment Modules script]({{ page.root }}/files/install-modules.sh)
and [Lmod script]({{ page.root }}/files/install-lmod.sh).  
**Note that** discussing modules in details is out-of-scope here, we're just
using them to show how to organise containerised applications.

All relevant bash wrapper scripts for our containerised application, *e.g.* are in a single location. To run this example, there's already a directory made ready in your current work directory, `$TUTO/demos/wrap_container`, namely `apps/lolcow/1.0.0/bin`. It contains four bash wrappers:

```bash
$ ls apps/lolcow/1.0/bin
```
{: .source}

```
cowsay     fortune     lolcat     lolcow
```
{: .output}

To get ready for this example, let us also pull the BLAST image there:

```bash
$ singularity pull --dir apps/lolcow/1.0.0/bin
```
{: .source}

Now, we can think of a minimal modulefile to setup `lolcow` in our environment:

```tcl
#%Module1.0######################################################################
##
## blast modulefile
##
proc ModulesHelp { } {
    puts stderr "\tModule for lolcow version 1.0.0\n"
    puts stderr "\tThis module uses the container image ???"
}

module-whatis   "edits the PATH to use the lolcow commands, version 1.0.0"

prepend-path     PATH            $env(TUTO)/demos/wrap_lolcow/apps/blast/1.0.0/bin
```
{: .source}

In general, the string associated to `PATH` will need to be customised case-by-case,
same as the `help` and `whatis` strings.  

A copy of this modulefile is under `modulefiles/` in the current path.  

Let's try it! First we need to tell modules to look for modules in this directory:

```bash
$ module use $(pwd)/modulefiles
$ module avail
```
{: .source}

```
------------------------------ /somewhere/demos/wrap_lolcow/modulefiles ------------------------------------
lolcow/1.0.0  

------------------------------ /usr/share/modules/modulefiles ---------------------------------------------
dot  module-git  module-info  modules  null  use.own  

```
{: .output}

It's there!  Let's `load` it:

```bash
$ module load lolcow/1.0.0
```
{: .source}

Can we now see the wrappers in there?

```bash
$ which cowsay
```
{: .source}

```
/somewhere/demos/wrap_lolcow/apps/blast/1.0.0/bin/cowsay
```
{: .output}

Sure! Let's test it with the usual `-h` flag:

```bash
$ cowsay -h
```
{: .source}

```
cow{say,think} version 3.03, (c) 1999 Tony Monroe
Usage: cowsay [-bdgpstwy] [-h] [-e eyes] [-f cowfile]
          [-l] [-n] [-T tongue] [-W wrapcolumn] [message]
```
{: .output}

Containerised application with wrappers and modules: the experience looks like a traditional installation!


### Latest: SHPC, a tool to the rescue for container modules

[Singularity Registry HPC](https://singularity-hpc.readthedocs.io), or SHPC for short,
is an extremely interesting project by some of the original creators of Singularity.  
This utility enables the automatic deployment of so called Container Modules,
using either Lmod or Environment Modules to provide access to bash wrappers.
we have just presented in this episode.  

This ever-growing repository of containerised applications already provides a number of
Bioinformatics packages, which are typically run within containers. As an example,
let's see how we can install [BLAST](https://blast.ncbi.nlm.nih.gov/Blast.cgi)
using SHPC.  First, let's look for available BLAST versions with `shpc show`:

```bash
$ shpc show --versions -f blast
```
{: .source}

```
quay.io/biocontainers/blast:2.10.1--pl526he19e7b1_3
quay.io/biocontainers/blast:2.11.0--pl5262h3289130_1
quay.io/biocontainers/blast:2.12.0--pl5262h3289130_0
ncbi/blast:2.11.0
ncbi/blast:2.12.0
ncbi/blast:latest
```
{: .output}

And now let's install the latest BLAST biocontainer (copy-pasting the image and
tag from the output above) with `shpc install`:

```bash
$ shpc install quay.io/biocontainers/blast:2.12.0--pl5262h3289130_0
```
{: .source}

```
singularity pull --name /home/ubuntu/singularity-hpc/containers/quay.io/biocontainers/blast/2.12.0--pl5262h3289130_0/quay.io-biocontainers-blast-2.12.0--pl5262h3289130_0-sha256:a7eb056f5ca6a32551bf9f87b6b15acc45598cfef39bffdd672f59da3847cd18.sif docker://quay.io/biocontainers/blast@sha256:a7eb056f5ca6a32551bf9f87b6b15acc45598cfef39bffdd672f59da3847cd18
INFO:    Converting OCI blobs to SIF format
INFO:    Starting build...
[..]
INFO:    Creating SIF file...
/home/ubuntu/singularity-hpc/containers/quay.io/biocontainers/blast/2.12.0--pl5262h3289130_0/quay.io-biocontainers-blast-2.12.0--pl5262h3289130_0-sha256:a7eb056f5ca6a32551bf9f87b6b15acc45598cfef39bffdd672f59da3847cd18.sif
Module quay.io/biocontainers/blast:2.12.0--pl5262h3289130_0 was created.
```
{: .output}

That's it!  We now have a BLAST module that provides all the BLAST applications.

### Final thoughts on using wrappers

So, we've shown you how to effectively hide containers under the hood to
provide a simplified user experience, while gaining in reproducibility,
portability, productivity and more.

Why bothering with learning the longer story of the Singularity syntax then?
Well, containers are a powerful technology, but also a complex one.  
Even if you're going to use them through a friendlier interface, it's still
crucial to know how thing work underneath, to be aware of the corresponding
limitations, and possibly also to be able to fix the setup when things go wrong.
