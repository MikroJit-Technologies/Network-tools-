#!/usr/bin/env sh
set -eu

dry_run=0
rc_marker_begin="# >>> network-tools >>>"
rc_marker_end="# <<< network-tools <<<"

usage() {
  cat <<'EOF'
Usage: ./uninstall.sh [options]

Options:
  --dry-run  Show what would be removed.
EOF
}

log() {
  printf '%s\n' "$*"
}

section() {
  log ""
  log "==> $*"
}

run() {
  if [ "$dry_run" -eq 1 ]; then
    printf 'dry-run: %s\n' "$*"
  else
    "$@"
  fi
}

remove_zshrc_block() {
  zshrc="$HOME/.zshrc"

  if [ ! -f "$zshrc" ] || ! grep -F "$rc_marker_begin" "$zshrc" >/dev/null 2>&1; then
    log "no network-tools block found in $zshrc"
    return 0
  fi

  if [ "$dry_run" -eq 1 ]; then
    log "would remove network-tools block from $zshrc"
    return 0
  fi

  tmp="${zshrc}.network-tools.$$"
  awk -v begin="$rc_marker_begin" -v end="$rc_marker_end" '
    $0 == begin { skip = 1; next }
    $0 == end { skip = 0; next }
    skip != 1 { print }
  ' "$zshrc" >"$tmp"
  mv "$tmp" "$zshrc"
  log "removed network-tools block from $zshrc"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) dry_run=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
  shift
done

section "Removing network-tools files"

for file in "$HOME/.local/bin/nt" "$HOME/.config/network-tools/completions/nt.zsh" "$HOME/.config/network-tools/network-tools.zsh"; do
  if [ -e "$file" ]; then
    run rm -f "$file"
    if [ "$dry_run" -eq 1 ]; then
      log "would remove $file"
    else
      log "removed $file"
    fi
  else
    log "not installed: $file"
  fi
done

section "Removing shell integration"
remove_zshrc_block

log ""
log "Done."
