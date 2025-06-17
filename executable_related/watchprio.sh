#!/bin/sh
set -e

watch -n0.1 "ps -eL -o pid,tid,comm,cls,pri,rtprio,psr | grep -i safebot | sort -f -k3"
