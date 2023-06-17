# raspberry pi setup using Arch linux ARM

![logo](https://i.imgur.com/N0Y4vco.png)

Tested on RPi3

# Get Arch on it 

* **download** pre-prepared **image**, aarch64, if not terribly out of date<br>
  [https://github.com/andrewboring/alarm-images/releases](https://github.com/andrewboring/alarm-images/releases)
* **flash** the image to to an sd card using [etcher](https://etcher.balena.io/#download-etcher) 
* **boot** the rpi with it, login root//root

Or follow [the official instructions.](https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-3)
With manual partitioning, and extracting and moving but everything is latest.

# Get Arch in to working state

* check space used and assigned `df -h` and `lsblk`<br>
  if root partition is too small
  * `cfdisk /dev/mmcblk0` or whatever is your drive path,
    and resize the partition, write changes
  * `resize2fs /dev/mmcblk0p2` or whatever is the path to the partition
* since the image can be older update might not be just `pacman -Syu`
  * update keyring `pacman -Sy archlinux-keyring`, `pacman -Sy archlinuxarm-keyring`<br>
  if it refuses - `pacman-key --init`; `pacman-key --populate`<br>
  Can take some time.
* update the system `pacman -Syu` 
* create a new user and set the password
  * `useradd -m -G wheel bastard`<br>
  * `passwd bastard`
  * edit sudoers to allow users of the group wheel to sudo<br>
    `EDITOR=nano visudo`<br>
    `%wheel ALL=(ALL) ALL`
* install sudo `pacman -S sudo` 
* try login as the new user

# Run prepared ansible

[This ansibe playbooks repo](https://github.com/DoTheEvo/ansible-arch)
setup some stuff for arch.<br>
But for arm based stuff it needs some adjustment.

#### Locale

Ansible needs utf8 [locale](https://wiki.archlinux.org/title/locale) set.

  * run `locale`, if its already UTF-8 then we are done here
  * `sudo nano /etc/locale.gen`<br>
    `en_US.UTF-8 UTF-8` uncomment
  * `locale-gen` - generates locale
  * `localectl set-locale LANG=en_US.UTF-8` - sets locale
  * logout, login, check `locale` again

#### YAY and Reflect


`playbook_core.yml` installs lot of basic packages. It works for most,
except for `yay` and `reflector` as they throw an error
cuz of ARM archiceture.

So before running `playbook_core.yml` or after experiencing any error,
just edit the `playbook_core.yml` and delete the responsible section, and run again.

`playbook_zsh.yml` and `playbook_docker.yml` worked without any issues.

After its done uninstall ansible stuff - `sudo pacman -Rns ansible`

The raspberry is now ready.

![neofetch](https://i.imgur.com/Eha3bOX.png)
