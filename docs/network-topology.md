# Network Topology for Cross-WiFi Teleoperation

This document describes the high-level architecture used to teleoperate a follower robotic arm across different Wi‑Fi networks. The leader computer and follower system run on separate networks but can communicate over a secure overlay network.

## Architecture Overview

The teleoperation setup consists of three key components:

1. **Leader (Laptop)** – runs LeRobot to read the leader arm state and send commands.
2. **Tailscale Overlay** – a secure virtual network that bridges the leader and follower devices across the public internet. Both devices join the same Tailscale network to obtain stable private IP addresses.
3. **Follower (Raspberry Pi 4)** – connects to the follower robot arm via USB and executes the received commands.

Here is a simple diagram of the topology:

![Architecture Diagram](../architecture_diagram.png)

Alternatively, the connections can be visualized with an ASCII diagram:

```
Leader (Laptop)  -->  Tailscale overlay  -->  Follower (Raspberry Pi)
   /dev/leader                      |                      /dev/follower
   reads arm state           secure connection        sends commands to arm
```

The leader streams the servo states over TCP to the follower through the overlay. On the Pi, a `socat` listener forwards the TCP stream to the physical serial port connected to the follower arm. On the leader, another `socat` instance creates a local pseudo‑terminal (`/dev/ttyFOLLOWER`) that forwards commands over the overlay.

## Startup Sequence

1. **Start the follower bridge on the Pi** using the `start_follower_bridge.sh` script in `scripts/pi`. This script kills any existing listeners and starts a `socat` service on port 5500 that exposes the follower serial port (`/dev/follower`) over TCP.  
2. **Start the PTY bridge on the leader** using the `start_follower_pty_bridge.sh` script in `scripts/laptop`. This creates a PTY at `/dev/ttyFOLLOWER` and connects it to the follower service at `tailscale_ip_of_pi:5500`.
3. **Launch LeRobot teleoperation** on the leader. Set the leader arm port to `/dev/leader` and the follower arm port to `/dev/ttyFOLLOWER`. LeRobot will open these ports and stream commands across the overlay.

For example:

```bash
# On the Pi (follower):
bash scripts/pi/start_follower_bridge.sh

# On the laptop (leader):
bash scripts/laptop/start_follower_pty_bridge.sh

# Teleoperate from the laptop:
lerobot-teleoperate \
  --robot.type so101_follower \
  --robot.port /dev/ttyFOLLOWER \
  --robot.id follower \
  --teleop.type so101_leader \
  --teleop.port /dev/leader \
  --teleop.id leader
```

## Why `/dev/ttyFOLLOWER` is a PTY proxy

The leader computer cannot directly access the follower’s physical serial device because it is on a remote network. The `socat` command on the leader creates a **pseudo‑terminal (PTY)** at `/dev/ttyFOLLOWER`. To LeRobot, this PTY behaves like a normal serial port. Underneath, `socat` forwards all data written to the PTY over TCP to the Pi. On the Pi, the companion `socat` process writes the data to the real serial port connected to the follower arm. This PTY proxy allows LeRobot to run unmodified while transparently bridging two different networks.
