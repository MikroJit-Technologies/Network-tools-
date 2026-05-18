#!/usr/bin/env sh
set -eu

repo_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
dry_run=0
install_deps=0
check_only=0
no_verify=0
no_shell=0
no_rc=0
update_repo=0
stamp="$(date +%Y%m%d-%H%M%S)"
os_name="$(uname -s)"
rc_marker_begin="# >>> network-tools >>>"
rc_marker_end="# <<< network-tools <<<"

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --dry-run       Show what would change without writing files.
  --check         Check this machine without installing files.
  --install-deps  Install recommended network packages, then install nt.
  --no-verify     Skip repo verification before installing.
  --no-shell      Skip installing shell integration file.
  --no-rc         Do not update ~/.zshrc with shell integration.
  --update        Pull the latest git changes before installing.
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
  case "$os_name" in
    Darwin)
      printf '%s\n' 'curl wget nmap tcpdump wireshark mtr bind whois openssl netcat tailscale wireguard-tools openvpn'
      ;;
    Linux)
      printf '%s\n' 'iproute2 net-tools iputils-ping traceroute mtr-tiny dnsutils whois openssl curl wget netcat-openbsd nmap tcpdump tshark ethtool wireless-tools network-manager nftables ufw openssh-client rsync tailscale wireguard openvpn'
      ;;
    *)
      printf '%s\n' 'curl wget nmap tcpdump whois openssl'
      ;;
  esac
}

install_dependencies() {
  section "Installing recommended packages"

  if [ "$os_name" = "Darwin" ] && has brew; then
    # shellcheck disable=SC2046
    run brew install $(recommended_packages)
  elif has apt; then
    run sudo apt update
    # shellcheck disable=SC2046
    run sudo apt install -y $(recommended_packages)
  elif has dnf; then
    # shellcheck disable=SC2046
    run sudo dnf install -y $(recommended_packages)
  elif has pacman; then
    # shellcheck disable=SC2046
    run sudo pacman -S --needed $(recommended_packages)
  else
    warn "No supported package manager found. Install manually:"
    printf '  %s\n' "$(recommended_packages)"
  fi
}

update_repository() {
  section "Updating repository"

  if [ -d "$repo_dir/.git" ] && has git; then
    run git -C "$repo_dir" pull --ff-only
  else
    warn "This directory is not a git checkout; skipping update."
  fi
}

check_tools() {
  section "Checking network tools"
  log "OS: $os_name"

  missing=''
  for cmd in ping curl openssl nmap tcpdump tailscale openvpn; do
    if has "$cmd"; then
      printf 'ok      %-10s %s\n' "$cmd" "$(command -v "$cmd")"
    else
      printf 'missing %s\n' "$cmd"
      missing="$missing $cmd"
    fi
  done

  if [ -n "$missing" ]; then
    warn "missing recommended commands:$missing"
    if [ "$os_name" = "Darwin" ]; then
      printf 'Suggested install command:\n  brew install %s\n' "$(recommended_packages)"
    elif has apt; then
      printf 'Suggested install command:\n  sudo apt update && sudo apt install -y %s\n' "$(recommended_packages)"
    else
      printf 'Recommended packages:\n  %s\n' "$(recommended_packages)"
    fi
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

install_zshrc_block() {
  zshrc="$HOME/.zshrc"
  integration='$HOME/.config/network-tools/network-tools.zsh'
  integration_line="[ -r \"$integration\" ] && source \"$integration\""

  if [ "$no_shell" -eq 1 ] || [ "$no_rc" -eq 1 ]; then
    return 0
  fi

  if [ -f "$zshrc" ] &&
    grep -F "$rc_marker_begin" "$zshrc" >/dev/null 2>&1 &&
    grep -F "$integration_line" "$zshrc" >/dev/null 2>&1; then
    log "unchanged $zshrc network-tools block"
    return 0
  fi

  if [ -f "$zshrc" ]; then
    run cp "$zshrc" "$zshrc.backup.$stamp"
  fi

  run mkdir -p "$(dirname -- "$zshrc")"
  if [ "$dry_run" -eq 1 ]; then
    log "would update $zshrc with network-tools shell integration"
  else
    if [ -f "$zshrc" ] && grep -F "$rc_marker_begin" "$zshrc" >/dev/null 2>&1; then
      tmp="${zshrc}.network-tools.$$"
      awk -v begin="$rc_marker_begin" -v end="$rc_marker_end" '
        $0 == begin { skip = 1; next }
        $0 == end { skip = 0; next }
        skip != 1 { print }
      ' "$zshrc" >"$tmp"
      mv "$tmp" "$zshrc"
    fi
    {
      printf '\n%s\n' "$rc_marker_begin"
      printf '%s\n' "$integration_line"
      printf '%s\n' "$rc_marker_end"
    } >>"$zshrc"
    log "updated $zshrc with network-tools shell integration"
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) dry_run=1 ;;
    --check) check_only=1 ;;
    --install-deps) install_deps=1 ;;
    --no-verify) no_verify=1 ;;
    --no-shell) no_shell=1 ;;
    --no-rc) no_rc=1 ;;
    --update) update_repo=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
  shift
done

section "network-tools installer"

if [ "$update_repo" -eq 1 ]; then
  update_repository
fi

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
if [ "$no_shell" -ne 1 ]; then
  install_file "$repo_dir/shell/network-tools.zsh" "$HOME/.config/network-tools/network-tools.zsh"
fi
install_zshrc_block

section "Post-install check"
if [ "$dry_run" -eq 1 ]; then
  log "dry-run: $HOME/.local/bin/nt doctor"
else
  "$HOME/.local/bin/nt" doctor >/dev/null
  log "nt doctor ok"
  if has zsh && [ -f "$HOME/.zshrc" ]; then
    zsh -n "$HOME/.zshrc"
    log "zshrc syntax ok"
  fi
fi

log ""
log "Installed network-tools."
log 'Run: nt help'
log 'If this terminal still has an old nt alias, run: unalias nt 2>/dev/null; hash -r'
