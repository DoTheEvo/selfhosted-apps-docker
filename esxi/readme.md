# Esxi
###### guide-by-example

# Purpose

Type 1 hypervisor hosting virtual machines, running straight on metal.

# Basic settings

https://www.dbappweb.com/2020/08/20/how-to-change-the-default-gateway-for-vmware-vsphere-esxi/

* esxcfg-route
* esxcfg-route 10.65.26.25

https://blog.techygeekshome.info/2021/04/vmware-esxi-esxcli-commands-to-update-host-dns-servers/

* esxcli network ip dns server add --server=8.8.8.8
* esxcli network ip dns server remove --server=1.1.1.1
* esxcli network ip dns server list

# Backups using ghettoVCB

* [github](https://github.com/lamw/ghettoVCB)
* [documentation](https://communities.vmware.com/t5/VI-VMware-ESX-3-5-Documents/ghettoVCB-sh-Free-alternative-for-backing-up-VM-s-for-ESX-i-3-5/ta-p/2773570)

The script makes snapshot of a VM, copies the "old" vmdk and other files
to a backup location, then deletes the snapshot.<br>
The space use of this approach where every version takes up lot of space
can be an issue, maybe solved by backup datastore having deduplication,
but thats maybe for the future.

VMs that have any existing snapshot wont get backed up.

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
  Make copy of it `cp /opt/ghettovcb/ghettoVCB.conf /opt/ghettovcb/ghetto_1.conf`<br>
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


Logs about backups are in `/tmp`

# disk reclamation


# Switching from Thick to Thin disks


vmkfstools --punchzero "./TrueNAS_scale-thin.vmdk"

unmap, windows, `fsck_ufs -Ey /dev/da0p3`

# links

* https://www.altaro.com/vmware/ghettovcb-back-up-vms/
* https://www.youtube.com/watch?v=ySMitWnNxp4
* https://forums.unraid.net/topic/30507-guide-scheduled-backup-your-esxi-vms-to-unraid-with-ghettovcb/
* https://blog.kingj.net/2016/07/03/how-to/backing-up-vmware-esxi-vms-with-ghettovcb/

#### email 
