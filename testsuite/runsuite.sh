#!/bin/bash
set -euo pipefail

# Backup directory
BACKUP_DIR="./etc_backup"
mkdir -p "$BACKUP_DIR"

FILES=(passwd shadow group gshadow)
FAILED=()

# Ensure root
if [ "$(id -u)" -ne 0 ]; then
  echo "root needed" >&2
  exit 1
fi

# Backup critical files
for f in "${FILES[@]}"; do
  cp "/etc/$f" "$BACKUP_DIR/$f"
done

# Restore on exit
cleanup() {
  echo "Restoring original /etc files..."
  for f in "${FILES[@]}"; do
    cp "$BACKUP_DIR/$f" "/etc/$f"
  done
  rm -rf $BACKUP_DIR
}
trap cleanup EXIT

# Determine tests to run
if [ $# -ge 1 ]; then
  TESTS=("$1")
else
  TESTS=(./test*.pl)
fi

# Run tests with shadowconfig set to "on" only
for a in on; do
  if ! shadowconfig "$a" >/dev/null; then
    echo "shadowconfig $a failed" >&2
    exit 1
  fi

  for i in "${TESTS[@]}"; do
    echo
    echo "Starting $i (shadow $a)"
    if ! perl -I. "$i" < /dev/null; then
      FAILED+=("$i($a)")
    fi
  done
done

# Success/failure reporting
if [ "${#FAILED[@]}" -eq 0 ]; then
  echo "All tests passed successfully"
else
  echo "Tests failed: ${FAILED[*]}"
  echo "Original /etc files were restored from $BACKUP_DIR"
  exit 1
fi

