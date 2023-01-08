# TrueNAS SCALE

###### guide-by-example

![logo](https://i.imgur.com/9ocPlzl.png)

# Purpose & Overview

Network storage operating system managed through web GUI.<br>

* [Official site](https://www.truenas.com/truenas-scale/)
* [Forums](https://www.truenas.com/community/forums/truenas-scale-discussion/)

Based on debian linux with ZFS file system is at the core.
Running nginx and using python and django for the web interface.

**note** - There are links to the official documentation in subsections,
its of decent quality, with pictures and videos and it should be up-to-date.

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

<details>
<summary><h1>Installation as a VM in VMware ESXi</h1></summary>

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
* ESXi - edit VM, add other device, PCI device,
  should be listed HBA card thats passthrough
  so that truenas has direct disks access

</details>

---
---

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

* `timedatectl` - general time info
* `sudo ntpq -p` - lists configured ntp servers, the symbols in the first column
 `+, -, *` [note the use](https://web.archive.org/web/20230102105411/https://detailed.wordpress.com/2017/10/22/understanding-ntpq-output/)
* `sudo ntpq -c sysinfo` - operational summary
* `sudo ntpd -g -x -q pool.ntp.org` - force sync to a pool
* `sudo sntp pool.ntp.org` - force sync to a pool
* `systemctl status ntp.service` - check service status
* `sudo journalctl -u ntp.service` - check journal info of the service
* `sudo systemctl restart ntp.service` - restart the service
* `cat /etc/ntp.conf` - check the config 
* `sudo hwclock --systohc --utc` - set utc time to rtc clock, hardware clock runnin in bios

![timedatectl](https://i.imgur.com/aIMm7WT.png)

I faced an issue of time being out of sync after restarts and ntpq command
failing to connect. What I think did the trick was force sync time through dashboard,
or through cli commands, then restart the ntp service.
Then set the UTC time in bios using `hwclock --systohc --utc`

### Pools and Datasets

![zfs-layout](https://i.imgur.com/uQXaw3h.png)

### Pool

[The official documentation.](https://www.truenas.com/docs/core/coretutorials/storage/pools/poolcreate/)

Pool is like a virtual unformated hard drive. Can't be mounted,
cant be used without *"partitioning"* it first.
But it is at the creation of pool where "raid" is set.

* start creating a pool<br>
  Storage > Create Pool button<br>
  name it; I prefer to not encrypt, that comes with datasets
* assign physical disks to the pool's default VDev,
  if needed, more VDevs can be added<br>
  select "raid" type for the VDev - stripe, mirror
* Create

For destruction of a pool - Storage > Export/Disconnect button

### Dataset

[The official documentation.](https://www.truenas.com/docs/core/coretutorials/storage/pools/datasets/)

`Dataset` is like a partition in the classical terms. It's where filesystem
actually comes to play, with all the good stuff like mount, access, quotas,
compression, snapshots,...

* start creating a dataset<br>
  Datasets > Add Dataset button<br>
  name it; I prefer to turn off compression
* set encryption to passphrase if desired<br>
  this encryption prevents access to the data after shutdown,
  nothing to do with sharing
* set Case sensitivity to `Insensitive` if windows will be accessing this dataset
* set Share Type to `SMB` if planning to share with SMB, which is the most used
  way to share, especially for windows or mixed access

### Zvol

`Zvol` is a direct alternative to dataset.<br>
When planning to use iScsi with its approach of mounting network storage
as a block device.
This provides great speeds with small files, but at the cost of space.

<details>
<summary><h1>SMB share</h1></summary>

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

### SMB share for everyone

One might think that just allowing group `everyone@` access is enough.
But when someone connects to a share, there must be a username used.
For this a guest account needs to be enabled,
which under the hood is named `nobody`

* in Shares > Windows (SMB) Shares > edit the share
* Advanced Options > Allow Guest Access

### Mounting network share at boot

Using systemd. And the instructions from [arch wiki.](https://wiki.archlinux.org/title/samba#As_systemd_unit)

I prefer setting permissions in the unit

check your user `id $whoami` for uid and gid

`/etc/systemd/system/mnt-bigdisk.mount`
```ini
[Unit]
Description=12TB truenas mount

[Mount]
What=//10.0.19.11/Dataset-01
Where=/mnt/bigdisk
Options=rw,username=bastard,password=lalala,file_mode=0644,dir_mode=0755,uid=1000,gid=1000
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
</details>

---
---

<details>
<summary><h1>NFS share</h1></summary>

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

### Mounting network share at boot

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

</details>

---
---

<details>
<summary><h1>iSCSI share</h1></summary>

[The official documentation.](https://www.truenas.com/docs/scale/scaletutorials/shares/iscsi/addingiscsishares/)

Sharing disk space as a block device over network. 
Great perfromance, especially if lot of I/O small files stuff.
Only single client can work with the block device at once.

* **target** - a storage we want to make available over network
* **initiator** - a device connecting to a target
* **portal** - they say IP and port pair, but part of it is also authentication
* 

both target and initiator must be assigned IQN - iSCSI Qualified Name<br>
name format: iqn.yyyy-mm.naming-authority:unique name<br>
examples:<br>
`iqn.2016-04.com.open-iscsi:4ab2905b66ca`<br>
`iqn.2005-10.org.freenas.ctl:garbage`<br>
`iqn.1991-05.com.microsoft:tester-81`<br>


assuming all sections (portals, Initators groups, Authgorized access, targets, extents,..) are empty and doing it first time

* create a new Zvol<br>
  Datasets > Add Zvol button<br>
  set Name; set Size, they recommend less than 80% of the pool but can be forced higher;

* click through iSCSI share wizzard or do the manual setup<br>
  Shares > Block (iSCSI) Shares Targets > ...<br>

Manual setup

* Target Global Configuration<br>
  nothing really worth changing
* Portals<br>
  add some description and set IP of the truenas<br>
* Initiator<br>
  add some description and for now check Allow All Initiators
* Authorized Access<br>
  skip
* Targets<br>
  set name; set portal group; set initiator group; authentication kept none
* Extents<br>
  set name; device=some zvol; Logical Block Size=4096
* Associated Targets <br>
  set target; LUN ID=0; set extent

Enable iSCSI service. 

To test if it works.<br>
On windows just launching `iscsicpl.exe` and refreshing, connect, should work.

On arch linux there is a good and detailed [instructions on the wiki.](https://wiki.archlinux.org/title/Open-iSCSI)

* install `open-iscsi`
* start service `sudo systemctl start iscsid.service`<br>
  do not `enable` it just start it to test<br>
  to have it present after boot:
  - `sudo systemctl enable iscsi.service`
  - edit `/etc/iscsi/nodes/../default` and set `node.startup = automatic`
  - apply systemd mount files 
* discover targets at the ip<br>
  `sudo iscsiadm --mode discovery --portal 10.0.19.11 --type sendtargets`<br>
  after this command a new directory is created `/etc/iscsi/nodes/`
* login to all available targets
  `sudo iscsiadm -m node -L all`
* see availabl block devices<br>
  `lsblks`

### Encryption setup using fs

[very well written arch wiki page](https://wiki.archlinux.org/title/Fscrypt)

* format the iscsi disk<br> 
  `sudo mkfs.ext4 -O encrypt /dev/sdb1`<br>
  or enable it with `sudo tune2fs -O encrypt /dev/device`
* mount it lets say `/mnt/target1`
* install fscrypt<br>
  `sudo pacman -S fscrypt`
* enable it on the system `fscrypt setup`
* enable it on the mounted partition `sudo fscrypt setup /mnt/target1`
* create a directory there as you cant encrypt root of a partition
* encrypt the directory `fscrypt encrypt /mnt/target1/homework` 
* lock `fscrypt lock /mnt/target1/homework`
* lock `fscrypt unlock /mnt/target1/homework`

systemd mount files

`/etc/systemd/system/mnt-target1.mount`
```ini
[Unit]
Before=remote-fs.target
After=iscsi.service 
Requires=iscsi.service
Description=iscasi test share

[Mount]
What=/dev/disk/by-uuid/58b83770-2c68-463e-9ea4-6f62ef8c001d
Where=/mnt/target1
Type=ext4
Options=_netdev,noatime

[Install]
WantedBy=multi-user.target
```

`/etc/systemd/system/mnt-bigdisk.automount`
```ini
[Unit]
Description=iscasi test share

[Automount]
Where=/mnt/target1

[Install]
WantedBy=multi-user.target
```

* `/etc/iscsi/nodes` - where targets are added
* `/etc/iscsi/initiatorname.iscsi` - machines id
* `/etc/iscsi/iscsid.conf` - general config


</details>

---
---

### Data protection settings

* enable autoamtic smart short tests<br>
  Data Protection > S.M.A.R.T. Tests > Add > all disks/short/weekly
* enable autoamtic snapshots

# Testing access to ZFS disks on a desktop


# Reinstall and import of pools


# Update


# Backup and restore

