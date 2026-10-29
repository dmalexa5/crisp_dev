# Chrony Time Synchronization Between Ubuntu Computers

This guide configures Chrony to synchronize time between two computers over a wired Ethernet network.

- **Master:** Ubuntu 24.04 — `192.168.1.10`
- **Client:** Ubuntu 22.04 — `192.168.1.11`
- **Network:** Ethernet subnet `192.168.1.0/24`

## Step 1: Assign Static IP Addresses

Configure static IP addresses on the Ethernet interfaces of both computers so they can reliably communicate.

| Computer | Operating System | Static IP Address |
|---|---|---|
| Master | Ubuntu 24.04 | `192.168.1.10` |
| Client | Ubuntu 22.04 | `192.168.1.11` |

Ensure both computers can communicate over Ethernet before proceeding.

## Step 2: Configure the Time Server (Master PC)

Perform these steps on the Ubuntu 24.04 master computer.

### 2.1. Install Chrony

```bash
sudo apt update && sudo apt install -y chrony
```

### 2.2. Edit the Chrony Configuration

Open the configuration file:

```bash
sudo nano /etc/chrony/chrony.conf
```

Append the following lines to the bottom of the file:

```conf
# Allow the Ethernet subnet to connect
allow 192.168.1.0/24

# Serve time even if not synchronized to an internet source
local stratum 10
```

The `allow` directive permits clients on the specified subnet to synchronize with this server. The `local stratum 10` directive allows Chrony to serve its local clock even when it is not synchronized to an external time source.

### 2.3. Restart Chrony

Save the file using `Ctrl+O`, press `Enter`, and exit with `Ctrl+X`.

Restart Chrony:

```bash
sudo systemctl restart chrony
```

## Step 3: Configure the Time Client (Client PC)

Perform these steps on the Ubuntu 22.04 client computer.

### 3.1. Install Chrony

```bash
sudo apt update && sudo apt install -y chrony
```

### 3.2. Edit the Chrony Configuration

Open the configuration file:

```bash
sudo nano /etc/chrony/chrony.conf
```

Comment out any existing default internet time sources by adding `#` to the beginning of lines starting with `pool` or `server`.

For example:

```conf
# pool ntp.ubuntu.com iburst
```

Then add the following configuration:

```conf
# Point to the Master PC's static Ethernet IP
server 192.168.1.10 iburst minpoll 2 maxpoll 4
```

The polling settings specify a minimum polling interval of 4 seconds and a maximum of 16 seconds.

### 3.3. Restart Chrony

Save the file using `Ctrl+O`, press `Enter`, and exit with `Ctrl+X`.

Restart Chrony:

```bash
sudo systemctl restart chrony
```

## Step 4: Verify Synchronization

Run the following commands on the Ubuntu 22.04 client.

### 4.1. Check Time Sources

```bash
chronyc sources
```

Look for the master server's IP address:

```text
192.168.1.10
```

A `^*` marker next to the source indicates that Chrony has selected it as the current synchronization source.

### 4.2. Check Synchronization Details

```bash
chronyc tracking
```

Review the following fields:

- **Reference ID:** Identifies the current time source.
- **Stratum:** Indicates the source's position in the time synchronization hierarchy.
- **Last offset:** Reports the estimated offset between the local clock and the reference source.
- **RMS offset:** Reports the root-mean-square offset over time.
- **Leap status:** Should eventually report `Normal` when synchronization is established.

On a wired Ethernet network, the offset may settle below one millisecond. Actual accuracy depends on the hardware, network conditions, clock behavior, and synchronization configuration.

## Troubleshooting

If the client does not synchronize with the master, check the following.

### Check Chrony Service Status

Run on both computers:

```bash
systemctl status chrony
```

### Check the Master Server's Sources

Run on the master:

```bash
chronyc sources
chronyc tracking
```

### Check Network Connectivity

Run on the client:

```bash
ping -c 4 192.168.1.10
```

### Check Firewall Rules

Ensure UDP port `123` is permitted between the client and master if a firewall is enabled.

### Check Chrony Client Access

On the master:

```bash
chronyc clients
```

This displays clients that have recently accessed the server.

---

## Summary

| Component | Configuration |
|---|---|
| Master OS | Ubuntu 24.04 |
| Client OS | Ubuntu 22.04 |
| Master IP | `192.168.1.10` |
| Client IP | `192.168.1.11` |
| Time protocol | NTP via Chrony |
| NTP transport | UDP port `123` |
| Client polling interval | 4–16 seconds |
| Synchronization verification | `chronyc sources` and `chronyc tracking` |