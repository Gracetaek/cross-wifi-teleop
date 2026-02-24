# Troubleshooting Cross‑WiFi Teleoperation

This document collects common issues encountered when using the cross‑WiFi teleoperation system (LeRobot teleop across different Wi‑Fi networks) and how to diagnose and fix them.

## "Missing motor IDs" or motor check failures

*Error message:* `FeetechMotorsBus motor check failed` with a list of missing IDs.

This happens when the leader‑side Feetech driver doesn't receive responses from the follower motors during its startup handshake. On a bridged link the driver pings each motor and expects immediate status packets. Network latency, incorrect baud rate, or serial contention on the Pi can cause these pings to be missed.

- Verify that the follower bridge on the Pi is running with the correct baud rate (`b1000000` for SO‑101 arms) and that `/dev/follower` points to the actual USB device (`/dev/ttyACM0` or `/dev/ttyUSB0`).
- Confirm that the Tailscale VPN is up on both machines. Use `ping` between the two Tailscale IPs to test connectivity and ensure that port 5500 is reachable from the laptop.
- Restart the `socat` bridge processes: start the Pi listener first, then the laptop PTY bridge, and only then start `lerobot‑teleoperate`.
- If latency cannot be avoided, adjust the LeRobot code to increase retry counts or bypass the strict handshake when using `/dev/ttyFOLLOWER`.

## "ConnectionError: Could not connect on port '/dev/ttyFOLLOWER'"

This means LeRobot cannot open the PTY that represents the follower arm.

- Ensure that the laptop‑side `socat` command is running and has created the PTY at `/dev/ttyFOLLOWER`. The command should look like:
  ```bash
  sudo socat -d -d PTY,link=/dev/ttyFOLLOWER,raw,echo=0,mode=666,waitslave \
    TCP:<PI_TAILSCALE_IP>:5500,nodelay,keepalive
  ```
- If `socat` exits (e.g., you see `read: Input/output error (probably PTY closed)`), it is because the PTY was closed when LeRobot exited. Restart the `socat` process.
- Always start the Pi listener first, then the laptop bridge, then run tele-op.

## "There is no status packet!"

This SCServo SDK error indicates that a command was sent but no reply was received. Over the network bridge, a single retry may not be enough.

- Increase the number of retries in LeRobot's Feetech driver or patch it to ignore missing status packets when using `/dev/ttyFOLLOWER`.
- Ensure that both `socat` commands use raw mode and that the Pi listener sets the correct baud.

## Port 5500 already in use on the Pi

If the Pi reports `E bind(5, {AF=...}:5500, 28): Address already in use` then something else is already listening on that port.

- Kill any leftover `socat` processes: `sudo pkill -f "socat.*5500"`.
- If you were using `ser2net`, stop it: `sudo systemctl stop ser2net`.
- Choose another port (e.g., 5501) in both the Pi and laptop `socat` commands if needed.

## Tailscale IP unreachable

- Run `tailscale ip -4` on both machines to get their current IPs.
- Use `ping <OTHER_IP>` to confirm connectivity. If unreachable, reconnect Tailscale (`sudo tailscale up`) or check network/firewall settings.
- Update your `socat` commands to use the current Tailscale IP of the Pi.

## ModemManager grabbing serial ports

On some Ubuntu images, `ModemManager` may attach to `/dev/ttyACM0` and prevent `socat` or LeRobot from opening it.

Disable it with:
```bash
sudo systemctl stop ModemManager
sudo systemctl disable ModemManager
```
Then unplug and replug the USB cable.

## Miscellaneous tips

- Use `raw` or `rawer` mode in `socat` and set `b1000000` (or your servo baud) on the Pi side to match the servo bus.
- Keep the arms powered and cables secure; connection errors are sometimes due to hardware problems.
- After any error, restart both `socat` processes to ensure a clean PTY and network connection.

