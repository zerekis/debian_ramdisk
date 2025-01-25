
# RamDisk for Debian 12 

In this Tutorial I'll shall show you how to create a Ram Drive using brd.ko on Debian 12.
RAM Drive will be saved in backup file whenever process will stop. And restore information from it when process starts.

___
> Note:
> Currenty, only configuration process is available, and you can download these files. In the future, I'll create an installation script file.
## Structure

What should be in the end:
- RAM-disk: `/mnt/ramdisk`  
- Module: `brd.ko` (1G, autostart after loading system)  
- Reserve copy: `/var/backups/ramdisk-backup.tar.gz`  

## Service
 - `mount-ramdisk.service` - creating and mounting RAM-drive

## Script
`/usr/local/bin/restore_ramdisk.sh`  
`/usr/local/bin/save_ramdisk.sh`  


## Appendix

Any additional information goes here


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

`echo "options brd rd_nr=1 rd_size=1048576" | sudo tee /etc/modprobe.d/brd.conf`

- `rd_nr=1` - RAM disk quantity.
- `rd_size=1048576` - Disk size

### Update 'initramfs' to apply configuration:
`sudo update-initramfs -u`

### Check module for loading up
`sudo modprobe brd`
`lsmod | grep brd`  
`ls/dev/ram*`


## Creating mounting point
```
sudo mkdir -p /mnt/ramdisk
sudo chown $USER:$GROUP /mnt/ramdisk
sudo chmod 700 /mnt/ramdisk
```
This will create directory in `/mnt/`.
Than you will assign user and group of current user that will have an access to it.
With `chmod 700` you will give read and wirte access to this folder of current user.

> Note:
>  `$USER:$GROUP` applies current user from bash command. If you want to switch to system account,
>   type `su -` and enter Paassword of root. After that applying `$USER:$GROUP` will connected with root account. Othewise, you can use insted of `$USER:$GROUP` different account or group like this,
>`root:root` or your account:group, similar to mine `zerekis:zerekis`


## Creating Services and Scripts

## Creating backup directory
```
sudo mkdir -p /var/backups
sudo chown root:root /var/backups
sudo chmod 755 /var/backups
```
> Note:
> `/var` should be restricted for users. Only Administrator privileges should have an access to this. Thats why I will assign system account privileges to it.

## Creating Reserved copy
Reserved copy will be created when service `mount-ramdisk.service` stops . 

Create file `save_ramdisk.sh` and insert next block of code:
`sudo nano /usr/local/bin/save_ramdisk.sh`


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
`sudo chmod +x /usr/local/bin/save_ramdisk.sh`


### Restore Data '/usr/local/bin/restore_ramdisk.sh`
Use this command to create file:
`sudo nano /usr/local/bin/restore_ramdisk.sh`

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

### Make sctipt executable

`sudo chmod +x /usr/local/bin/restore_ramdisk.sh`

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
ExecStartPre=/bin/bash -c 'mountpoint -q /mnt/ramdisk && umount /mnt/ramdisk || :'
ExecStart=/sbin/mkfs.ext4 -q /dev/ram0
ExecStartPost=/bin/mount /dev/ram0 /mnt/ramdisk
ExecStartPost=/bin/chown -R zerekis:zerekis /mnt/ramdisk
ExecStartPost=/bin/chmod -R 700 /mnt/ramdisk
ExecStop=/bin/bash -c 'tar -czf /var/backups/ramdisk-backup.tar.gz -C /mnt/ramdisk . && umount /mnt/ramdisk'
ExecStopPost=/sbin/rmmod brd

[Install]
WantedBy=multi-user.target
```


### Applying and testing
#### Activating Services
```
sudo systemctl daemon-reload
sudo systemctl enable mount-ramdisk.service
```

#### Checking backup

`ls -l /var/backups/ramdisk-backup.tar.gz`

#### Restarting RAM-drive and checking restored backup
```
sudo systemctl start mount-ramdisk.service
sudo ls -l /mnt/ramdisk
sudo systemctl status mount-ramdisk.service
```