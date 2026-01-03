# Mounting at Boot Network Shares

Many ways to mount - fstab, autofs, systemd, fuse, gvfs,...<br>
but the current go-to is **systemd mount**.

There are two distinct ways to mount with systemd

* **mount** service is enabled<br>
  straight up simple mounting at boot, high expectation that the network share
  is always available during the boot, it's simple and easy to control
  order of execution, retries, time outs, easy to debug,
  best for servers, docker hosts,...
* **automount** service is enabled<br>
  the mounting happens at the first demand to access the path,
  does not wait during boot for the mount to really happen, less predictable,
  can auto-umount on idle, good for users machines


# Samba / SMB / CIFS 

[Arch wiki](https://wiki.archlinux.org/title/samba#As_systemd_unit)
on samba systemd mount

* Have `/mnt/pool` directory ready on the client - `sudo mkdir /mnt/pool`
* will be creating a mount file in `/etc/systemd/system/`<br>
  the name MUST correspond with the planned mount location,
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
* enable the mount service `sudo systemctl enable mnt-pool.mount`
* done

### Automount version

If the machine is just an end user PC or a notebook,
or no service really depends on that share being present straight from boot,
or a notebook moves between networks and share is not always there...
we can use automount that mounts the share only when something tries to access
the path.

* disable mount service if already enabled:
  `sudo systemctl disable mnt-pool.mount`
* we add another file next to  the mount file, named exactly the same,
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
* we enable this automount service:
  `sudo systemctl enable --now mnt-pool.automount`
* done


### Useful commands

`smbclient -L 10.0.19.11` - list shares mounted from the ip<br>
`systemctl list-units -t mount --all` 

# NFS

[Arch wiki](https://wiki.archlinux.org/title/NFS#As_systemd_unit)
on NFS systemd mount

All the stuff regarding mount vs automount from Samba section above applies,
only the content of the systemd unit files changes.

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


Enable the mount service: `sudo systemctl enable --now mnt-pool.mount`<br>
Or for automount `sudo systemctl enable --now mnt-pool.automount`

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
