#!/bin/sh
set -eu

MAX_PWM_DEFAULT=255
RESTORE_ON_EXIT=0
HWMON_DIR=""

usage() {
  cat <<'EOF'
Usage:
  sudo ./fan_max.sh [--max <value>] [--hwmon <path>] [--restore-on-exit]

Options:
  --max <value>         PWM max value to write (default: 255)
  --hwmon <path>        Explicit hwmon path (e.g., /sys/class/hwmon/hwmon5)
  --restore-on-exit     Restore previous pwm values when the script exits

Examples:
  sudo ./fan_max.sh
  sudo ./fan_max.sh --max 255
  sudo ./fan_max.sh --hwmon /sys/class/hwmon/hwmon5
  sudo ./fan_max.sh --restore-on-exit
EOF
}

# Parse args
MAX_PWM="$MAX_PWM_DEFAULT"
while [ $# -gt 0 ]; do
  case "$1" in
    --max)
      [ $# -ge 2 ] || { echo "ERROR: --max requires a value" >&2; exit 2; }
      MAX_PWM="$2"
      shift 2
      ;;
    --hwmon)
      [ $# -ge 2 ] || { echo "ERROR: --hwmon requires a path" >&2; exit 2; }
      HWMON_DIR="$2"
      shift 2
      ;;
    --restore-on-exit)
      RESTORE_ON_EXIT=1
      shift 1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

# Root check (writing to /sys requires root)
if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: Please run as root (use sudo)." >&2
  exit 1
fi

# Auto-discover a hwmon dir if not provided
if [ -z "$HWMON_DIR" ]; then
  for d in /sys/class/hwmon/hwmon*; do
    if [ -e "$d/pwm1" ] && [ -e "$d/pwm2" ] && [ -e "$d/fan1_input" ] && [ -e "$d/fan2_input" ]; then
      HWMON_DIR="$d"
      break
    fi
  done
fi

if [ -z "$HWMON_DIR" ] || [ ! -d "$HWMON_DIR" ]; then
  echo "ERROR: Could not find a hwmon directory with pwm1/pwm2 and fan inputs." >&2
  echo "Hint: run: ls -R /sys/class/hwmon | egrep -i 'pwm|fan'" >&2
  exit 1
fi

if [ ! -w "$HWMON_DIR/pwm1" ] || [ ! -w "$HWMON_DIR/pwm2" ]; then
  echo "ERROR: pwm files are not writable: $HWMON_DIR/pwm1 or pwm2" >&2
  exit 1
fi

NAME="unknown"
[ -r "$HWMON_DIR/name" ] && NAME="$(cat "$HWMON_DIR/name" || true)"

OLD_PWM1="$(cat "$HWMON_DIR/pwm1")"
OLD_PWM2="$(cat "$HWMON_DIR/pwm2")"

cleanup() {
  if [ "$RESTORE_ON_EXIT" -eq 1 ]; then
    echo "$OLD_PWM1" > "$HWMON_DIR/pwm1" || true
    echo "$OLD_PWM2" > "$HWMON_DIR/pwm2" || true
    echo "Restored pwm1=$OLD_PWM1 pwm2=$OLD_PWM2"
  fi
}
trap cleanup EXIT INT TERM

echo "Using HWMON_DIR=$HWMON_DIR (name=$NAME)"
echo "Current: pwm1=$OLD_PWM1 pwm2=$OLD_PWM2"
echo "Setting both fans to max PWM=$MAX_PWM ..."

echo "$MAX_PWM" > "$HWMON_DIR/pwm1"
echo "$MAX_PWM" > "$HWMON_DIR/pwm2"

NEW_PWM1="$(cat "$HWMON_DIR/pwm1")"
NEW_PWM2="$(cat "$HWMON_DIR/pwm2")"
FAN1="$(cat "$HWMON_DIR/fan1_input" 2>/dev/null || echo "N/A")"
FAN2="$(cat "$HWMON_DIR/fan2_input" 2>/dev/null || echo "N/A")"

echo "Now: pwm1=$NEW_PWM1 pwm2=$NEW_PWM2"
echo "Fan RPM: fan1=$FAN1 fan2=$FAN2"
echo "Done."

