# Arch Linux installation to serve as a docker host

###### guide by example

![logo](https://i.imgur.com/SkENpGn.png)

# Purpose

Linux that will run docker.

This is not a very hand holding guide.</br>
Google for plenty of tutorials and youtube videos alongside arch wiki.

* [Official site](https://www.archlinux.org/)
* [Arch wiki install guide](https://wiki.archlinux.org/index.php/installation_guide)
* [Arch wiki docker entry](https://wiki.archlinux.org/index.php/docker)

# Files and directory structure

```
/home/
└── bastard/
    └── docker/
        ├── container-setup #1
        ├── container-setup #2
        ├── ...
```

# Make installation usb

* [wiki](https://wiki.archlinux.org/index.php/USB_flash_installation_media)

`sudo dd bs=4M if=archlinux-2020.05.01-x86_64.iso of=/dev/sdX status=progress oflag=direct`

The above command will fuck your machine up if you dunno what you are doing.

# Boot from the usb

This is BIOS/MBR setup as I am running on an old thinkpad with a busted screen,
plus I like the simplicity of it.</br>
So if theres boot menu option choose non-uefi.

# Installation 

* create a single partition and mark it bootable</br>
  `cfdisk /dev/sda`
* build ext4 filesystem on it</br>
  `mkfs.ext4 /dev/sda1`
* mount the new partition</br>
  `mount /dev/sda1 /mnt`
* choose geographicly close mirror, ctrl+k deletes a line in nano</br>
  `nano /etc/pacman.d/mirrorlist` 
* install the base system </br>
  `pacstrap /mnt base linux linux-firmware base-devel grub dhcpcd nano`
* gnerate fstab</br>
  `genfstab -U /mnt > /mnt/etc/fstab`
* chroot in to the new system</br>
  `arch-chroot /mnt`
* install grub</br>
  `grub-install /dev/sda`</br>
  `grub-mkconfig -o /boot/grub/grub.cfg`
* remove the bootable media and restart the machine</br>
  `exit`</br>
  `reboot`

# Basic configuration after the first boot

* login as `root`</br>
* set password for root</br>
  `passwd`
* set hostname</br>
  `echo docker-host > /etc/hostname`
* add new user and set their password</br>
  `useradd -m -G wheel bastard`</br>
  `passwd bastard`
* edit sudoers to allow users group wheel to sudo</br>
  `EDITOR=nano visudo`</br>
  *%wheel ALL=(ALL) ALL*
* check the network interface name</br>
  `ip link`
* enable aquiring dynamic IP</br>
  `systemctl enable --now dhcpcd@enp0s25`
* uncomment desidred locales in locale.gen</br>
  `nano /etc/locale.gen`</br>
* generate new locales and set one system wide</br>
  `locale-gen`</br>
  `localectl set-locale LANG=en_US.UTF-8`
* select timezone and set it permanent</br>
  `tzselect`</br>
  `timedatectl set-timezone 'Europe/Bratislava'`
* set hardware clock and sync using ntp</br>
  `hwclock --systohc --utc`</br>
  `timedatectl set-ntp true`
* setup a swap file</br>
  `fallocate -l 8G /swapfile`</br>
  `chmod 600 /swapfile`</br>
  `mkswap /swapfile`</br>
  `nano /etc/fstab`</br>
  */swapfile none swap defaults 0 0*
* enable colors in pacman.conf</br>
  `nano /etc/pacman.conf`</br>
  *Color*
* reboot</br>
  `reboot`

# SSH, ZSH, Docker, and other goodies

From now on its login as non-root user.

### Setup SSH access

* install openssh package</br>
  `sudo pacman -S openssh`
* edit sshd_config</br>
  `sudo nano /etc/ssh/sshd_config`</br>
  *PermitRootLogin prohibit-password*</br>
  *PasswordAuthentication yes*
* enable sshd service</br>
  `sudo systemctl enable --now sshd`

### ZSH shell

I like [Zim](https://github.com/zimfw/zimfw),
it's the fastest zsh framework and out of the box setup nicely

* install zsh package</br>
  `sudo pacman -S zsh`
* install zim, it changes users default shell to zsh</br>
  `curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh`

### Setup docker

* have `docker` and `docker-compose` packages installed</br>
  `sudo pacman -S docker docker-compose`
* enable docker service</br>
  `sudo systemctl enable --now docker`
* add non-root user to the docker group</br>
  `sudo gpasswd -a bastard docker`


### Extra stuff

* `sudo pacman -S vim git cronie curl borg htop lm_sensors nnn bind-tools python-llfuse`
* install yay for access to AUR packages</br>
  `git clone https://aur.archlinux.org/yay-bin.git`</br>
  `cd yay-bin && makepkg -si`</br>
  `cd .. && rm -rf yay-bin`</br>

`ctop` and `inxi` are good packages from yay

### Adding stuff to .zshrc

* `export EDITOR=vim`
* for ctrl+f prepending sudo
  ```bash
  add_sudo (){
      BUFFER="sudo $BUFFER"
      zle -w end-of-line
  }
  zle -N add_sudo
  bindkey "^f" add_sudo
  ```
