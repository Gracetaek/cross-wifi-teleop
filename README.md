# Cross-WiFi Teleoperation (LeRobot + socat + Tailscale)

Teleoperate an **SO-101 leader arm on a laptop** and an **SO-101 follower arm on a Raspberry Pi 4** even when they are on **different Wi-Fi networks**.

This repo documents a practical setup that uses:

- **LeRobot** for teleoperation
- **Tailscale** for secure cross-network connectivity
- **socat** to bridge the follower serial port over TCP and expose it as a local PTY (`/dev/ttyFOLLOWER`) on the laptop

---

## What this solves

Normally, LeRobot expects the follower arm to be connected locally (USB serial) to the same machine running `lerobot-teleoperate`.

This setup makes the follower arm (physically connected to the Pi) look like a **local serial device** on the laptop by creating a **PTY proxy**:

- Pi: `/dev/follower` (real serial device) → TCP server on port `5500`
- Laptop: TCP client → `/dev/ttyFOLLOWER` (virtual serial device / PTY)

LeRobot then uses `/dev/ttyFOLLOWER` as if it were a normal local serial port.

---

## Repository Structure

```text
.
├── README.md
├── docs
│   ├── network-topology.md
│   └── troubleshooting.md
└── scripts
    ├── laptop
    │   └── start_follower_pty_bridge.sh
    └── pi
        └── start_follower_bridge.sh
