# TrueNAS SCALE

###### guide-by-example

![logo](https://i.imgur.com/9ocPlzl.png)

# Purpose & Overview

Network storage operating system managed through web GUI.<br>

* [Official site](https://www.truenas.com/truenas-scale/)
* [Forums](https://www.truenas.com/community/forums/truenas-scale-discussion/)

TrueNAS SCALE is based on debian linux. ZFS file system is at the core.
Running nginx and using pythong and django for the web interface.

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

Good alterntive I could have go for is [openmediavault](https://www.openmediavault.org/),
but truenas seems a bigger player. And if I did not luck out with the HBA card,
I would be buying Fujitsu 9211-8i from ebay.

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
* login, shutdown
* ESXi - edit VM, add other device, PCI device, <should be listed HBA card> 

# Basic Setup

### Static IP address

* Network > Interfaces > uncheck DHCP > add Aliases > 
  fill IP/mask, on save it asks for the gateway IP
* set hostname and DNS server in Network > Global Configuration

### Set time

* Set time zone and date format<br>
  System Settings > General > Localization > Settings<br>

If there are issues with the time... enable ssh service, ssh in to the truenas 
check few things

* `timedatectl` 
* `ntpq -p`
* `systemctl status ntp.service`
* `sudo journalctl -u ntp.service`
* `cat /etc/ntp.conf`
* `hwclock --systohc --utc`

![timedatectl](https://i.imgur.com/aIMm7WT.png)

For the issue I faced, I think what did the trick was sync time through dashboard
when I had notice of wrong time for like 4th time.
Then I used set the UTC time in bios using `hwclock --systohc --utc`
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

Should be go-to way to share for most cases.

* Windows (SMB) Shares > Add 
* set path to the dataset to share
* set the name under which it will be shared
* set Purpose if there is a special case
* in advanced settings allow guest access if desired

This created a share, now to deal with the permissions<br>
There are two type of permissions accessible through icons in the share view

* Share ACL - set to allow everyone by default
* Edit Filesystem ACL - where one actually wants to control permissions



### NFS share

### iSCSI share

### Data protection settings

* enable autoamtic smart short tests<br>
  Data Protection > S.M.A.R.T. Tests > Add > all disks/short/weekly
* enable autoamtic snapshots

# Testing access to ZFS disks on a desktop


# Reinstall and import of pools


# Update


# Backup and restore

