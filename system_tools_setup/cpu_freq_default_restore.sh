#!/bin/sh
set -eu

CPUFREQ_BASE="/sys/devices/system/cpu/cpufreq"
SCRIPT_NAME=$(basename "$0")

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME

Purpose:
  Restore CPU frequency scaling to a dynamic default configuration.

Options:
  -h, --help            Show this help message and exit

Notes:
  Re-enables boost/turbo when supported, restores each policy's min/max
  range, and picks a reasonable governor such as schedutil or ondemand.
EOF
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
  "")
    ;;
  *)
    echo "ERROR: $SCRIPT_NAME does not accept positional arguments." >&2
    usage >&2
    exit 2
    ;;
esac

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: run as root: sudo $0" >&2
  exit 1
fi

if [ ! -d "$CPUFREQ_BASE" ]; then
  echo "ERROR: $CPUFREQ_BASE not found; cpufreq not available?" >&2
  exit 1
fi

echo "Restoring CPU frequency settings to default (dynamic scaling)..."

if [ -f "$CPUFREQ_BASE/boost" ]; then
  echo 1 > "$CPUFREQ_BASE/boost"
  echo "Set $CPUFREQ_BASE/boost = 1 (boost enabled)"
else
  echo "Note: $CPUFREQ_BASE/boost not present"
fi

if [ -f "/sys/devices/system/cpu/intel_pstate/no_turbo" ]; then
  echo 0 > "/sys/devices/system/cpu/intel_pstate/no_turbo"
  echo "Set /sys/devices/system/cpu/intel_pstate/no_turbo = 0 (turbo enabled)"
else
  echo "Note: /sys/devices/system/cpu/intel_pstate/no_turbo not present"
fi

choose_governor() {
  f="$1"
  if [ ! -f "$f" ]; then
    echo ""
    return
  fi

  avail="$(cat "$f" 2>/dev/null || echo "")"

  echo "$avail" | grep -q "schedutil" && { echo "schedutil"; return; }
  echo "$avail" | grep -q "ondemand"  && { echo "ondemand"; return; }
  echo "$avail" | grep -q "powersave" && { echo "powersave"; return; }

  set -- $avail
  [ $# -ge 1 ] && echo "$1" || echo ""
}

echo ""
found=0
for p in "$CPUFREQ_BASE"/policy*; do
  [ -d "$p" ] || continue
  found=1

  minf="$(cat "$p/cpuinfo_min_freq" 2>/dev/null || echo 0)"
  maxf="$(cat "$p/cpuinfo_max_freq" 2>/dev/null || echo 0)"
  drv="$(cat "$p/scaling_driver" 2>/dev/null || echo unknown)"

  if [ -f "$p/scaling_min_freq" ]; then
    echo "$minf" > "$p/scaling_min_freq"
  fi
  if [ -f "$p/scaling_max_freq" ]; then
    echo "$maxf" > "$p/scaling_max_freq"
  fi

  if [ -f "$p/scaling_governor" ]; then
    gov="$(choose_governor "$p/scaling_available_governors")"
    if [ -n "$gov" ]; then
      echo "$gov" > "$p/scaling_governor" 2>/dev/null || true
    fi
  fi

  gov_now="$(cat "$p/scaling_governor" 2>/dev/null || echo n/a)"
  cur="$(cat "$p/scaling_cur_freq" 2>/dev/null || echo n/a)"
  echo "OK: ${p##*/}: driver=$drv gov=$gov_now min=$(cat "$p/scaling_min_freq" 2>/dev/null || echo n/a) max=$(cat "$p/scaling_max_freq" 2>/dev/null || echo n/a) cur=$cur"
done

if [ "$found" -eq 0 ]; then
  echo "ERROR: No policies found under $CPUFREQ_BASE/policy*" >&2
  exit 1
fi

echo ""
echo "Summary (scaling_cur_freq):"
grep -H . "$CPUFREQ_BASE"/policy*/scaling_cur_freq 2>/dev/null || true

echo ""
echo "Done."
