# TrueNAS SCALE

###### guide-by-example

![logo](https://i.imgur.com/9ocPlzl.png)

# Purpose & Overview

Network storage operating system managed through web GUI.<br>

* [Official site](https://www.truenas.com/truenas-scale/)
* [Forums](https://www.truenas.com/community/forums/truenas-scale-discussion/)

TrueNAS SCALE is based on debian linux. ZFS file system is at the core.
Running nginx and using pythong and django for the web interface.

# My specific use case

My home server runs Esxi.<br>
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

![logo](https://i.imgur.com/hqatTKG.png)

[official documentation](https://www.truenas.com/docs/scale/gettingstarted/install/installingscale/)

* [download ISO](https://www.truenas.com/download-truenas-scale/)
* upload it to esxi datastore
* create new VM
    * Guest OS family - linux
    * Guest OS version - Debian <latest> 64-bit 
    * give it 2 cpu cores
    * give it 4GB RAM
    * give it 50GB disk space
    * mount ISO in to the dvd drive
    * SCSI Controller was left at default - vmware paravirtual
    * switch tab and change boot from bios to uefi
* click through the Installation
* login, shutdown
* Esxi - edit VM, add other device, PCI device, <should be listed HBA card> 

# Basic Setup

### First login


### Static IP address

### Pool and datasets

### SMB share

### NFS share

# Testing access to ZFS disks on a desktop


# Reinstall and import of pools


# Update


# Backup and restore

