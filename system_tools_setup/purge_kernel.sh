#!/usr/bin/env bash
set -euo pipefail

PATTERN='share-budget'
BOOT_DIR='/boot'
MODULES_DIR='/lib/modules'

echo "==> Checking running kernel..."
RUNNING="$(uname -r)"
echo "    uname -r: ${RUNNING}"
if [[ "${RUNNING}" == *"${PATTERN}"* ]]; then
  echo "ERROR: You are currently running a '${PATTERN}' kernel (${RUNNING})."
  echo "Please reboot into a *-generic kernel first, then run this script again."
  exit 1
fi

echo "==> Scanning ${BOOT_DIR} for *${PATTERN}* artifacts..."
mapfile -t BOOT_MATCHES < <(ls -1 "${BOOT_DIR}" | grep -F "${PATTERN}" || true)

if (( ${#BOOT_MATCHES[@]} == 0 )); then
  echo "No /boot entries matching '*${PATTERN}*' found. Nothing to do."
else
  echo "Found ${#BOOT_MATCHES[@]} /boot entries to remove:"
  printf '  - %s\n' "${BOOT_MATCHES[@]}"
fi

echo "==> Scanning ${MODULES_DIR} for modules directories matching *${PATTERN}* ..."
mapfile -t MOD_MATCHES < <(find "${MODULES_DIR}" -mindepth 1 -maxdepth 1 -type d -name "*${PATTERN}*" -printf "%f\n" 2>/dev/null || true)

if (( ${#MOD_MATCHES[@]} == 0 )); then
  echo "No /lib/modules/*${PATTERN}* directories found."
else
  echo "Found ${#MOD_MATCHES[@]} module trees to remove:"
  printf '  - %s\n' "${MOD_MATCHES[@]}"
fi

echo
echo "==> DRY-RUN summary (what would be deleted):"
if (( ${#BOOT_MATCHES[@]} > 0 )); then
  echo "  /boot:"
  printf '    %s/%s\n' "${BOOT_DIR}" "${BOOT_MATCHES[@]}"
fi
if (( ${#MOD_MATCHES[@]} > 0 )); then
  echo "  /lib/modules:"
  printf '    %s/%s\n' "${MODULES_DIR}" "${MOD_MATCHES[@]}"
fi
echo

read -r -p "Proceed to DELETE these files/directories? Type 'yes' to continue: " ans
if [[ "${ans}" != "yes" ]]; then
  echo "Aborted."
  exit 0
fi

echo "==> Deleting /boot share-budget artifacts..."
for f in "${BOOT_MATCHES[@]:-}"; do
  [[ -e "${BOOT_DIR}/${f}" ]] || continue
  rm -f -- "${BOOT_DIR}/${f}"
done

echo "==> Deleting /lib/modules share-budget module trees..."
for d in "${MOD_MATCHES[@]:-}"; do
  [[ -d "${MODULES_DIR}/${d}" ]] || continue
  rm -rf -- "${MODULES_DIR}/${d}"
done

echo "==> Cleaning stale symlinks in /boot (vmlinuz/initrd.img/vmlinuz.old) if they point to deleted kernels..."
# Only remove symlinks if their target contains share-budget
for link in "${BOOT_DIR}/vmlinuz" "${BOOT_DIR}/initrd.img" "${BOOT_DIR}/vmlinuz.old"; do
  if [[ -L "${link}" ]]; then
    tgt="$(readlink -f "${link}" || true)"
    if [[ "${tgt}" == *"${PATTERN}"* ]]; then
      echo "    Removing symlink: ${link} -> ${tgt}"
      rm -f -- "${link}"
    fi
  fi
done

echo "==> Regenerating initramfs for installed *-generic kernels (safe no-op if already present)..."
# Rebuild initramfs for the currently installed kernels (generic) to avoid broken menu entries
# If you have multiple generic kernels, update-initramfs can handle it via -u -k all
update-initramfs -u -k all

echo "==> Updating GRUB menu..."
update-grub

echo "==> Done."
echo "You should now only see the *-generic kernels in GRUB."
echo "Tip: verify with: grep -n \"Found linux image\" -n /boot/grub/grub.cfg | head -n 50"

