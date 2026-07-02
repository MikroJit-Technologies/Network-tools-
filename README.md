# Network Tools

[![CI](https://github.com/MikroJit-Technologies/Network-tools-/actions/workflows/ci.yml/badge.svg)](https://github.com/MikroJit-Technologies/Network-tools-/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A single `nt` command that wraps the network diagnostics you'd otherwise
chase across a dozen tools — interfaces, routes, DNS, HTTP/TLS, ports, VPN,
and firewall status — on macOS and Linux.

```
$ nt quick

==> Local command
/Users/you/.local/bin/nt
version 0.4.0

==> Interfaces
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	inet 10.10.20.14 netmask 0xffffff00 broadcast 10.10.20.255

==> Default route
default            10.10.20.1         UGSc

==> DNS
==> Query github.com
140.82.121.3

==> Public IP
203.0.113.42
```

No config files, no daemons — it's a POSIX shell script that shells out to
tools already on your machine (or tells you what's missing).

## Why

Diagnosing a network issue usually means remembering the right invocation for
`dig` vs `nslookup`, `ip` vs `ifconfig`, `ss` vs `netstat` — and it's
different on macOS and Linux. `nt` picks the right tool for the OS, degrades
gracefully when something isn't installed, and gives every check the same
shape so you can script around it.

## Install

Guided setup (recommended for first-time installs):

```sh
git clone https://github.com/MikroJit-Technologies/Network-tools-.git
cd Network-tools-
./setup.sh
```

Direct install, no prompts:

```sh
./install.sh
```

Install with recommended network packages first (auto-detects `brew`, `apt`,
`dnf`, or `pacman`):

```sh
./install.sh --install-deps
```

Any of these installs:

- `nt` to `~/.local/bin/nt`
- Zsh completion to `~/.config/network-tools/completions/nt.zsh`
- Shell integration to `~/.config/network-tools/network-tools.zsh`
- A managed block in `~/.zshrc` so completion loads automatically

Make sure `~/.local/bin` is on your `PATH`.

### Other install flags

```sh
./install.sh --check        # inspect this machine, install nothing
./install.sh --dry-run      # show what would change
./install.sh --update       # git pull, then reinstall
./install.sh --wizard       # interactive setup (same as setup.sh)
./install.sh --no-shell     # skip completion/shell integration
./install.sh --no-rc        # don't touch ~/.zshrc
./setup.sh --reset          # uninstall, then run the wizard fresh
```

Equivalent `make` targets: `make setup`, `make install`, `make install-full`,
`make update`.

## Commands

| Command | What it does |
|---|---|
| `nt doctor` | Installed vs. missing network tools, grouped by OS |
| `nt quick` | Fast connectivity check: interfaces, default route, DNS, public IP |
| `nt tools` | Full tool inventory grouped by purpose |
| `nt summary` | Interfaces, routes, DNS, public IP, and listening ports in one pass |
| `nt interfaces` | Interface addresses and link state |
| `nt routes` | Routing table and rules |
| `nt dns [host]` | Resolver status and a DNS query (default `github.com`) |
| `nt http [url]` | HTTP response headers with timing breakdown |
| `nt tls <host> [port]` | TLS certificate subject, issuer, dates, fingerprint |
| `nt whois <target>` | `whois`, falling back to an RDAP lookup |
| `nt ping [host]` | Ping a host (default `1.1.1.1`) |
| `nt trace [host]` | Route trace via `mtr`, `traceroute`, or `tracepath` |
| `nt ports` | Listening TCP/UDP ports |
| `nt scan <target>` | Fast top-100-port `nmap` scan |
| `nt capture [iface] [file]` | `tcpdump` packet capture to a file |
| `nt wifi` | Wi-Fi device and connection status |
| `nt monitor [seconds]` | Re-run `summary` on a loop |
| `nt export [file]` | Write a full diagnostic report to a text file |
| `nt vpn` | Tailscale, WireGuard, and OpenVPN status |
| `nt firewall` | pf (macOS) or UFW/nftables/iptables (Linux) status |
| `nt speed` | Run `speedtest` or `speedtest-cli` if installed |
| `nt myip` | Public IP address |
| `nt path` | Where `nt` and its config files are installed |
| `nt fix` | Clear a stale shell alias and reload shell integration |
| `nt selftest` | Smoke-test core commands and shell integration |

Run `nt help` for the full usage summary.

## Uninstall

```sh
./uninstall.sh            # remove installed files and the ~/.zshrc block
./uninstall.sh --dry-run  # preview what would be removed
```

## Verify

```sh
./verify.sh      # shell syntax checks + smoke tests (+ shellcheck if installed)
make verify
nt selftest
```

## How it works

`bin/nt` is a single POSIX (`sh`) script — no Bash-only syntax, no external
runtime. Every command:

- picks the right underlying tool for `Darwin` vs `Linux` (e.g. `ifconfig`
  vs `ip`, `netstat` vs `ss`, `pfctl` vs `nftables`/`ufw`)
- checks with `command -v` before running anything, and reports `missing
  <command>` instead of failing silently
- writes plain text to stdout, so output pipes cleanly into `nt export` or
  your own scripts

The installer (`install.sh`) is idempotent: re-running it backs up any file
it's about to overwrite (`<file>.backup.<timestamp>`) and skips files that
are already up to date.

## Documentation

- [docs/nt.md](docs/nt.md) — command reference and troubleshooting
- [CHANGELOG.md](CHANGELOG.md) — release notes

## Requirements

Nothing beyond a POSIX shell and the individual tools each command wraps —
`nt doctor` tells you what's missing. Recommended packages:

**Linux (apt)**

```sh
sudo apt update
sudo apt install -y iproute2 net-tools iputils-ping traceroute mtr-tiny dnsutils whois openssl curl wget netcat-openbsd nmap tcpdump tshark ethtool wireless-tools network-manager nftables ufw openssh-client rsync tailscale wireguard openvpn
```

**macOS (Homebrew)**

```sh
brew install curl wget nmap tcpdump wireshark mtr bind whois openssl netcat tailscale wireguard-tools openvpn
```

## License

MIT — see [LICENSE](LICENSE).
