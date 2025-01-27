#!/bin/bash
BACKUP_FILE=/var/backups/ramdisk-backup.tar.gz

# Restore data to the RAM disk
if [ -f "$BACKUP_FILE" ]; then
  if mountpoint -q /mnt/ramdisk; then
    tar -xzf "$BACKUP_FILE" -C /mnt/ramdisk
    echo "RAM disk data restored from $BACKUP_FILE"
  else
    echo "RAM disk is not mounted. Cannot restore data."
  fi
else
  echo "No backup file found at $BACKUP_FILE"
fi
