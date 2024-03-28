# Mounting Network Shares in Linux

possible ways to mount stuff - fstab, autofs, systemd, docker volumes if its for docker

possible types of shares

* smb/samba/cifs - the most common share, support on all OS
* nfs - mostly used between linux machines, bit better performance
* iSCSI - the share is mounted as a block device as if it was really a disk,
  great performance for small files

More on setup of these shares is in
[TrueNAS Scale guide.](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/trueNASscale)

# smb/samba/cifs 

[Arch wiki](https://wiki.archlinux.org/title/samba#As_systemd_unit)
on samba systemd mount

* you will create two files in `/etc/systemd/system`
* one will have extension `.mount` the other `.automount` 
* the name will be the same for both and it MUST correspond with the planned
  mount path. Slashes `/` being replaced by dashes `-`.<br>
  So if the share should be at `/mnt/mirror` the files are named 
  `mnt-mirror.mount` and `mnt-mirror.automount`
* copy paste the bellow content, edit as you see fit,
  changing description, ip address and path, user and password,..
* linux command `id` will show your current user `uid` and `gid`
* after ther changes execute command `sudo systemctl enable mnt-mirror.automount`
  This will setup mounting that does not fail on boot if there are network issues,
  and really mounts the target only on request

`mnt-mirror.mount`
```ini
[Unit]
Description=3TB truenas mirror mount

[Mount]
What=//10.0.19.11/Mirror
Where=/mnt/mirror
Type=cifs
Options=rw,username=kopia,password=aaa,file_mode=0644,dir_mode=0755,uid=1000,gid=1000

[Install]
WantedBy=multi-user.target
```

`mnt-mirror.automount`
```ini
[Unit]
Description=3TB truenas mirror mount

[Automount]
Where=/mnt/mirror

[Install]
WantedBy=multi-user.target
```

### Useful commants

`smbclient -L 10.0.19.11` - list shares mounted from the ip
`systemctl list-units -t mount --all` 
