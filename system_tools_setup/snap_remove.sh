#!/bin/sh
set -efu

SCRIPT_NAME=$(basename "$0")
export LC_ALL=C

usage() {
  cat <<EOF
Usage:
  sudo ./$SCRIPT_NAME

Purpose:
  Remove installed snaps, purge snapd, and block its installation through APT.

What it changes:
  - removes snaps with --purge (no automatic data snapshots)
  - lets APT purge snapd and its system data and services
  - deletes the invoking user's snap directory (SUDO_USER when run with sudo)
  - replaces any snapd hold with /etc/apt/preferences.d/nosnap.pref

Important:
  Back up needed Snap application data before running this script.
  Snap removal affects all users; extra home cleanup targets only the caller.
  Firefox packages, repositories, and holds are not changed.
  Failed removal or remaining mounts cause an error, not forced unmounting.

Options:
  -h, --help            Show this help message and exit
EOF
}

die() {
  echo "ERROR: $*" >&2
  exit 1
}

if [ "$#" -gt 1 ]; then
  usage >&2
  exit 2
fi
case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  "") ;;
  *) usage >&2; exit 2 ;;
esac

[ "$(id -u)" -eq 0 ] || die "Run with sudo: sudo sh $0"

for cmd in apt-get apt-mark dpkg-query getent readlink timeout awk tee; do
  command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
done

# Resolve the caller through passwd, rather than trusting sudo's HOME.
target_user=${SUDO_USER:-root}
passwd_entry=$(getent passwd "$target_user") || die "Cannot resolve user: $target_user"
target_home=$(printf '%s\n' "$passwd_entry" | cut -d: -f6)
case "$target_home" in
  /*) ;;
  *) die "Invalid home directory for $target_user" ;;
esac
target_home=$(readlink -e -- "$target_home") || die "Home directory does not exist"
[ "$target_home" != / ] || die "Refusing to clean a home directory at /"

# mountinfo encodes whitespace and backslashes as octal escapes. Decode each
# mount point before comparing, including bind mounts on the same filesystem.
check_mounts() {
  mount_paths=$(awk '{print $5}' /proc/self/mountinfo) || die "Cannot read mount table"
  while IFS= read -r encoded; do
    [ -n "$encoded" ] || continue
    mount_path=$(printf '%b' "$encoded")
    for data_dir in /snap /var/snap /var/lib/snapd /var/cache/snapd "$target_home/snap"; do
      case "$mount_path" in
        "$data_dir"|"$data_dir"/*)
          die "Mount still active: $mount_path. Resolve it before rerunning."
          ;;
      esac
    done
  done <<EOF
$mount_paths
EOF
}

list_snaps() {
  # Do not let a failed query become an apparently empty list through a pipe.
  snap_output=$(timeout 30s snap list) || die "Cannot list snaps; check snapd.service and snapd.socket"
  packages=$(printf '%s\n' "$snap_output" | awk 'NR > 1 {print $1}')
  if [ -n "$snap_output" ]; then
    header=$(printf '%s\n' "$snap_output" | awk 'NR == 1 {print $1}')
    [ "$header" = Name ] || die "Unexpected snap list output: $snap_output"
  fi
  package_count=$(printf '%s\n' "$packages" | awk 'NF {n++} END {print n+0}')
}

read_snapd_status() {
  # Query the database as a whole: a missing package is normal, but a failed
  # database query must not be mistaken for an already completed purge.
  dpkg_states=$(dpkg-query -W -f='${Package} ${db:Status-Status}\n') || die "Cannot query the dpkg database"
  snapd_status=$(printf '%s\n' "$dpkg_states" | awk '$1 == "snapd" {print $2}')
  snapd_status=${snapd_status:-not-installed}
}

echo "Removing Snap application data for $target_user ($target_home/snap)."
read_snapd_status
case "$snapd_status" in
  installed)
    command -v snap >/dev/null 2>&1 || die "snapd is installed but the snap command is missing"
    list_snaps
    while [ "$package_count" -gt 0 ]; do
      previous_count=$package_count
      # Retry dependency failures after other packages have been removed.
      # The snapd snap must be kept until all other snaps are gone.
      for pkg in $packages; do
        if [ "$pkg" = snapd ] && [ "$previous_count" -gt 1 ]; then
          continue
        fi
        echo "Removing snap: $pkg"
        if timeout 300s snap remove --purge "$pkg"; then
          :
        else
          result=$?
          if [ "$result" -eq 124 ] || [ "$result" -eq 137 ]; then
            die "Timed out removing $pkg; inspect snap changes before rerunning"
          fi
          echo "Removal failed for $pkg; retrying only if this round makes progress." >&2
        fi
      done
      list_snaps
      if [ "$package_count" -ge "$previous_count" ]; then
        die "No progress removing snaps. Remaining packages: $packages"
      fi
    done
    ;;
  not-installed|config-files) ;;
  *) die "snapd has an incomplete dpkg state: $snapd_status. Repair it first." ;;
esac

# snap remove performs normal unmounting; APT's maintainer scripts stop services.
# Do not purge data underneath any leftover mount.
check_mounts
held_packages=$(apt-mark showhold) || die "Cannot read APT holds"
if printf '%s\n' "$held_packages" | grep -qx snapd; then
  apt-mark unhold snapd
fi
if [ "$snapd_status" != not-installed ]; then
  apt-get purge -y snapd
fi
read_snapd_status
[ "$snapd_status" = not-installed ] || die "snapd was not fully purged: $snapd_status"

echo "Blocking snapd installation through APT..."
install -d -m 0755 /etc/apt/preferences.d
cat <<EOF | tee /etc/apt/preferences.d/nosnap.pref >/dev/null
Package: snapd
Pin: version *
Pin-Priority: -10
EOF

check_mounts
# APT owns system directory cleanup. Do not manually remove /usr/lib/snapd.
# rm removes a final-component symlink itself, not the directory it points to.
rm -rf -- "$target_home/snap"

echo "SUCCESS: snapd purged, APT blocking policy written, and $target_user's snap directory removed."
