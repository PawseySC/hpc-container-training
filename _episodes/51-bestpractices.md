---
title: "Best Practices"
teaching: 15
exercises: 0
questions:
objectives:
- Discuss the best practices when debugging and finalising container recipes
- Discuss any security issues that may arise in the build process
- Discuss how to design containers to contain simple in-built tests
- Discuss how containers can be built to be portable or performant and when to choice portability or performance
keypoints:
- Add lots of comments and metadata to your recipe so that it is easier to maintain
- When possible include tests of any Parallel API the container may need to use
---

### How to write maintanable recipes

#### Adding Comments

Most examples of Docker recipes that you will find are not well documented, nor easily maintainable. Consider the previous recipe for the lolcow container:
```
FROM ubuntu:18.04

LABEL maintainer="Pawsey Supercomputing Centre"

RUN apt-get -y update && \
  apt-get -y install fortune cowsay lolcat

ENV PATH=/usr/games:$PATH

VOLUME /data
WORKDIR /data

CMD fortune | cowsay | lolcat
```
{: .source}

The recipe does not contain any comments, and more importantly the container built using this recipe will not have any metadata about what it contains. How can it be improved?

For one, it should have a extensive set of labels:  
```
LABEL maintainer="Aardvark"
LABEL version="1.0.0"
LABEL tags="ubuntu/18.04"
LABEL description="This container provides the fortune, cowsay and lolcat commands.\
It will by default combine all these commands, piping the output from fortune to cowsay and \
add colour via lolcat. "
```
{: .source}

Second, it will be easier to maintain if comments are added.
```
# Use the ubuntu base image
FROM ubuntu:18.04

# Adding labels
LABEL maintainer="Pawsey Supercomputing Centre"

# Use apt-get to install desired packages
RUN apt-get -y update && \
  apt-get -y install fortune cowsay lolcat
```
{: .source}

#### Debugging with mutiple `RUN` and finalizing with single `RUN`

Finally, it is good practice to split any complex steps when building a container
into separate `RUN` commands but then once a built works as desired to join everything
into a simple run command and take care to clean up any unnecessary files that were
used in building applications. This reduces the container size. In the above example, the
installs have already been combined. However, if there was a typo it could be difficult
to identify, particularly if lots of packages are being installed and if there are several typos.

A pedagogical example would be:
```
RUN apt-get -y update && \
  apt-get -y install cowsay fortun lolcats
```
{: .source}

Here there are two typos it might be easier to have each install command on a single line:
```
RUN apt-get -y update
RUN apt-get -y install cowsay
RUN apt-get -y install fortun
RUN apt-get -y install lolcats
RUN apt-get -y install lolcats
```
{: .source}

The conatiner also contains all the files need to run `apt-get` and recently cached files.
These are unlikely to be used when running the container so the recipe should also remove them
once they have been used.
```
# Use apt-get to install desired packages
RUN apt-get -y update && \
  # install packages
  apt-get -y install fortune cowsay lolcat \
  # and clean-up apt-get related files
  && apt-get clean all \
  && rm -r /var/lib/apt/lists/*
```
{: .source}

#### Ensuring  no security information present in container

Finally, for docker it is particularly important to ensure that security information,
such as ssh keys, are used and then removed all within a single `RUN` command, otherwise,
a layer will contain sensitive information. An example is copying ssh keys from a host
system into a container so that the container can access sensitive information during the
build process. It is poor practice to copy ssh keys with the `COPY` command:
```
# Copy the ssh keys to have git credentials
# Git credential
ARG SSH_KEY_PATH
RUN mkdir /root/.ssh/
COPY ${SSH_KEY_PATH}/id_rsa /root/.ssh/id_rsa
COPY ${SSH_KEY_PATH}/known_hosts /root/.ssh/known_hosts
# Run commands
```
{: .source}

Instead, it is critical that such sensitive information be limited to a single `RUN` command
and removed once used.
```
RUN mkdir /root/.ssh/ \
    # Copy ssh information within a run command
    && cp ${SSH_KEY_PATH}/id_rsa /root/.ssh/id_rsa \
    && cp ${SSH_KEY_PATH}/known_hosts /root/.ssh/known_hosts \
    # Run other commands
    # Remove SSH key so that layer does not contain any security information
    && rm -rf /root/.ssh/*
```
{: .source}

> ## Checklist for writing a recipe
> - Recipes should have useful comments, similar to how any other source code contains comments.
> - Recipes should Have useful metadata, providing information for users of the container.
> - When debugging use multiple `RUN` commands. Combine separate `RUN` commands
> into single `RUN` command to minimize image size once the recipe is working.
> - Ensure any security information is ephemeral, that is used and the deleted within
> a single `RUN` command.
{: .checklist}

### Including tests in a container

Although not all containers make use of external libraries for functionality or performance,
there are a number of uses cases where it is very useful to provide separate tests within a container.
A prime example is where containers make use of MPI libraries. In (almost) all cases, the container
should use the MPI libraries of the host system rather than any provided within the container itself.
However, debugging MPI issues by running the container application may be tricky.

Thankfully, there is already a ready-to-use set of MPI tests, the [OSU Micro-Benchmarks](http://mvapich.cse.ohio-state.edu/benchmarks/).
This package provides a large number of MPI related tests. By comparing the results of
these tests within a container to the same test running on the host system, you might be able
to identify issues running MPI within the container:
```
# build desired ABI compatibile MPI library
# here this example shows how we might build OPENMPI
# first build openmpi
ARG OPENMPI_VERSION="4.1.1"
ARG OPENMPI_DIR="v4.1"
ARG OPENMPI_CONFIGURE_OPTIONS="--prefix=/usr/local"
ARG OSU_VERISON="5.9"
ARG OSU_CONFIGURE_OPTIONS="--prefix=/usr/local"
ARG OSU_MAKE_OPTIONS="-j${CPU_CORE_COUNT}"
RUN mkdir -p /tmp/openmpi-build \
      && cd /tmp/openmpi-build \
      && wget https://download.open-mpi.org/release/open-mpi/${OPENMPI_DIR}/openmpi-${OPENMPI_VERSION}.tar.gz \
      && tar xzf openmpi-${OPENMPI_VERSION}.tar.gz \
      && cd openmpi-${OPENMPI_VERSION}  \
      # build openmpi
      && ./configure ${OPENMPI_CONFIGURE_OPTIONS} \
      && make ${OPENMPI_MAKE_OPTIONS} \
      && make install \
      && ldconfig \
      # remove the build directory now that the library is installed
      && cd / \
      && rm -rf /tmp/openmpi-build \
      # now having built openmpi, build the osu benchmarks
      # download, extract and build
      && cd /tmp/osu-build \
      && wget http://mvapich.cse.ohio-state.edu/download/mvapich/osu-micro-benchmarks-${OSU_VERISON}.tar.gz  \
      && tar xzf osu-micro-benchmarks-${OSU_VERSION}.tar.gz \
      && cd osu-micro-benchmarks-${OSU_VERSION}  \
      && ./configure ${OSU_CONFIGURE_OPTIONS} \
      && make ${OSU_MAKE_OPTIONS} \
      && make install \
      && ldconfig \
      # remove the build directory now that the library is installed
      && cd / \
      && rm -rf /tmp/osu-build
```
{: .docker}

The approach of having a simple test related to any Parallel API contained within the container
may reduce the number of issues you will encounter deploying containers on a variety of systems.
It also maybe useful to even add a script that reports the libraries used by containerized
applications at runtime:
```
#!/bin/bash
# list all applications of interest as space separated list
apps=()
# loop over all apps and report there dependencies
echo "Checking the runtime libraries used by :"
echo ${apps[@]}
echo ""
for app in ${apps[@]}
do
    echo ${app}
    ldd ${app}
done
```
{: .language-bash}
and have this script in `/usr/bin/applications-dependency-check`:
```
# add ldd script
ARG LDD_SCRIPT
RUN cp -p ${LDD_SCRIPT} /usr/bin/applications-dependency-check \
      && chmod +x /usr/bin/applications-dependency-check
```
{: .docker}


### Portability vs Performance

Some containerized applications are not computational intensive applications and must
run on a variety of systems. In fact containers were conceived with reproducibility and portability
as core properties since most initial applications were service oriented and needed to be
easily deployable.

However, there are cases where a container does not need to run on all systems,
allowing the source code to be compiled with performance in mind. OpenFOAM containers
are a prime example of such a use-case, as the code is computationally intensive.
When compiling the source of such applications it can be useful to build with a
large number of optimization flags, such as `-O2 -march=<target>`.
Such code will be built to run only on compatible CPU architecture. It is therefore important to
defined portable and performant containers:

> ## Portable
> ```
> # build from source a portable container
> ARG OPTIMIZATION_FLAGS="-O2"
> ARG source=<source>
> LABEL build.type="Portable"
> LABEL build.target="x86_64"
> LABEL build.options=${OPTIMIZATION_FLAGS}
>
> RUN mkdir -p /tmp/build \
>       # get the source
>       && wget ${source}.tar.gz && tar xzf ${source}.tar.gz && cd ${source} \
>       # build
>       && make CXXFLAGS=${OPTIMIZATION_FLAGS} && make install \
>       && rm -rf /tmp/build
> ```
> {: .docker}
{: .callout}

> ## Performance
> ```
> # build from source a CPU optimised build
> ARG OPTIMIZATION_FLAGS="-O3 -march=znver3"
> ARG source=<source>
> LABEL build.type="Performance"
> LABEL build.target="zen3"
> LABEL build.options=${OPTIMIZATION_FLAGS}
>
> RUN mkdir -p /tmp/build \
>       # get the source
>       && wget ${source}.tar.gz && tar xzf ${source}.tar.gz && cd ${source} \
>       # build
>       && make CXXFLAGS=${OPTIMIZATION_FLAGS} && make install \
>       && rm -rf /tmp/build
> ```
> {: .docker}
{: .callout}

You'll notice subtle differences in the `RUN` commands but that we have added metadata
to make it clear what the difference between these containers.
