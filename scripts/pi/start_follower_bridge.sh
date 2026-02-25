#!/bin/bash
# Start follower bridge on Pi
# This script starts a socat TCP listener on port 5500 and forwards data to the follower arm's serial port.
# It runs in raw mode with 1,000,000 baud. Adjust the serial device path and baud rate as needed.

sudo socat -x -v -d -d \
  TCP-LISTEN:5500,reuseaddr,fork,nodelay,keepalive \
  FILE:/dev/follower,rawer,echo=0,b1000000
