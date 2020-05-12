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
* [portainer](portainer/) - docker managment
* [prometheus_grafana](prometheus_grafana/) - monitoring
* [watchtower](watchtower/) - automatic docker images update
* [arch_linux_host_install](arch_linux_host_install)

The core of the setup is Caddy reverse proxy.</br>
It's described in most details.

# Some docker bacics and some info

You **do not** need to fuck with `docker-compose.yml` to get something up,
simple copy paste should suffice.

You **do need** to fuck with `.env` file, that's where all your variables are.
  
Also sometimes the `.env` file is used as `env_file`

* `.env` - name of the file used only by compose.</br>
  It is used automaticly just by being in the directory
  with the `docker-compose.yml`</br>
  Variables set there are only available during the building of the container.
* `env_file` - an option in compose that defines existing external file.</br>
  Variables set in this file will be available in the running container,
  but not in compose.

So to not have polluted huge ass compose file, or to not have multiple places
where changes need to be made...  `env_file: .env` BAM.

Only issue is that all variables are avaialble in all containers.</br>
So that can lead to potential conflicts and clashes, looking at you nextcloud.

In those cases variables names to be used are declared per container.

But it is just so much easier, pretier to `env_file: .env`, and mostly painless.

