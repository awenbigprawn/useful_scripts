#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_NAME=$(basename "$0")

ETHERNET_INTERFACE="enp0s31f6"
ETHERNET_DRIVER="e1000e"
CONNECTION_PROFILE="Wired connection 1"
LAPTOP_CIDR="10.42.0.1/24"
PI_HOSTNAME="rpi5-realsense.local"
PI_USER="safebot"
PI_MAC="d8:3a:dd:dc:cf:3b"
WAIT_SECONDS=60
STATUS_ONLY=0
CONNECT_AFTER_SETUP=0
ALLOW_DRIVER_RELOAD=1

usage() {
  cat <<EOF
Usage:
  $SCRIPT_NAME [options]

Purpose:
  Recover and configure the laptop-to-Raspberry-Pi direct Ethernet link.
  Run this script on the laptop, not on the Raspberry Pi.

Options:
  --status                 Inspect the current state without changing anything
  --connect                Open SSH to the detected direct Ethernet address
  --interface NAME         Ethernet interface (default: $ETHERNET_INTERFACE)
  --driver MODULE          Ethernet driver (default: $ETHERNET_DRIVER)
  --profile NAME           NetworkManager profile (default: $CONNECTION_PROFILE)
  --laptop-cidr CIDR       Shared laptop address (default: $LAPTOP_CIDR)
  --pi-host HOSTNAME       Pi mDNS hostname (default: $PI_HOSTNAME)
  --pi-user USER           Pi SSH user (default: $PI_USER)
  --pi-mac MAC             Pi Ethernet MAC used for discovery (default: $PI_MAC)
  --wait-seconds N         Discovery timeout (default: $WAIT_SECONDS)
  --no-driver-reload       Fail instead of reloading a missing Ethernet driver
  -h, --help               Show this help message

Examples:
  $SCRIPT_NAME --status
  $SCRIPT_NAME
  $SCRIPT_NAME --connect
  $SCRIPT_NAME --profile "Wired connection 1" --connect
EOF
}

log() {
  printf '[rpi5-direct] %s\n' "$*"
}

warn() {
  printf '[rpi5-direct] WARNING: %s\n' "$*" >&2
}

die() {
  printf '[rpi5-direct] ERROR: %s\n' "$*" >&2
  exit 1
}

need_command() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

is_nonnegative_integer() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --status)
      STATUS_ONLY=1
      shift
      ;;
    --connect)
      CONNECT_AFTER_SETUP=1
      shift
      ;;
    --interface)
      [[ $# -ge 2 ]] || die "--interface requires a value"
      ETHERNET_INTERFACE="$2"
      shift 2
      ;;
    --driver)
      [[ $# -ge 2 ]] || die "--driver requires a value"
      ETHERNET_DRIVER="$2"
      shift 2
      ;;
    --profile)
      [[ $# -ge 2 ]] || die "--profile requires a value"
      CONNECTION_PROFILE="$2"
      shift 2
      ;;
    --laptop-cidr)
      [[ $# -ge 2 ]] || die "--laptop-cidr requires a value"
      LAPTOP_CIDR="$2"
      shift 2
      ;;
    --pi-host)
      [[ $# -ge 2 ]] || die "--pi-host requires a value"
      PI_HOSTNAME="$2"
      shift 2
      ;;
    --pi-user)
      [[ $# -ge 2 ]] || die "--pi-user requires a value"
      PI_USER="$2"
      shift 2
      ;;
    --pi-mac)
      [[ $# -ge 2 ]] || die "--pi-mac requires a value"
      PI_MAC="$2"
      shift 2
      ;;
    --wait-seconds)
      [[ $# -ge 2 ]] || die "--wait-seconds requires a value"
      WAIT_SECONDS="$2"
      shift 2
      ;;
    --no-driver-reload)
      ALLOW_DRIVER_RELOAD=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

need_command nmcli
need_command ip
need_command lspci
need_command modprobe
need_command ssh
need_command sudo

is_nonnegative_integer "$WAIT_SECONDS" ||
  die "--wait-seconds must be a nonnegative integer"

LAPTOP_IP="${LAPTOP_CIDR%/*}"
CIDR_PREFIX="${LAPTOP_CIDR##*/}"
[[ "$LAPTOP_IP" != "$LAPTOP_CIDR" ]] ||
  die "--laptop-cidr must include a prefix length"
[[ "$CIDR_PREFIX" == "24" ]] ||
  die "This helper currently requires a /24 laptop subnet"
DIRECT_PREFIX="${LAPTOP_IP%.*}."

show_status() {
  printf '%s\n' '--- NetworkManager devices ---'
  nmcli -f DEVICE,TYPE,STATE,CONNECTION device status || true

  printf '%s\n' '--- saved profile ---'
  if nmcli -g connection.id connection show "$CONNECTION_PROFILE" \
      >/dev/null 2>&1; then
    nmcli \
      -f connection.id,connection.interface-name,connection.autoconnect,ipv4.method,ipv4.addresses,ipv6.method \
      connection show "$CONNECTION_PROFILE" || true
  else
    printf 'Profile not found: %s\n' "$CONNECTION_PROFILE"
  fi

  printf '%s\n' '--- PCI Ethernet controller ---'
  lspci -s 00:1f.6 -nnk 2>/dev/null ||
    lspci -nnk | grep -A3 -i 'Ethernet controller' || true

  printf '%s\n' '--- driver binding ---'
  if [[ -L /sys/bus/pci/devices/0000:00:1f.6/driver ]]; then
    readlink /sys/bus/pci/devices/0000:00:1f.6/driver
  else
    printf 'unbound\n'
  fi

  printf '%s\n' '--- interface address ---'
  ip -4 address show dev "$ETHERNET_INTERFACE" 2>/dev/null || true

  printf '%s\n' '--- direct-link neighbors ---'
  ip neigh show dev "$ETHERNET_INTERFACE" 2>/dev/null || true

  printf '%s\n' '--- hostname resolution ---'
  getent hosts "$PI_HOSTNAME" 2>/dev/null || true
}

if [[ "$STATUS_ONLY" -eq 1 ]]; then
  show_status
  exit 0
fi

if [[ "$EUID" -eq 0 ]]; then
  SUDO=()
else
  SUDO=(sudo)
  "${SUDO[@]}" -v
fi

if [[ ! -d "/sys/class/net/$ETHERNET_INTERFACE" ]]; then
  [[ "$ALLOW_DRIVER_RELOAD" -eq 1 ]] ||
    die "$ETHERNET_INTERFACE is missing and driver reload is disabled"

  log "$ETHERNET_INTERFACE is missing; reloading $ETHERNET_DRIVER"
  if [[ -d "/sys/module/$ETHERNET_DRIVER" ]]; then
    "${SUDO[@]}" modprobe -r "$ETHERNET_DRIVER"
  fi
  "${SUDO[@]}" modprobe "$ETHERNET_DRIVER"

  for _ in {1..10}; do
    [[ -d "/sys/class/net/$ETHERNET_INTERFACE" ]] && break
    sleep 1
  done
fi

if [[ ! -d "/sys/class/net/$ETHERNET_INTERFACE" ]]; then
  warn "Recent $ETHERNET_DRIVER messages:"
  journalctl -k -b --no-pager 2>/dev/null |
    grep -i "$ETHERNET_DRIVER" |
    tail -n 20 >&2 || true
  die "$ETHERNET_INTERFACE did not appear after loading $ETHERNET_DRIVER"
fi

if nmcli -g connection.id connection show "$CONNECTION_PROFILE" \
    >/dev/null 2>&1; then
  PROFILE_TYPE=$(
    nmcli -g connection.type connection show "$CONNECTION_PROFILE"
  )
  [[ "$PROFILE_TYPE" == "802-3-ethernet" ||
     "$PROFILE_TYPE" == "ethernet" ]] ||
    die "Profile '$CONNECTION_PROFILE' is not an Ethernet profile"

  PROFILE_INTERFACE=$(
    nmcli -g connection.interface-name connection show "$CONNECTION_PROFILE"
  )
  if [[ -n "$PROFILE_INTERFACE" &&
        "$PROFILE_INTERFACE" != "$ETHERNET_INTERFACE" ]]; then
    die "Profile '$CONNECTION_PROFILE' belongs to $PROFILE_INTERFACE, not $ETHERNET_INTERFACE"
  fi

  log "Ensuring shared settings on profile '$CONNECTION_PROFILE'"
  "${SUDO[@]}" nmcli connection modify "$CONNECTION_PROFILE" \
    connection.interface-name "$ETHERNET_INTERFACE" \
    connection.autoconnect yes \
    ipv4.method shared \
    ipv4.addresses "$LAPTOP_CIDR" \
    ipv6.method disabled
else
  log "Creating shared profile '$CONNECTION_PROFILE'"
  "${SUDO[@]}" nmcli connection add \
    type ethernet \
    ifname "$ETHERNET_INTERFACE" \
    con-name "$CONNECTION_PROFILE" \
    connection.autoconnect yes \
    ipv4.method shared \
    ipv4.addresses "$LAPTOP_CIDR" \
    ipv6.method disabled
fi

log "Activating '$CONNECTION_PROFILE' on $ETHERNET_INTERFACE"
"${SUDO[@]}" nmcli connection up "$CONNECTION_PROFILE" \
  ifname "$ETHERNET_INTERFACE"

carrier=0
for _ in {1..15}; do
  if [[ -r "/sys/class/net/$ETHERNET_INTERFACE/carrier" ]] &&
     [[ "$(<"/sys/class/net/$ETHERNET_INTERFACE/carrier")" == "1" ]]; then
    carrier=1
    break
  fi
  sleep 1
done

[[ "$carrier" -eq 1 ]] ||
  die "No Ethernet carrier on $ETHERNET_INTERFACE; check Pi power and cable"

if ! ip -4 address show dev "$ETHERNET_INTERFACE" |
    grep -Fq "inet $LAPTOP_CIDR"; then
  ip -4 address show dev "$ETHERNET_INTERFACE" >&2 || true
  die "$ETHERNET_INTERFACE does not have $LAPTOP_CIDR"
fi

find_pi_ip() {
  local found_ip=""

  if [[ -n "$PI_MAC" ]]; then
    found_ip=$(
      ip neigh show dev "$ETHERNET_INTERFACE" |
        awk -v mac="$PI_MAC" '
          tolower($5) == tolower(mac) &&
          $NF != "FAILED" &&
          $NF != "INCOMPLETE" {
            print $1
            exit
          }
        '
    )
  fi

  if [[ -z "$found_ip" ]]; then
    found_ip=$(
      ip neigh show dev "$ETHERNET_INTERFACE" |
        awk -v prefix="$DIRECT_PREFIX" -v self="$LAPTOP_IP" '
          index($1, prefix) == 1 &&
          $1 != self &&
          $NF != "FAILED" &&
          $NF != "INCOMPLETE" {
            print $1
            exit
          }
        '
    )
  fi

  if [[ -z "$found_ip" ]]; then
    found_ip=$(
      { getent ahostsv4 "$PI_HOSTNAME" 2>/dev/null || true; } |
        awk -v prefix="$DIRECT_PREFIX" '
          index($1, prefix) == 1 {
            print $1
            exit
          }
        '
    )
  fi

  printf '%s' "$found_ip"
}

log "Waiting up to ${WAIT_SECONDS}s for the Pi"
PI_IP=""
for ((elapsed = 0; elapsed <= WAIT_SECONDS; elapsed++)); do
  PI_IP=$(find_pi_ip)
  [[ -n "$PI_IP" ]] && break
  [[ "$elapsed" -lt "$WAIT_SECONDS" ]] && sleep 1
done

if [[ -z "$PI_IP" ]]; then
  show_status >&2
  die "No Pi address discovered on $ETHERNET_INTERFACE"
fi

log "Pi direct Ethernet address: $PI_IP"
ping -c 1 -W 2 -I "$ETHERNET_INTERFACE" "$PI_IP" >/dev/null 2>&1 ||
  warn "The Pi did not answer ping; SSH may still work"

if [[ "$CONNECT_AFTER_SETUP" -eq 1 ]]; then
  log "Connecting to $PI_USER@$PI_IP"
  exec ssh \
    -o "HostKeyAlias=$PI_HOSTNAME" \
    "$PI_USER@$PI_IP"
fi

cat <<EOF

Direct link is ready.

Connect with:
  ssh -o HostKeyAlias=$PI_HOSTNAME $PI_USER@$PI_IP

Or, if mDNS selects the Ethernet address:
  ssh ${PI_HOSTNAME%.local}
EOF
