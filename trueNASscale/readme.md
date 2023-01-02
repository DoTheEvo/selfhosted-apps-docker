# TrueNAS SCALE

###### guide-by-example

![logo](https://i.imgur.com/9ocPlzl.png)

# Purpose & Overview

Network storage operating system managed through web GUI.<br>

* [Official site](https://www.truenas.com/truenas-scale/)
* [Forums](https://www.truenas.com/community/forums/truenas-scale-discussion/)

Based on debian linux with ZFS file system is at the core.
Running nginx and using python and django for the web interface.

[ZFS for Dummies](https://blog.victormendonca.com/2020/11/03/zfs-for-dummies/)

# My specific use case

My home server runs ESXi.<br>
TrueNAS is one of the virtual machines,
with Fujitsu D3307 [flashed in to IT Mode](https://forums.servethehome.com/index.php?threads/the-versatile-sas3008-chipset-my-vendor-crossflashing-adventures.28297/page-4#post-319106)
and pass-through in to the VM so that truenas has direct access to the disk,
without any in between layer.

I hold strong opinion on backups > raid.<br>
So I make zero use of zfs raid features and use it just as nice web GUI
for samba and nfs sharing.

Good alterntive is [openmediavault](https://www.openmediavault.org/),
but truenas seems a bigger player. And if I would have not lucked out
with the HBA card, I would be buying Fujitsu 9211-8i from ebay.

# Installation

![esxi-vm](https://i.imgur.com/hqatTKG.png)

[The official documentation.](https://www.truenas.com/docs/scale/gettingstarted/install/installingscale/)

* [download ISO](https://www.truenas.com/download-truenas-scale/)
* upload it to ESXi datastore
* create new VM
    * Guest OS family - linux
    * Guest OS version - Debian <latest> 64-bit 
    * give it 2 cpu cores
    * give it 4GB RAM with sub-setting: `Reserve all guest memory (All locked)`
    * give it 50GB disk space
    * mount ISO in to the dvd drive
    * SCSI Controller was left at default - vmware paravirtual
    * switch tab and change boot from bios to uefi
* click through the Installation
* pick admin user and set password
* login, shutdown
* ESXi - edit VM, add other device, PCI device, <should be listed HBA card> 

# Basic Setup

### Static IP address

* turn off dhcp and set static ip and mask<br>
  Network > Interfaces<br>
  uncheck DHCP; Add Aliases, IP address=10.0.19.11; mask=24<br>
  on save it asks for the gateway IP
* set hostname, DNS server and enable netbios discovery<br>
  Network > Global Configuration > Settings<br>
  check `NetBIOS-NS`; set hostname; set dns if it's not

### Set time

* Set time zone and date format<br>
  System Settings > General > Localization > Settings<br>
  Timezone=Europe/Bratislava; Date Format=2 Jan 2023

If there are issues with the time... enable ssh service, ssh in to the truenas 
check few things

* `timedatectl` 
* `ntpq -p`
* `sudo ntpq -c sysinfo`
* `systemctl status ntp.service`
* `sudo journalctl -u ntp.service`
* `cat /etc/ntp.conf`
* `sudo hwclock --systohc --utc`

![timedatectl](https://i.imgur.com/aIMm7WT.png)

For the issue I faced, I think what did the trick was sync time through dashboard
when I had notice of wrong time for like 4th time.
Then I set the UTC time in bios using `hwclock --systohc --utc`
and then I started `sudo systemctl start ntp` which previously was failing,
after that `ntpq -p` worked.

### Pools and Datasets

![zfs-layout](https://i.imgur.com/uQXaw3h.png)


##### First a Pool

[The official documentation.](https://www.truenas.com/docs/core/coretutorials/storage/pools/poolcreate/)

I think of a pool as of a virtual unformated hard rive. You cant mount it,
you cant use it without partitioning it first.

* create a pool in the Storage section, name it, I prefer to not encrypt,
  that comes later with Datasets
* assign disks to the pool's default VDev, if needed more VDevs can be added
* in vdev select "raid" type stripe, mirror,
* finish

##### Second comes Dataset

[The official documentation.](https://www.truenas.com/docs/core/coretutorials/storage/pools/datasets/)

`Dataset` is like a partition in the classical terms. It's where filesystem
actually comes to play, with all the good stuff like mount, access, quotas,
compression, snapshots,...

* create a dataset in Datasets > Add Dataset, name it,
  I prefer to turn off compression
* set encryption to passphrase if desired<br>
  this encryption prevents access to the data after shutdown,
  nothing to do with sharing
* set Case sensitivity to `Insensitive` if windows will be accessing this dataset
* set Share Type to `SMB` if planning to share with SMB, which is the most used
  way to share, especially for windows or mixed access

Theres also a direct alterantive to dataset - `Zvol` when one desires
iScsi and the mounting of a network storage as a block device.
Which provides great speeds with small files, but at the cost of space.

For destruction of datasets - Datasets > select one > delete button right side<br>
For destruction of pools - Storage > Export/Disconnect button

### SMB share

Should be go-to for most cases, as all systems(win, linux, mac, 
android, ios) have mature reliable smb clients.

To see connected users, SSH in and `sudo smbstatus -b`

* Windows (SMB) Shares > Add 
* set path to the dataset to share
* set the name under which it will be shared
* set Purpose if there is a special case
* on save the service will be enabled, if its not already

Now to deal with the permissions<br>
There are two type of permissions accessible through icons in the share view

* Share ACL - set to allow everyone by default
* Edit Filesystem ACL - where one actually wants to control permissions

Create smb user and allow the access to the share

* Credentials > Local Users > Add
* set user name, for example: smb_usr<br>
  note the default UID for very first account added manually being `3000`
* set password
* switch to Shares > Edit Filesystem ACL (shield icon)
* in Edit ACL > Add Item > smb_usr
* set desired permissions

Trying to access the IP of truenas instance with the now set credentials
should allow full access to the share.

Worth noting that it's the UID number that identifies users,
not the username.

#### SMB share for everyone

One might think that just allowing group `everyone@` access is enough.
But when someone connects to a share, there must be a username used.
For this a guest account needs to be enabled,
which under the hood is named `nobody`

* in Shares > Windows (SMB) Shares > edit the share
* Advanced Options > Allow Guest Access

#### Mounting network share at boot

Using systemd. And the instructions from [arch wiki.](https://wiki.archlinux.org/title/samba#As_systemd_unit)

`/etc/systemd/system/mnt-bigdisk.mount`
```ini
[Unit]
Description=12TB truenas mount

[Mount]
What=//10.0.19.11/Dataset-01
Where=/mnt/bigdisk
Options=rw,username=ja,password=qq,file_mode=0644,dir_mode=0755,uid=1000
Type=cifs
TimeoutSec=10

[Install]
WantedBy=multi-user.target
```

`/etc/systemd/system/mnt-bigdisk.automount`
```ini
[Unit]
Description=12TB truenas mount

[Automount]
Where=/mnt/bigdisk

[Install]
WantedBy=multi-user.target
```


### NFS share

Linux to linux file sharing. Simple.

Before creation of nfs share, a linux permission group should be planned to use.<br>
Lets say that a group named `nfs` with gid `1100`

on linux client machine

 - `sudo groupadd -g 1100 nfs` - create the group
 - `sudo gpasswd -a bastard nfs` - add the user in to the group
 - log out, log in, check with `id`

Now on truenas the new group is created and set for the dataset
and NFSv4 share is set.

* create nfs group with guid 1100<br>
  Credentials > Local Groups > Add > GID = 1100; Name = nfs
* create new Dataset<br>
  Datasets > Add Dataset > Name it; keep defaults
* set `nfs` group for this dataset root
  Datasets > Permissions (scroll down, bottom right) > Edit<br>
  Group = nfs; check `Apply Group`; check `Apply permissions recursively`<br>
  Save
* switch NFS to version 4<br>
  Shares > UNIX (NFS) Shares > three dots > Config Service<br>
  check `Enable NFSv4`; check `NFSv3 ownership model for NFSv4`<br>
  Save
* Set nfs share<br>
  Shares > UNIX (NFS) Shares > Add<br>
  pick path to the dataset<br>
  Save


Test mounting on client machine, in my case arch linux machine,
[here](https://wiki.archlinux.org/title/NFS#Client) is wiki on nfs

* check you see the share `showmount -e 10.0.19.11`
* mount the share `sudo mount 10.0.19.11:/mnt/Pool-02/sun/ ~/temp`
* should work can check version using `nfsstat -m` or `rpcinfo -p 10.0.19.11`

#### Mounting network share at boot

Using systemd. And the instructions from [arch wiki.](https://wiki.archlinux.org/title/NFS#As_systemd_unit)

`/etc/systemd/system/mnt-truenas.mount`
```ini
[Unit]
Description=Truenas 6TB in stripe

[Mount]
What=10.0.19.11:/mnt/Pool-02/sun
Where=/mnt/truenas
Options=vers=4
Type=nfs
TimeoutSec=10

[Install]
WantedBy=multi-user.target
```

`/etc/systemd/system/mnt-truenas.automount`
```ini
[Unit]
Description=Truenas 6TB in stripe

[Automount]
Where=/mnt/truenas

[Install]
WantedBy=multi-user.target
```

handy commands

* `lsof ~/temp` - find what uses files when trying to unmount

### iSCSI share

### Data protection settings

* enable autoamtic smart short tests<br>
  Data Protection > S.M.A.R.T. Tests > Add > all disks/short/weekly
* enable autoamtic snapshots

# Testing access to ZFS disks on a desktop


# Reinstall and import of pools


# Update


# Backup and restore

