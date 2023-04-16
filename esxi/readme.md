# Esxi
###### guide-by-example

![logo](https://i.imgur.com/ala26GB.png)

# Purpose

Type 1 hypervisor hosting virtual machines, running straight on metal,
managed through web GUI.

ESXi is made by vmware. It is a commercial product part of vSphere,
but offers free version when one registers on their site.<br>
The free version has limit of max 2 physical cpus, max 8 vCPU per VM, 
and no access to API which prevents ease of making backups of the VMs.
But for backups there is solution of using ghettovcb script.

ESXi is also considered bit picky when it comes to hardware.
Having natively supported network card and disk controller is not given.

![gui-pic](https://i.imgur.com/HkfoCrk.png)

# Basic settings

### Password complexity

* Host > Manage > System > Advanced settings > Password quality control<br>
  `retry=10 min=1,1,1,1,1`

### New user

* Add new user<br>
  Host > Manage > Security & users > Users > Add user<br>
  Set name and password.
* Set permissions for the new user<br>
  Host > Actions > Permissions<br>
  Set the same user as before, pick role

### Interface

* Right top corner > user name
  * Auto-refresh=60
  * Settings, turn off everything - statistics,
    recent only, welcome message, visual effects

### NTP time sync

* Host > Manage > System > Time & date > Edit NTP Settings
  * Use Network Time Protocol (enable NTP client) 
  * Start and stop with host
  * `pool.ntp.org`
  * Host > Manage > Services > search for ntpd > Start

### Hostname and domain

* ssh in
* `esxcli system hostname set --host esxi-2023`
* if domain on network<br>
  `esxcli system hostname set --domain example.local`

### Network

Should just work, but if there is more complex setup,
like if a VM serves as a firewall...<br>
Be sure you ssh in and try to `ping google.com` to see if network and DNS work.

To check and set the default gateway

* `esxcfg-route` 
* `esxcfg-route 10.65.26.25`

To [change DNS server](https://blog.techygeekshome.info/2021/04/vmware-esxi-esxcli-commands-to-update-host-dns-servers/)

* `esxcli network ip dns server list`
* `esxcli network ip dns server add --server=8.8.8.8`
* `esxcli network ip dns server remove --server=1.1.1.1`
* `esxcli network ip dns server list`

To disable ipv6

* `esxcli network ip set --ipv6-enabled=false`

# Logs

[Documentation](https://docs.vmware.com/en/VMware-vSphere/7.0/com.vmware.vsphere.monitoring.doc/GUID-832A2618-6B11-4A28-9672-93296DA931D0.html)

Host > Monitor > Logs

The one worth knowing about

* shell.log - History of shell commands when SSH in
* syslog.log - General info of what's happening on the system.
* vmkernel.log - Activities of esxi and VMs

Will update with some actual use, when I use logs.

Logs from systems in VMs are in >Virtual Machines > Name-of-VM > Monitor > Logs

![logs-pic](https://i.imgur.com/fEz3Igv.png)

# Backups using ghettoVCB

* [github](https://github.com/lamw/ghettoVCB)
* [documentation](https://communities.vmware.com/t5/VI-VMware-ESX-3-5-Documents/ghettoVCB-sh-Free-alternative-for-backing-up-VM-s-for-ESX-i-3-5/ta-p/2773570)

The script makes snapshot of a VM, copies the "old" vmdk and other files
to a backup location, then deletes the snapshot.<br>
This approach, where backup in time is full backup takes up a lot of space.
Some form of deduplication might be a solution.

VMs that have any existing snapshot wont get backed up.

Files that are backed up:

* vmdk - virtual disk file, every virtual disk has a separate file.
  In webgui datastore browser only one vmdk file is seen per disk,
  but on filesystem theres `blabla.vmdk` and `blablka-flat.vmdk`.
  The `flat` one is where the data actually are, the other one is a descriptor
  file.
* nvram - bios settings of a VM
* vmx - virtual machine settings, can be edited

### Backup storage locations

* Local disk datastore
* NFS share<br>
  For nfs share on trueNAS scale
  * Maproot User -> root
  * Maproot Group -> nogroup

Note the exact path from webgui of your datastore for backups.<br>
Looks like this `/vmfs/volumes/6187f7e1-c584077c-d7f6-3c4937073090`

### Install

* ssh in to esxi
* `cd /tmp`
* `esxcli network firewall ruleset set -e true -r httpClient`
* `wget https://github.com/lamw/ghettoVCB/releases/download/2021_10_20/vghetto-ghettoVCB.vib --no-check-certificate`
* `esxcli software vib install -v /tmp/vghetto-ghettoVCB.vib -f`
* check `ls /opt`

### Config and preparation

Gotta know basics how to edit files with ancient `vi`

* Config file template is in `/opt/ghettovcb/ghettoVCB.conf`<br>
  Make copy of it<br>
  `cp /opt/ghettovcb/ghettoVCB.conf /opt/ghettovcb/ghetto_1.conf`<br>
* Only edit this file, for starter setting where to copy backups<br>
  `vi /opt/ghettovcb/ghetto_1.conf`<br>
  `VM_BACKUP_VOLUME=/vmfs/volumes/6187f7e1-c584077c-d7f6-3c4937073090/Backups`
* Create a file that will contain list of VMs to backup<br>
  `touch /opt/ghettovcb/vms_to_backup_list`<br>
  `vi /opt/ghettovcb/vms_to_backup_list`<br>
  ```
  OPNsense
  Arch-Docker-Host
  ```
* Create a shell script that starts ghetto script using this config for listed VMs<br>
  `touch /opt/ghettovcb/bin/ghetto_run.sh`<br>
  `vi /opt/ghettovcb/bin/ghetto_run.sh`<br>
  ```
  #!/bin/sh

  /opt/ghettovcb/bin/ghettoVCB.sh \
      -g /opt/ghettovcb/ghetto_1.conf \
      -f /opt/ghettovcb/vms_to_backup_list \
      &> /dev/null
  ```
  Make the script executable<br>
  `chmod +x /opt/ghettovcb/bin/ghetto_run.sh`
* for my use case where TrueNAS VM cant be snapshoted while running because
  of a passthrough pcie HBA card there needs to be another config
* Make new config copy<br>
  `cp /opt/ghettovcb/ghetto_1.conf /opt/ghettovcb/ghetto_2.conf`
* Edit the config, setting it to shut down VMs before backup.<br>
  `vi /opt/ghettovcb/ghetto_2.conf`<br>
  `POWER_VM_DOWN_BEFORE_BACKUP=1`
* edit the run script, add another execution for specific VM using ghetto_2.conf<br>
  `vi /opt/ghettovcb/bin/ghetto_run.sh`<br>
  ```
  #!/bin/sh

  /opt/ghettovcb/bin/ghettoVCB.sh \
      -g /opt/ghettovcb/ghetto_1.conf \
      -f /opt/ghettovcb/vms_to_backup_list \
      &> /dev/null

  /opt/ghettovcb/bin/ghettoVCB.sh \
      -g /opt/ghettovcb/ghetto_2.conf \
      -m TrueNAS_scale \
      &> /dev/null
  ```

### Execution and scheduled runs

To simply execute:

* `/opt/ghettovcb/bin/ghetto_run.sh`


To execute it periodicly cron is used.

* Make backup of roots crontab<br>
  `cp /var/spool/cron/crontabs/root /var/spool/cron/crontabs/root.backup`
* Edit roots crontab to execute the run script at 4:00<br>
  add the following line at the end in [cron format](https://crontab.guru/)<br>
  `vi /var/spool/cron/crontabs/root`
  ```
  0    4    *   *   *   /opt/ghettovcb/bin/ghetto_run.sh
  ```
  To save read only file in vi use `:wq!`
* restart cron service<br>
  `kill $(cat /var/run/crond.pid)`<br>
  `crond`

Logs about backups are in `/tmp`

### Restore from backup

[Documentation](https://communities.vmware.com/t5/VI-VMware-ESX-3-5-Documents/Ghetto-Tech-Preview-ghettoVCB-restore-sh-Restoring-VM-s-backed/ta-p/2792996)

* In webgui create a full path where to restore the VM
* The restore-config-template-file is in `/opt/ghettovcb/`<br>
  named `ghettoVCB-restore_vm_restore_configuration_template`
  Make copy of it<br>
  `cp /opt/ghettovcb/ghettoVCB-restore_vm_restore_configuration_template /opt/ghettovcb/vms_to_restore_list`<br>
* Edit this file, adding new line, in which separated by `;` are:
    * path to the backup, the directory with date in name
    * path where to restore this backup
    * disk type - 1=thick | 2=2gbsparse | 3=thin | 4=eagerzeroedthick<br>
    * optional - new name of the VM<br>
  `vi /opt/ghettovcb/vms_to_restore_list`
  ```
  "/vmfs/volumes/6187f7e1-c584077c-d7f6-3c4937073090/Backups/OPNsense/OPNsense-2023-04-16_04-00-00;/vmfs/volumes/6378107d-b71bee00-873d-b42e99f40944/OPNsense_restored;3;OPNsense-restored"
  ```
* Execute the restore script with the config given as a parameter.<br>
  `opt/ghettovcb/bin/ghettoVCB-restore.sh -c /opt/ghettovcb/vms_to_restore_list`
* Register the restored VM.<br>
  If it's in the same location as the original was, it should just go through.
  If the location is different then esxi asks if it was moved or copied.
  * Copied - You are planning to use both VMs at the same time,
    selecting this option generates new UUID for the VM, new MAC address,
    maybe some other hardware identifiers as well.
  * Moved - All old settings are kept, for restoring backups this is usually
    the correct choice.

# Switching from Thick to Thin disks

Kinda issue is that vmdk are actually two files.<br>
Small plain `.vmdk` that holds some info, and the `flat.vmdk` with actual
gigabytes of data of the disk. In webgui this fact is hidden.

* have backups
* down the VM
* unregister the VM
* ssh in
* navigate to where its vmdk files are in datastore<br>
  `cd /vmfs/volumes/6187f7e1-c584077c-d7f6-3c4937073090/linux/`
* execute command that converts the vmdk
  `vmkfstools -i "./linux.vmdk" -d thin "./linux-thin.vmdk"`
* zeropunch the image file, so that unused blocks are properly zeroed.<br>
  `vmkfstools --punchzero "./linux-thin.vmdk"`
* remove or move both original files<br>
  `rm linux.vmdk`<br>
  `rm linux-flat.vmdk`
* In webgui navigate to the datastore.
  Use `move` command to rename thin version to the original name.<br>
  This changes the values in `linux.vmdk` to point to correct `flat.vmdk`
* register the VM back to esxi gui.

# Disk space reclamation

If you run VMs with thin disks, the idea is that it uses only as much space
as is needed. But if you copy 50GB file to a VM, then deletes it, it's not always
seamless that the VMDK shrinks by 50GB too.

Correctly functioning reclamation can save time and space for backups.

* Modern windows should just work, did just one test with win10.
* linux machines need fstrim run that marks blocks as empty.
* Unix machine, like opnsense based on FreeBSD needed to be started from ISO,
  so that partition is not mounted and executed<br> 
  `fsck_ufs -Ey /dev/da0p3`<br>
  afterwards it needed one more run of vmkfstools --punchzero "./OPNsense.vmdk"<br>
  And it still uses roughly twice as much space as it should.

# links

* https://www.altaro.com/vmware/ghettovcb-back-up-vms/
* https://www.youtube.com/watch?v=ySMitWnNxp4
* https://forums.unraid.net/topic/30507-guide-scheduled-backup-your-esxi-vms-to-unraid-with-ghettovcb/
* https://blog.kingj.net/2016/07/03/how-to/backing-up-vmware-esxi-vms-with-ghettovcb/
* https://sudonull.com/post/95754-Backing-up-ESXi-virtual-machines-with-ghettoVCB-scripts#esxi-3
