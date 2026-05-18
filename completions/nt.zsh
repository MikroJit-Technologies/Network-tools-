#compdef nt

_nt() {
  local -a commands
  commands=(
    'doctor:show installed and missing network tools'
    'summary:show compact network overview'
    'interfaces:show interfaces'
    'routes:show routes'
    'dns:query DNS'
    'ping:ping a host'
    'trace:trace route to a host'
    'ports:show listening ports'
    'scan:run fast nmap scan'
    'capture:capture packets'
    'vpn:show VPN status'
    'firewall:show firewall status'
    'speed:run speedtest'
    'myip:show public IP'
    'help:show help'
  )

  _describe 'command' commands
}

_nt "$@"
