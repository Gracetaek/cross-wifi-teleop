#!/bin/bash
# Start follower PTY bridge on laptop
# This script creates a pseudo-terminal /dev/ttyFOLLOWER and bridges it over TCP to the Pi follower port.
# Adjust the IP address to the Pi's Tailscale IP as necessary.

sudo socat -x -v -d -d \
  PTY,link=/dev/ttyFOLLOWER,raw,echo=0,mode=666,waitslave \
  TCP:100.103.76.89:5500,nodelay,keepalive
