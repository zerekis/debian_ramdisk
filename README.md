
# RamDisk for Debian 12 

In this Tutorial we shall create a RamDisk using brd.ko on Debian 12.


## Structure

What should be in the end:
*RAM-drive: `/mnt/ramdisk`
*Module: 'brd.ko' (1G, autostart after loading system)
*Reserve copy: '/var/backups/ramdisk-backup.tar.gz'

## Services
  *'mount-ramdisk.service' - creating and mounting RAM-drive
  *'save-ramdisk.service' - restore data from backup.

## Script
`/usr/local/bin/restore_ramdisk.sh`
## Installation

```echo "brd rd_nr=1 rd_size=1048576" | sudo tee /etc/modprobe.d/brd.conf```

*`rd_nr=1` - RAM-drive quantity
*`rd_size=1048576` - Drive size

### Update `initramfs` to apply configuration:
`sudo update-initramfs -u`

### Check module for loading up
`sudo modprobe brd`
`ls/dev/ram*`


### Creating Services and Scripts
Service for mounting RAM-drive: `/etc/systemd/system/mount-ramdisk.service`

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

### Script to restore data from backup `/usr/local/bin/restore_ramdisk.sh`

`sudo nano /usr/local/bin/restore_ramdisk.sh`

*Type next block code inside

```
#!/bin/bash
if [ -f /var/backups/ramdisk-backup.tar.gz ]; then
    tar -xzf /var/backups/ramdisk-backup.tar.gz -C /mnt/ramdisk
fi
```

### Make sctipt executable

`sudo chmod +x /usr/local/bin/restore_ramdisk.sh`


### Service to restore data from backup

`sudo nano /etc/systemd/system/save-ramdisk.service`
*Type next code
```
[Unit]
Description=Restore RAM Disk Data
After=mount-ramdisk.service
Requires=mount-ramdisk.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/restore_ramdisk.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
```

### Creating Reserve copy
Reserve copy will be created when service stop `mount-ramdisk.service`. It was mentioned in block `Creating Services and Scripts`

### Checking and debugging
#### Activating Services
```
sudo systemctl daemon-reload
sudo systemctl enable mount-ramdisk.service
sudo systemctl enable save-ramdisk.service
```

*Launching RAM-drive
`sudo systemctl start mount-ramdisk.service`

#### Checking Restoring data from backup
```
sudo systemctl start save-ramdisk.service
sudo ls -l /mnt/ramdisk
```

#### Stop RAM-drive and create backup
`sudo systemctl stop mount-ramdisk.service`

#### Checking backup

`ls -l /var/backups/ramdisk-backup.tar.gz`

#### Restarting RAM-drive and checking restored backup
```
sudo systemctl start mount-ramdisk.service
sudo systemctl start save-ramdisk.service
sudo ls -l /mnt/ramdisk
```
