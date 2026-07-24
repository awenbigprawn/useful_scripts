#!/bin/sh
set -eu

TARGET_KHZ_DEFAULT=800000
CPUFREQ_BASE="/sys/devices/system/cpu/cpufreq"
SCRIPT_NAME=$(basename "$0")

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME [target_khz]

Purpose:
  Lock CPU scaling policies to a fixed frequency and disable boost/turbo.

Arguments:
  target_khz            Target CPU frequency in kHz (default: $TARGET_KHZ_DEFAULT)

Options:
  -h, --help            Show this help message and exit

Example:
  sudo ./$SCRIPT_NAME 800000
EOF
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
esac

if [ $# -gt 1 ]; then
  echo "ERROR: Too many arguments." >&2
  usage >&2
  exit 2
fi

TARGET_KHZ="${1:-$TARGET_KHZ_DEFAULT}"
set -x

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: run as root: sudo $0 [target_khz]" >&2
  exit 1
fi

if [ ! -d "$CPUFREQ_BASE" ]; then
  echo "ERROR: $CPUFREQ_BASE not found; cpufreq not available?" >&2
  exit 1
fi

echo "Target frequency: ${TARGET_KHZ} kHz"

if [ -f "$CPUFREQ_BASE/boost" ]; then
  echo 0 > "$CPUFREQ_BASE/boost"
  echo "Set $CPUFREQ_BASE/boost = 0 (boost disabled)"
else
  echo "Note: $CPUFREQ_BASE/boost not present"
fi

if [ -f "/sys/devices/system/cpu/intel_pstate/no_turbo" ]; then
  echo 1 > "/sys/devices/system/cpu/intel_pstate/no_turbo"
  echo "Set /sys/devices/system/cpu/intel_pstate/no_turbo = 1 (turbo disabled)"
else
  echo "Note: /sys/devices/system/cpu/intel_pstate/no_turbo not present"
fi

echo ""

found=0
for p in "$CPUFREQ_BASE"/policy*; do
  if [ ! -d "$p" ]; then
    continue
  fi
  found=1

  minf="$(cat "$p/cpuinfo_min_freq" 2>/dev/null || echo 0)"
  maxf="$(cat "$p/cpuinfo_max_freq" 2>/dev/null || echo 0)"
  drv="$(cat "$p/scaling_driver" 2>/dev/null || echo unknown)"

  if [ "$TARGET_KHZ" -lt "$minf" ] || [ "$TARGET_KHZ" -gt "$maxf" ]; then
    echo "WARN: ${p##*/}: target ${TARGET_KHZ} outside hw range [${minf}, ${maxf}] kHz; skipping"
    continue
  fi

  if [ -f "$p/scaling_available_governors" ] && grep -q "performance" "$p/scaling_available_governors"; then
    echo performance > "$p/scaling_governor" 2>/dev/null || true
  fi

  echo "$TARGET_KHZ" > "$p/scaling_min_freq"
  echo "$TARGET_KHZ" > "$p/scaling_max_freq"

  if [ -f "$p/scaling_setspeed" ]; then
    echo "$TARGET_KHZ" > "$p/scaling_setspeed" 2>/dev/null || true
  fi

  gov="$(cat "$p/scaling_governor" 2>/dev/null || echo n/a)"
  cur="$(cat "$p/scaling_cur_freq" 2>/dev/null || echo n/a)"
  echo "OK: ${p##*/}: driver=$drv gov=$gov min=$(cat "$p/scaling_min_freq") max=$(cat "$p/scaling_max_freq") cur=$cur"
done

if [ "$found" -eq 0 ]; then
  echo "ERROR: No policies found under $CPUFREQ_BASE/policy*" >&2
  exit 1
fi

echo ""
echo "Summary (scaling_cur_freq):"
grep -H . "$CPUFREQ_BASE"/policy*/scaling_cur_freq 2>/dev/null || true
