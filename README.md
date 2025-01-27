
# RamDisk for Debian 12
In this Tutorial, I will show you how to create a Ram-disk using brd.ko on Debian 12.
RAM Drive will be saved in backup file whenever process will stop, and restore information from it when process starts.
___
> Note:
> Currently, only configuration files are available, and you can download these files. In the future, I'll create an installation script file.
## Structure

What should be in the end:
- RAM-disk: `/mnt/ramdisk`  
- Module: `brd.ko` (1G, autostart after loading system)  
- Reserve copy: `/var/backups/ramdisk-backup.tar.gz`  

## Service
 - `mount-ramdisk.service` - creating and mounting RAM-disk.

## Script
`/usr/local/bin/restore_ramdisk.sh`  
`/usr/local/bin/save_ramdisk.sh`  


## Getting Started

[Installation](#installation)
- [Creating mounting point](#creating-mounting-point)
[Creating Services and Scripts](#creating-services-and-scripts)
- [Creating backup directory](#creating-backup-directory)
- [Creating Reserved copy](#creating-reserved-copy)
- [Restore Data](#restore-data)
- [Service for mounting RAM-disk](#service-for-mounting-ram-disk) 
[Applying and testing](#applying-and-testing)
- [Checking backup](#checking-backup)

# Installation

Use this command to set a block inside of your memory with 1G.
`echo "options brd rd_nr=1 rd_size=1048576" | sudo tee /etc/modprobe.d/brd.conf`

- `rd_nr=1` - RAM disk quantity.
- `rd_size=1048576` - Disk size.

### Update 'initramfs' to apply configuration:
```sudo update-initramfs -u```

### Check module for loading up
`modprobe brd`. It will load the configuration that you have already created.
```sudo modprobe brd```  

Check your device that was loaded.
```lsmod | grep brd```  
```ls/dev/ram*```


## Creating mounting point
```
sudo mkdir -p /mnt/ramdisk
sudo chown $USER:$GROUP /mnt/ramdisk
sudo chmod 700 /mnt/ramdisk
```
This will create a directory in `/mnt/`.
Then you will assign a user and group of the current user that will have access to it.
With `chmod 700` you will give read and write access to this folder of the current user.
> Note:
> `$USER:$GROUP` applies the current user from the bash command. If you want to switch to a system account,
> type `su -` and enter the Password of the root account. After that applying `$USER:$GROUP` will connect with the root account. Otherwise, you can use instead of `$USER:$GROUP` different account or group like this,
>`root:root` or your account:group, similar to mine `zerekis:zerekis`


## Creating Services and Scripts

## Creating backup directory
```
sudo mkdir -p /var/backups
sudo chown root:root /var/backups
sudo chmod 755 /var/backups
```
> Note:
> `/var` should be restricted for users. Only Administrator privileges should have access to this. That's why I will assign system account privileges to it.

## Creating Reserved copy
A Reserve copy will be created when service `mount-ramdisk.service` stops. 

Create the file `save_ramdisk.sh` and insert the next block of code:
```sudo nano /usr/local/bin/save_ramdisk.sh```

```
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
```

Make this file executable:
```sudo chmod +x /usr/local/bin/save_ramdisk.sh```


### Restore Data
Use this command to create the file: 
```sudo nano /usr/local/bin/restore_ramdisk.sh```

Paste or type this code into the script:
```
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
```

### Make a script executable

```sudo chmod +x /usr/local/bin/restore_ramdisk.sh```

## Service for mounting RAM-disk

Create file:
`sudo nano /etc/systemd/system/mount-ramdisk.service`

And insert this code:
```
[Unit]
Description=Mount RAM Disk using brd module
After=local-fs.target
Wants=local-fs.target

[Service]
Type=oneshot
RemainAfterExit=true

ExecStartPre=/sbin/modprobe brd rd_nr=1 rd_size=1048576
ExecStartPre=/bin/bash -c 'mkdir -p /mnt/ramdisk && chmod 755 /mnt/ramdisk'

ExecStart=/sbin/mkfs.ext4 -q /dev/ram0

ExecStartPost=/bin/mount /dev/ram0 /mnt/ramdisk
ExecStartPost=/bin/bash -c 'chown -R $(id -un):"$(id -gn)" /mnt/ramdisk'
ExecStartPost=/bin/chmod -R 700 /mnt/ramdisk
ExecStartPost=/usr/local/bin/restore_ramdisk.sh

ExecStop=/usr/local/bin/save_ramdisk.sh
ExecStopPost=/bin/umount /mnt/ramdisk
ExecStopPost=/sbin/rmmod brd

[Install]
WantedBy=multi-user.target

```


### Applying and testing
#### Activating Services
Apply configuration:
```
sudo systemctl daemon-reload
```
Enable this service:
```
sudo systemctl enable mount-ramdisk.service
```

#### Checking backup

`ls -l /var/backups/ramdisk-backup.tar.gz`

#### Restarting RAM-drive and checking restored backup
```
sudo systemctl restart mount-ramdisk.service
sudo ls -l /mnt/ramdisk
sudo systemctl status mount-ramdisk.service
```