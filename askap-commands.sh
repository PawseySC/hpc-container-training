#!/bin/bash

image_dir="$(dirname $0)"
image_name="askapsoft.sif"

cmd="$(basename $0)"

args="$@"

singularity exec $image_dir/$image_name $cmd $args
