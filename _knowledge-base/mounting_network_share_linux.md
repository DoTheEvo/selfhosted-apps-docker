# Mounting at Boot Network Shares

Many ways to mount - fstab, autofs, systemd, fuse, gvfs,...<br>
but the current go-to is **systemd mount**.

There are two distinct ways to mount with systemd

* **mount** unit is enabled<br>
  straight up simple mounting at boot, high expectation that the network share
  is always available during the boot, it's simple and easy to control
  order of execution, time outs, easy to debug,
  best for servers, docker hosts,...
* **automount** unit is enabled<br>
  the mounting happens at the first demand to access the path,
  does not wait during boot for the mount to really happen, less predictable,
  can auto-unmount on idle, good for users machines


# Samba / SMB / CIFS 

[Arch wiki](https://wiki.archlinux.org/title/samba#As_systemd_unit)
on samba systemd mount

* **install samba** support package, on most distros it's `cifs-utils`
* **test** if you can access the share,<br>
  visit the IP of the NAS in your file explorer `smb://10.0.19.80`
* Have the **mount path ready** on the client - `sudo mkdir /mnt/pool`
* will be creating a **mount file** in `/etc/systemd/system/`<br>
  the name MUST correspond with the planned mount location,<br>
  just slashes `/` are replaced with dashes `-`<br>
  So if the share should be mounted at `/mnt/pool` the file is:<br>
 `/etc/systemd/system/mnt-pool.mount`
  ```ini
  [Unit]
  Description=Mount MergerFS Pool or Whatever
  After=network-online.target
  Wants=network-online.target
  # Before=docker.service

  [Mount]
  What=//10.0.19.80/pool
  Where=/mnt/pool
  Type=cifs
  Options=rw,username=bastard,password=aaa,uid=1000,gid=1000,file_mode=0664,dir_mode=0775,vers=3,_netdev

  [Install]
  WantedBy=multi-user.target
  ```
* **enable the mount unit** `sudo systemctl enable mnt-pool.mount`
* done

### Automount version

If the machine is just an end user PC or a notebook that moves between networks
and share is not always there...  we can use automount that mounts the share
only when something tries to access the path.

* **disable the mount unit** if already enabled:
  `sudo systemctl disable mnt-pool.mount`
* **add another file** next to the mount file, named exactly the same,
  except the extension is `automount`, so here it would be:<br>
 `/etc/systemd/system/mnt-pool.automount`
  ```ini
  [Unit]
  Description=Mount MergerFS Pool or Whatever

  [Automount]
  Where=/mnt/pool
  # TimeoutIdleSec=3600  # Unmount after 1 hour idle

  [Install]
  WantedBy=multi-user.target
  ```
* we **enable the automount unit**:
  `sudo systemctl enable --now mnt-pool.automount`
* done


### Useful commands

`smbclient -L 10.0.19.11` - list shares mounted from the ip<br>
`systemctl list-units -t mount --all`  - list all mount unit 

# NFS

[Arch wiki](https://wiki.archlinux.org/title/NFS#As_systemd_unit)
on NFS systemd mount

All the stuff regarding mount vs automount from Samba section above applies.<br>
You need to **install nfs support package**,
it's `nfs-utils` or `nfs-common` or `nfs-client` depending on the distro.


`/etc/systemd/system/mnt-pool.mount`
```
[Unit]
Description=Mount MergerFS Pool or Whatever
After=network-online.target
Wants=network-online.target

[Mount]
What=10.0.19.80:/mnt/pool
Where=/mnt/pool
Type=nfs
Options=vers=3

[Install]
WantedBy=multi-user.target
```

`/etc/systemd/system/mnt-pool.automount`
```
[Unit]
Description=AutoMount MergerFS Pool or Whatever
Requires=network-online.target
After=network-online.target

[Automount]
Where=/mnt/pool
TimeoutIdleSec=0

[Install]
WantedBy=multi-user.target
```


Enable the mount: `sudo systemctl enable --now mnt-pool.mount`<br>
Or for automount `sudo systemctl enable --now mnt-pool.automount`


# iSCSI

[Arch wiki](https://wiki.archlinux.org/title/Open-iSCSI)
detailed instructions.

* **install** `open-iscsi` and enable two services<br>
  `sudo systemctl enable --now iscsid` - daemon managing iscsi sessions <br> 
  `sudo systemctl enable --now iscsi` - provides automatic login to targets 
* to **discover** available targets at an IP,
  run `sudo iscsiadm -m discovery -t sendtargets -p 10.0.19.80`<br>
  something like *10.0.19.11:3260,1 iqn.2005-10.org.freenas.ctl:test_2*
  should be an answer, it also creates a node entry in /var/lib/iscsi/...
* **login** to all discovered iscsi targets - `sudo iscsiadm -m node --login`<br>
  * to list current sessions - `sudo iscsiadm -m session` 
* **autologin at boot** to all discovered targets:
  `sudo iscsiadm -m node --op update -n node.startup -v automatic`
  * verify: `sudo iscsiadm -m node -o show | grep node.startup`
* **format** the iscsi drive
  * `lsblk` - to see new block devices and
    `sudo iscsiadm -m session -P 3` to confirm that sdx is really
    the block device we want to work with
  * format the sdx directly, no need for sdx1 partitioning
    if all the space is used.
    It makes lsblk output cleaner, where iscsi devices easily recognizable.
  * `sudo mkfs.ext4 /dev/sdx -L test_2`
* **mount** the share somewhere and **take ownership**
  * `sudo mkdir /mnt/test_2`
  * `sudo mount /dev/sdx /mnt/test_2`
  * `sudo chown $USER:$USER /mnt/test_2`
  * test stuff, all should work
* for **automatic mount** on boot systemd mount will be used,
  typical mount unit file and automount file.
  * get the uuid - `lsblk -f`
  * `/etc/systemd/system/mnt-test_2.mount`
    ```
    [Unit]
    Description=Truenas 6TB in stripe
    After=iscsi.service
    Requires=iscsi.service

    [Mount]
    What=/dev/disk/by-uuid/5a16cc72-b251-4eb9-9ea7-af2984df01b4
    Where=/mnt/test_2
    Type=ext4
    Options=_netdev,noatime

    [Install]
    WantedBy=multi-user.target

    ```
  * `/etc/systemd/system/mnt-test_2.automount`
    ```
    [Unit]
    Description=Truenas 6TB in stripe

    [Automount]
    Where=/mnt/test_2
    # TimeoutIdleSec=3600  # Unmount after 1 hour idle

    [Install]
    WantedBy=multi-user.target
    ```
  * enable either mount or automount, depending on preference,
    as explained at the top<br>
    `sudo systemctl enable --now mnt-test_2.mount`<br>
    `sudo systemctl enable --now mnt-test_2.automount`

Of note is change of nodes location from /etc/iscsi to /var/lib/iscsi for nodes.

# Windows Client

### Samba - windows

just mount it or map it as a letter

### NFS - windows

For Windows NFS clients, write access often requires `all_squash`
with a defined anonuid/anongid, because Windows does not send linux uid/gid
information. Something like this:<br>
`/mnt/pool 10.0.19.0/24(rw,async,no_subtree_check,all_squash,anonuid=1000,anongid=1000,fsid=1)`

**Windows Client**

* must be windows pro, not windows home
* add windows component in the control panel - `Services for NFS` - `Client for NFS`
* cmd, not powershell - `mount \\10.0.19.80\mnt\pool N:`

### iSCSI - windows

...
