---
title: "Python containers"
teaching: 15
exercises: 10
questions:
objectives:
- Discuss how to have reproducibile builds with `pip` and `conda`
- Discuss how to build `mpi4py`
keypoints:
- Use explicit versions of python packages by using `pip freeze` and `pip install -r`

---

### Useful base images

Depending on the type of application you need to containerise, various public images
can represent an effective starting point, in shipping ready-to-use utilities that
have been containerised, tested and optimised by their own authors.  Relevant to
this workshop are:

* Python images, such as `python:3.9` and `python:3.9-slim` (a lightweight version);
we're going to use the `slim` version to avoid including unneeded packages in our images;
here are the [Docker Hub](https://hub.docker.com/_/python) repo and the
[Dockerfile](https://github.com/docker-library/python/blob/master/3.9/bullseye/slim/Dockerfile);
* Conda images by [Anaconda](https://www.anaconda.com), such as `continuumio/miniconda3:4.10.3`;
again, we prefer `miniconda3` over `anaconda3` to exclude unnecessary packages;
see [Docker Hub](https://hub.docker.com/r/continuumio/miniconda3) and
[Dockerfile](https://github.com/ContinuumIO/docker-images/blob/master/miniconda3/debian/Dockerfile);
* Intel optimised Python images, *i.e.* `intelpython/intelpython3_core:2020.2`
and `intelpython/intelpython3_full:2020.2`; we're going to use the `core` image
for the same reasons as above; see [Docker Hub](https://hub.docker.com/r/intelpython/intelpython3_core)
and [Dockerfile](https://github.com/IntelPython/container-images/blob/master/configs/intelpython3_core/Dockerfile);

Other useful base images, not directly used in this context, include:

* Jupyter images, in particular the `jupyter/` repository by
[Jupyter Docker Stacks](https://jupyter-docker-stacks.readthedocs.io)
(unfortunately making extensive use of the `latest` tag); for instance, the
scientific Python image `jupyter/scipy-notebook:latest`, see
[DockerHub](https://hub.docker.com/r/jupyter/datascience-notebook);
* OS images, such as `ubuntu:18.04`, `debian:buster` and `centos:7`.

Note that the `python`, `miniconda3`, and `intelpython` images are all based on
Debian OS (currently version 11 *Bullseye*).

All of the mentioned images are currently hosted in Docker Hub.  In addition to the image
itself, it is worth having an idea of what the corresponding Dockerfile looks like,
both to know how the image was created and to get tips on how to optimally use it.
Having the Dockerfiles is also useful in case one needs an image with multiple utilities.
Then, intelligently merging the Dockerfiles will do the job.

### Containerising *astropy* using *pip*

Let's practice installing Python packages in a container using *pip*; we'll use
the base image `python:3.9-slim`, and the package `astropy` as an example:
```docker
FROM python:3.9-slim

LABEL maintainer="Pawsey Supercomputing Research Centre"
LABEL description="This is a container with python and astropy"
LABEL python.version=3.9
LABEL python.packages="astropy"

RUN pip install astropy

CMD [ "/bin/bash" ]
```
{: .source}

Seems straightforward, right?  Note how the Dockerfile is re-defining the default
command to the `bash` shell; this is because `python` images set it to the Python console.  
Have a look at the [Dockerfile](https://github.com/docker-library/python/blob/master/3.9/buster/slim/Dockerfile)
for `python:3.9-slim` as a reference.  If you prefer the latter setting, just delete the last line.

Let's build the image, have a look at the output, and then check the image size with `docker images`:

```bash
$ docker build -t p:1 -f Dockerfile.1 .
```
{: .source}

```
Step 1/3 : FROM python:3.9-slim
3.9-slim: Pulling from library/python
1fe172e4850f: Pull complete
caf521ccaac6: Pull complete
3ead6fa29328: Pull complete
5c2a1cbceb83: Pull complete
a8d5f1318db7: Pull complete
Digest: sha256:ba3b77ddbc953cdb8d998b2052088d4af4b8805805e5b01975a05af4e19855ea
Status: Downloaded newer image for python:3.9-slim
 ---> 8c7051081f58
Step 2/3 : RUN pip install astropy
 ---> Running in 1873f952be21
 Collecting astropy
   Downloading astropy-5.0.4-cp39-cp39-manylinux_2_12_x86_64.manylinux2010_x86_64.whl (11.1 MB)
      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 11.1/11.1 MB 66.0 MB/s eta 0:00:00
 Collecting packaging>=19.0
   Downloading packaging-21.3-py3-none-any.whl (40 kB)
      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 40.8/40.8 KB 2.8 MB/s eta 0:00:00
 Collecting PyYAML>=3.13
   Downloading PyYAML-6.0-cp39-cp39-manylinux_2_5_x86_64.manylinux1_x86_64.manylinux_2_12_x86_64.manylinux2010_x86_64.whl (661 kB)
      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 661.8/661.8 KB 15.0 MB/s eta 0:00:00
 Collecting numpy>=1.18
   Downloading numpy-1.22.3-cp39-cp39-manylinux_2_17_x86_64.manylinux2014_x86_64.whl (16.8 MB)
      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 16.8/16.8 MB 36.7 MB/s eta 0:00:00
 Collecting pyerfa>=2.0
   Downloading pyerfa-2.0.0.1-cp39-cp39-manylinux_2_5_x86_64.manylinux1_x86_64.manylinux_2_12_x86_64.manylinux2010_x86_64.whl (742 kB)
      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 742.9/742.9 KB 20.8 MB/s eta 0:00:00
 Collecting pyparsing!=3.0.5,>=2.0.2
   Downloading pyparsing-3.0.8-py3-none-any.whl (98 kB)
      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 98.5/98.5 KB 6.4 MB/s eta 0:00:00
 Installing collected packages: PyYAML, pyparsing, numpy, pyerfa, packaging, astropy
 Successfully installed PyYAML-6.0 astropy-5.0.4 numpy-1.22.3 packaging-21.3 pyerfa-2.0.0.1 pyparsing-3.0.8
 Removing intermediate container d80db8640631
  ---> bc9e0ebcf0b9
 Successfully built bc9e0ebcf0b9
 Successfully tagged p:1
  ---> 6e8eaaaa85dc
Step 3/3 : CMD [ "/bin/bash" ]
  ---> Running in cba660461191
Removing intermediate container cba660461191
  ---> 06cc7bee12cd
Successfully built 06cc7bee12cd
Successfully tagged p:1
```
{: .output}

A couple of notes here:
* The version of `astropy` version depends on the version of pip. Here `5.0.4` is installed.
* `astropy` depends on `numpy`, so the `pip` installs both.
* the final image size is 285 MB.

Can we reduce image size? Yes by disabling the cache used by pip:

```docker
FROM python:3.9-slim
# have removed labels to reduce amount of text.
RUN pip --no-cache-dir install astropy

CMD [ "/bin/bash" ]
```
{: .source}

If we build this image, we can see that using the option `pip --no-cache-dir`
reduces the size by 30 MB, or 10%, to 255 MB.

Now, let's try and add version control to this image:

```docker
FROM python:3.9-slim

ARG ASTRO_VERSION="4.3.0"
RUN pip --no-cache-dir install astropy==$ASTRO_VERSION

CMD [ "/bin/bash" ]
```
{: .source}

In this example, the default installed version is `4.3.0`. This can be changed
at build time with `--build-arg ASTRO_VERSION=<ALTERNATE VERSION>`.

This was easy enough.  Now, how about build reproducibility?  Or, put in other words,
are there other packages for which we might need to keep explicit track of the version?
Well, when we install Python packages, most of them come with some dependency;
in this case it's `numpy`. Let's see ways to track these when building a container.  
We're going to see two examples, both of which rely on using a `requirements` file.

#### *pip* build reproducibility, way 1: *pip freeze*

We're now going to adopt a pretty useful strategy when developing Docker files,
that is running interactive container sessions to trial things.  First, let's write a
`requirements.in` file specifying the package we're after:

```
astropy==4.3.0
```
{: .source}

And now, let's start an interactive session with our base image, `python:3.9-slim`.
We need the current directory to be bind mounted in the container:

```bash
$ docker run --rm -it -v $(pwd):/data -w /data python:3.9-slim bash
```
{: .source}

Now, from inside the container let's execute the `prepare-pip.sh` script:

```bash
#!/bin/bash

# run this from the miniconda3 container
# docker run --rm -it -v $(pwd):/data -w /data python:3.9-slim bash

pip install -r requirements.in

REQ_FILE="requirements.txt"
pip freeze >$REQ_FILE
```
{: .source}

Here we're performing a trial run of the installation we're after, using the
`requirements` file via `pip install -r requirements.in`. Then, the useful bit:
let's save the obtained `pip` configuration in a file, using `pip freeze`.
The end result, `requirements.txt`, contains all the final packages
(two in this case) with explicit versions:

```
astropy==4.3.0
numpy==1.19.1
```
{: .source}

We can then use this file as a reference in the Dockerfile, see `Dockerfile.4`:

```docker
FROM python:3.9-slim

ARG REQ_FILE="requirements.txt"
ADD requirements.in /
ADD $REQ_FILE /requirements.txt
RUN pip --no-cache-dir install --no-deps -r /requirements.txt

CMD [ "/bin/bash" ]
```
{: .source}

We're copying the `requirements` files in the image using `ADD`, and then using
the second one to run the `pip` installation (the former is copied just to document
it in the image, it's not really required). We're using the additional flag
`install --no-deps` to make sure `pip` is only installing the packages that are
listed in the requirements; this is a complete list of packages, as we got it
from a real installation.

Now, if we run this build repeatedly over time, we're always ending up with the
same set of packages (and versions) in the container image!

#### *pip* build reproducibility, way 2: *pip-tools*

With `pip`, we've got an alternate way to generate our fully specified `requirements`
file, that does not require running a full installation interactively.

This alternate way makes use of a Python package called `pip-tools`, see its
[Github page](https://github.com/jazzband/pip-tools).  We need it installed on
the host machine we use to build Docker images, which we can achieve via
`pip install pip-tools`.

Then, starting from our initial `requirements.in` file, we can generate the final
one simply running:

```bash
$ pip-compile -o requirements.txt requirements.in
```
{: .source}

The list of packages is consistent with the *pip freeze* way, just with some extra comments:

```
#
# This file is autogenerated by pip-compile
# To update, run:
#
#    pip-compile --output-file=requirements.txt requirements.in
#
astropy==4.3.0            # via -r requirements.in
numpy==1.19.1             # via astropy
```
{: .source}


### *astropy* using *conda*

> ## Recommendation
> Use pip and python*-slim as as per typical `conda` installations,
> the list of new/updated packages is longer than with `pip` resulting in
> large final image sizes. Furthermore, more work must be done to produce
> a nice containerised environment that makes use of conda commands by setting environment
> variables. Finally, the process of setting exact versions of packages to ensure
> a reproducible build with `conda` is more involved then with `pip`.
> **Only use** `conda` if you are more familiar with it and
> use it to install non-pythonic packages.
{: .prereq}

To conda to install `astropy`, let's start with the basic `Dockerfile.1`:

```docker
FROM continuumio/miniconda3:4.10.3

ARG ASTRO_VERSION="5.0.3"
RUN conda install -y --no-update-deps astropy==$ASTRO_VERSION \
    # and clean conda to reduce image size \
    && conda clean -ay
```
{: .source}

First, we're starting from the `continuumio/miniconda3:4.10.3` image; have a look
at the [Dockerfile](https://github.com/ContinuumIO/docker-images/blob/master/miniconda3/debian/Dockerfile)
if you want.

Then, note how we're using the `conda install` flag `--no-update-deps` to ask
`conda` not to update any package that ships with the base image.  This is intended
for better build reproducibility, in that these packages should be defined only
by the choice of the base image itself.  However, unfortunately at the time of
writing this flag does not seem to work as intended.

We can build the image with:

```bash
$ docker build -t c:1 -f Dockerfile.1 .
```
{: .source}

The corresponding image is 1.47 GB large, significantly larger than that built using python*-slim.

Now, let's focus on build reproducibility, taking again an approach using a `requirements` file.
Let's start with our specification, `requirements.in`:

```
astropy==5.0.3
```
{: .source}

Now, similar to the *pip* case, let's start an interactive session:

```bash
$ docker run --rm -it -v $(pwd):/data -w /data continuumio/miniconda3:4.10.3 bash
```
{: .source}

And run this preparation script, `prepare-conda.sh`:

```bash
#!/bin/bash

# run this from the miniconda3 container
# docker run --rm -it -v $(pwd):/data -w /data continuumio/miniconda3:4.10.3 bash

conda install --no-update-deps -y  --file requirements.in

REQ_LABEL="astropy"
ENV_FILE="environment-${REQ_LABEL}.yaml"
conda env export >${ENV_FILE}

REQ_FILE="requirements-${REQ_LABEL}.yaml"
cp $ENV_FILE $REQ_FILE
sed -i -n '/dependencies/,/prefix/p' $REQ_FILE
sed -i -e '/dependencies:/d' -e '/prefix:/d' $REQ_FILE
sed -i 's/ *- //g' $REQ_FILE
```
{: .source}

Here we're running a trial installation using `conda install --file requirements.in`.
Then we can export the versioned packages in the active environment using `conda env export`.  
This has a caveat: environment export in `conda` creates a YAML file that allows
the creation of a completely new environment, including information on the environment name,
prefix and channels (see `environment-3sep.yaml` in the directory of this example).

As we just want this information to install packages in the preexisting base environment
of the base image, we need to polish this file, *e.g.* using `sed`.  
A bunch of edits will return use the final `requirements-astropy.yaml` (see example directory),
which only contain the list of versioned packages.
This is the requirements file we can use in the Dockerfile, see `Dockerfile.3`:

```docker
FROM continuumio/miniconda3:4.10.3

ARG REQ_FILE="requirements-astropy.yaml"
ADD requirements.in /
ADD $REQ_FILE /requirements.yaml

RUN conda install -y --no-deps --file /requirements.yaml \
    # and clean conda to reduce image size \
    && conda clean -ay
```
{: .source}

Note how we're now using the option `conda install --no-deps`, to tell `conda`
not to consider any package dependency for installation, but just those packages
in the requirements list.  In principle, this is dangerous and can lead to broken
environments, but here we're safe as we obtained this list by exporting a real,
functional environment.

#### Shell variables and *conda* environment settings

This is one more aspect worth mentioning when dealing with `conda` container images.

So, `conda activate` run in a Dockerfile would not work as intended, as variable
settings would only leave inside the corresponding `RUN` layer. Then, another way
might be to embed environment sourcing inside *profile* files, such as
`~/.sourcerc`, `~/.profile`, or even something like `/etc/profile.d/conda.sh`.
However, these files are only sourced when `bash` is launched, so for instance
not when running a `python` execution directly.
Also, files under home, `~/`, would not work with Singularity: Docker home is *root*'s home,
whereas Singularity runs as the host user.

In summary, the most robust way to ensure shell variables for the conda environment
are set is to set them explicitly in the Dockerfile using `ENV` instructions.

In terms of general conda variables, the `continuumio` base images all set a
modified `PATH` variable, so that conda and binaries in the base environment are
found (see [Dockerfile](https://github.com/ContinuumIO/docker-images/blob/master/miniconda3/debian/Dockerfile)).
Explicitly setting also the `CONDA_PREFIX` is not done in the base image, so it
does not hurt doing it in our Dockerfile, see `Dockerfile.4`:

```docker
FROM continuumio/miniconda3:4.10.3

ARG REQ_FILE="requirements-astropy.yaml"
ADD requirements.in /
ADD $REQ_FILE /requirements.yaml

RUN conda install -y --no-deps --file /requirements.yaml \
    # and clean conda to reduce image size \
    && conda clean -ay

# conda activate is not robustly usable in a container.
# then, go for an environment check in a test container,
# to see if you need to set any package specific variables in the container:
#
# run this from the miniconda3 container
# docker run --rm -it -v $(pwd):/data -w /data continuumio/miniconda3:4.10.3 bash
#
# env >before
# conda install <..>
# env >after
# diff before after

# this one is always good to have
ENV CONDA_PREFIX="/opt/conda"
```
{: .source}

Althtough not the case for `astropy`, some installed packages may need additional variables
added to the shell environment. It's possible to capture them by:

```bash
$ docker run --rm -it -v $(pwd):/data -w /data continuumio/miniconda3:4.10.3 bash
$ env >before # from within the container
$ conda install <..>
$ env >after
$ diff before after
```
{: .source}

If there are any spare variables, it's advisable to review them, and include relevant
ones in the Dockerfile using `ENV` instructions.

### Python with MPI: *mpi4py*

Now, let's have a look at a more articulated example: suppose we need a container image that is able to run MPI Python code, *i.e.* using the package `mpi4py` (files under `2.mpi.python/`).
How is this different compared to previous examples?  Well, in brief:
* we know that, beside the `mpi4py` Python package, we also need some system utilities such as compilers and MPI libraries/wrappers;
* compilers are available with `apt`, but MPI libraries are better compiled from scratch ..
* .. in fact, as we'll see in the next episode, this configuration requires care, so that at runtime we can dynamically link `mpi4py` to the host MPI libraries rather than the container ones.

So, here's our plan:

1. install compilers and build tools with `apt`;
2. compile an MPI library;
3. install `mpi4py` using `pip`.

Note how in our container image we need both Python and MPI utilities.  We know we have base images for both, *e.g.* `python:3.9-slim` and `pawsey/mpich-base:3.1.4_ubuntu18.04`.
Can we combine them?  Upon inspection, we will notice that there are no incompatible steps amongst the two, so .. yes we can combine them.
How to combine them?  Well, there's no Docker instruction to achieve this from the two images, so the only option
is to pick one and then install the other set of utilities explicitly in the Dockerfile.

This is when it gets handy to have a look at the Dockerfiles of our base images of interest:
[python](https://github.com/docker-library/python/blob/master/3.9/buster/slim/Dockerfile),
[pawsey/mpich-base](https://github.com/PawseySC/pawsey-containers/blob/master/mpich-base/Dockerfile).
The former is 143 lines long, the latter only 64 so looks more convenient to embed the latter on top of the former.

As regards `mpi4py`, if we run a trial interactive installation we'll discover
that this package has no further `pip` package dependencies, so we can specify
its version straight in the Dockerfile.

Let's have a look at how the final `Dockerfile` looks like:

```docker
FROM python:3.9-slim

# set the arguments of MPICH
ARG MPICH_VERSION="3.1.4"
ARG MPICH_CONFIGURE_OPTIONS="--enable-fast=all,O3 --prefix=/usr"
ARG MPICH_MAKE_OPTIONS="-j4"
# and arguments for MPI4PY
ARG MPI4PY_VERSION="3.1.3"

# first get all the necessary pre-built packages
# compile mpi and build python
RUN apt-get update -qq \
      && apt-get -y --no-install-recommends install \
         build-essential \
         ca-certificates \
         gdb \
         gfortran \
         wget \
      && apt-get clean all \
      && rm -r /var/lib/apt/lists/*

# build MPI libraries
# neglecting for simplicity the building of benchmarking and test suite here
RUN mkdir -p /tmp/mpich-build \
      && cd /tmp/mpich-build \
      && wget http://www.mpich.org/static/downloads/${MPICH_VERSION}/mpich-${MPICH_VERSION}.tar.gz \
      && tar xvzf mpich-${MPICH_VERSION}.tar.gz \
      && cd mpich-${MPICH_VERSION}  \
      && ./configure ${MPICH_CONFIGURE_OPTIONS} \
      && make ${MPICH_MAKE_OPTIONS} \
      && make install \
      && ldconfig \
      && cp -p /tmp/mpich-build/mpich-${MPICH_VERSION}/examples/cpi /usr/bin/ \
      && cd / \
      && rm -rf /tmp/mpich-build

# build mpi4py
RUN pip --no-cache-dir install --no-deps mpi4py==${MPI4PY_VERSION}

CMD [ "/bin/bash" ]
```
{: .source}
