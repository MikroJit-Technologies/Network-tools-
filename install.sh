#!/usr/bin/env sh
set -eu

repo_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
dry_run=0
install_deps=0
check_only=0
no_verify=0
stamp="$(date +%Y%m%d-%H%M%S)"

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --dry-run       Show what would change without writing files.
  --check         Check this machine without installing files.
  --install-deps  Install recommended network packages, then install nt.
  --no-verify     Skip repo verification before installing.
EOF
}

log() {
  printf '%s\n' "$*"
}

section() {
  log ""
  log "==> $*"
}

warn() {
  printf 'warning: %s\n' "$*" >&2
}

run() {
  if [ "$dry_run" -eq 1 ]; then
    printf 'dry-run: %s\n' "$*"
  else
    "$@"
  fi
}

has() {
  command -v "$1" >/dev/null 2>&1
}

recommended_packages() {
  printf '%s\n' 'iproute2 net-tools iputils-ping traceroute mtr-tiny dnsutils curl wget netcat-openbsd nmap tcpdump tshark ethtool wireless-tools network-manager nftables ufw openssh-client rsync tailscale wireguard openvpn'
}

install_dependencies() {
  section "Installing recommended packages"

  if has apt; then
    run sudo apt update
    # shellcheck disable=SC2046
    run sudo apt install -y $(recommended_packages)
  else
    warn "No supported package manager found. Install manually:"
    printf '  %s\n' "$(recommended_packages)"
  fi
}

check_tools() {
  section "Checking network tools"

  missing=''
  for cmd in ip ss ping curl dig nmap tcpdump tshark tailscale wg openvpn; do
    if has "$cmd"; then
      printf 'ok      %-10s %s\n' "$cmd" "$(command -v "$cmd")"
    else
      printf 'missing %s\n' "$cmd"
      missing="$missing $cmd"
    fi
  done

  if [ -n "$missing" ]; then
    warn "missing recommended commands:$missing"
    printf 'Suggested install command:\n  sudo apt update && sudo apt install -y %s\n' "$(recommended_packages)"
  fi
}

install_file() {
  src="$1"
  dest="$2"

  if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
    log "unchanged $dest"
    return 0
  fi

  if [ -f "$dest" ]; then
    run cp "$dest" "$dest.backup.$stamp"
  fi

  run mkdir -p "$(dirname -- "$dest")"
  run cp "$src" "$dest"
  run chmod +x "$dest"

  if [ "$dry_run" -eq 1 ]; then
    log "would install $dest"
  else
    log "installed $dest"
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) dry_run=1 ;;
    --check) check_only=1 ;;
    --install-deps) install_deps=1 ;;
    --no-verify) no_verify=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
  shift
done

section "network-tools installer"

if [ "$install_deps" -eq 1 ]; then
  install_dependencies
fi

check_tools

if [ "$check_only" -eq 1 ]; then
  log ""
  log "Check complete. No files were changed."
  exit 0
fi

if [ "$no_verify" -ne 1 ]; then
  section "Verifying repo"
  "$repo_dir/verify.sh"
fi

section "Installing files"
install_file "$repo_dir/bin/nt" "$HOME/.local/bin/nt"
install_file "$repo_dir/completions/nt.zsh" "$HOME/.config/network-tools/completions/nt.zsh"

section "Post-install check"
if [ "$dry_run" -eq 1 ]; then
  log "dry-run: $HOME/.local/bin/nt doctor"
else
  "$HOME/.local/bin/nt" doctor >/dev/null
  log "nt doctor ok"
fi

log ""
log "Installed network-tools."
log 'Run: nt help'
