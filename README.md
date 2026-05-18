# Network Tools

Practical Linux network toolkit with one command for quick diagnostics, DNS
checks, port checks, scans, packet capture helpers, VPN status, and firewall
inspection.

The project is designed like `customizecmd`: installable, backup-aware,
repeatable, and easy to verify.

## Quick Install

```sh
./install.sh
```

This installs:

- `nt` command to `~/.local/bin/nt`
- shell completion to `~/.config/network-tools/completions/nt.zsh`

## Full Install

Install recommended packages first, then install the command:

```sh
./install.sh --install-deps
```

Equivalent Make targets:

```sh
make install
make install-full
```

## Usage

```sh
nt help
nt doctor
nt summary
nt dns github.com
nt ping 1.1.1.1
nt trace github.com
nt ports
nt scan 192.168.1.1
nt capture any
nt vpn
nt firewall
```

## Commands

- `doctor` - show installed network tools and missing recommendations
- `summary` - show interfaces, routes, DNS, public IP, and listening ports
- `interfaces` - show IP addresses and link details
- `routes` - show routes
- `dns [host]` - show resolver status and query a host
- `ping [host]` - ping a host
- `trace [host]` - trace a route with `mtr`, `traceroute`, or `tracepath`
- `ports` - show listening TCP/UDP ports
- `scan <target>` - run a fast top-port `nmap` scan
- `capture [iface] [file]` - run `tcpdump` packet capture
- `vpn` - show Tailscale, WireGuard, and OpenVPN status
- `firewall` - show UFW, nftables, and iptables status
- `speed` - run `speedtest` if installed
- `myip` - show public IP address

## Roll Back

```sh
./uninstall.sh
```

Preview rollback:

```sh
./uninstall.sh --dry-run
```

## Verify

```sh
./verify.sh
make verify
```

## Recommended Packages

```sh
sudo apt update
sudo apt install -y iproute2 net-tools iputils-ping traceroute mtr-tiny dnsutils curl wget netcat-openbsd nmap tcpdump tshark ethtool wireless-tools network-manager nftables ufw openssh-client rsync tailscale wireguard openvpn
```
