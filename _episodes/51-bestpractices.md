---
title: "Best Practices"
teaching: 15
exercises: 0
questions:
objectives:
- become familiar with best practices when debugging and finalising container recipes
- become familiar with any security issues that may arise in the build process
- how to design containers to contain simple in-built tests
- understand how containers can be built to be portable or performant and when to choice portability or performance
keypoints:
- Add lots of comments and metadata to your recipe so that it is easier to maintain
- When possible include tests of any Parallel API the container may need to use
---

### Writing recipes

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

> ## Recipes should  
> - have comments
> - have useful metadata
> - combine separate `RUN` commands
> - ensure any security information is ephemeral, that is used and the deleted within
> a single `RUN` command
{: .checklist}

### Including tests

### Portability vs Performance
