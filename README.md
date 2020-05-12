# Selfhosted-Apps-Docker

###### guide by example

---

![logo](https://i.imgur.com/u5LH0jI.png)

---

* [caddy_v2](caddy_v2/) - reverse proxy
* [bitwarden_rs](bitwarden_rs/) - password manager
* [bookstack](bookstack/) - notes and documentation
* [borg_backup](borg_backup/) - backup utility
* [ddclient](ddclient/) - automatic DNS update
* [dnsmasq](dnsmasq/) - DNS and DHCP server
* [homer](homer/) - homepage
* [nextcloud](nextcloud/) - file share & sync
* [portainer](portainer/) - docker management
* [prometheus_grafana](prometheus_grafana/) - monitoring
* [watchtower](watchtower/) - automatic docker images update
* [arch_linux_host_install](arch_linux_host_install)

The core of the setup is Caddy reverse proxy.</br>
It's described in most details.

# Some docker basics and some info

You **do not** need to fuck with `docker-compose.yml` to get something up,
simple copy paste should suffice.

You **do need** to fuck with `.env` file, that's where all the variables are.
  
Also sometimes the `.env` file is used as `env_file`

* `.env` - actual name of a file, used only by compose.</br>
  It is used automatically just by being in the directory
  with the `docker-compose.yml`</br>
  Variables set there are only available during the building of the container.
* `env_file` - an option in compose that defines existing external file.</br>
  Variables set in this file will be available in the running container,
  but not in compose.

So to not have polluted huge ass compose file, or to not have multiple places
where changes need to be made when adding a variable...  `env_file: .env` BAM.

Only issue is that all variables are available in all containers in the compose.</br>
That can lead to potential conflicts and clashes, looking at you nextcloud.

In those cases variables names are declared per container.

But `env_file: .env` is just easier, prettier... and mostly painless.

