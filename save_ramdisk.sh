#!/bin/bash
BACKUP_DIR=/var/backups
BACKUP_FILE=$BACKUP_DIR/ramdisk-backup.tar.gz

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"
chown root:root "$BACKUP_DIR"
chmod 755 "$BACKUP_DIR"

# Save the RAM disk contents
if mountpoint -q /mnt/ramdisk; then
  tar -czf "$BACKUP_FILE" -C /mnt/ramdisk .
  echo "RAM disk data saved to $BACKUP_FILE"
else
  echo "RAM disk is not mounted. Nothing to save."
fi
