# Selfhosted-Apps-Docker

###### guide-by-example

---

![logo](https://i.imgur.com/u5LH0jI.png)

---

* [caddy_v2](caddy_v2/) - reverse proxy
* [bitwarden_rs](bitwarden_rs/) - password manager
* [bookstack](bookstack/) - notes and documentation
* [borg_backup](borg_backup/) - backup utility
* [ddclient](ddclient/) - automatic DNS update
* [dnsmasq](dnsmasq/) - DNS and DHCP server
* [gotify / ntfy / signal](gotify-ntfy-signal/) - instant notifications apps
* [homer](homer/) - homepage
* [jellyfin](jellyfin/) - video and music streaming
* [kopia](kopia_backup/) - backup utility replacing borg
* [minecraft](minecraft/) - game server
* [meshcrentral](meshcrentral/) - web based remote desktop, like teamviewer or anydesk
* [rustdesk](rustdesk/) - remote desktop, like teamviewer or anydesk
* [nextcloud](nextcloud/) - file share & sync
* [opnsense](opnsense/) - a firewall, enterprise level 
* [qbittorrent](qbittorrent/) - video and music streaming
* [portainer](portainer/) - docker management
* [prometheus_grafana](prometheus_grafana/) - monitoring
* [unifi](unifi/) - management utility for ubiquiti devices
* [snipeit](snipeit/) - IT inventory management
* [trueNAS scale](trueNASscale/) - network file sharing
* [watchtower](watchtower/) - automatic docker images update
* [wireguard](wireguard/) - the one and only VPN to ever consider
* [zammad](zammad/) - ticketing system
* [arch_linux_host_install](arch_linux_host_install)

Can also just check the directories listed at the top for work in progress

Check also [StarWhiz / docker_deployment_notes](https://github.com/StarWhiz/docker_deployment_notes/blob/master/README.md)<br>
Repo documents self hosted apps in similar format and also uses caddy for reverse proxy

# Core concepts

- `docker-compose.yml` do not need any editing to get started,
   changes are to be done in the `.env` file.
- Not using `ports` directive if theres only web traffic in a container.<br>
  Theres an expectation of running a reverse proxy which makes mapping ports
  on docker host unnecessary. Instead `expose` is used which is basically
  just documentation.<br>
- For persistent storage bind mount `./whatever_data` is used.
  No volumes, nor static path somewhere... just relative path next to compose file.

# Requirements 

**Basic linux and basic docker-compose knowledge.**
The shit here is pretty hand holding and detailed, but it still should not be
your first time running a docker container.

# Some extra info

Kinda the core of the setup is Caddy reverse proxy.</br>
It's described in most details, it's really amazingly simple but robust software.

### Compose

When making changes use `docker-compose down` and `docker-compose up -d`,
not just restart or stop/start.

Often the `.env` file is used as `env_file`,
which can be a bit difficult concept at a first glance.

`env_file: .env`

* `.env` - actual name of a file that is used only by compose.</br>
  It is used automatically just by being in the directory
  with the `docker-compose.yml`</br>
  Variables in it are available during the building of a container,
  but unless named in the `environment:` option, they are not available
  once the container is running.
* `env_file` - an option in compose that defines an existing external file.</br>
  Variables in this file will be available in the running container,
  but not during building of the container.

So a compose file having `env_file: .env` mixes these two together.

Benefit is that you do not need to make changes at multiple places.
Adding variables or changing a name in `.env` does not require you
to also go in to compose to add/change it there...  also the compose file
looks much cleaner, less cramped.

Only issue is that **all** variables from the `.env` file are available in
all containers that use this `env_file: .env` method.</br>
That can lead to potential issues if a container picks up environment
variable that is intended for a different container of the stack.

In the setups here it works and is tested, but if you start to use this
everywhere without understanding it, you can encounter issues.
So first troubleshooting step should be abandoning `.env` and write out 
the variables directly in the compose file only under containers that want them.

---

### Docker images latest tag

Most of the time the images are without any tag,
which defaults to `latest` tag being used.</br>
This is [frowned upon](https://vsupalov.com/docker-latest-tag/),
but feel free to put there the current version to lower the chance of a fuckup.

---

### Cloudflare

For managing DNS records. The free tier provides lot of management options and 
benefits. Like proxy between your domain and your server, so no one
can get your public IP just from your domain name. Or 5 firewall rules that allow
you to geoblock whole world except your country.

[How to move to cloudflare.](https://support.cloudflare.com/hc/en-us/articles/205195708-Changing-your-domain-nameservers-to-Cloudflare)

---

### ctop

[official site](https://github.com/bcicen/ctop)

![ctop-look](https://i.imgur.com/nGAd1MQ.png)

htop like utility for quick containers management.

It is absofuckinglutely amazing in how simple yet effective it is.

* hardware use overview, so you know which container uses how much cpu, ram, bandwidth, IO,...
* detailed info on a container, it's IP, published and exposed ports, when it was created,..
* quick management, quick exec in to a container, check logs, stop it,...

Written in Go, so its super fast and installation is trivial when it is a single binary,
as likely your distro does not have it in repos. If you use arch, like I do, its on AUR.

---

### Archlinux as a docker host 

My go-to is archlinux as I know it the best.
Usually in a virtual machine with snapshots before updates.

For Arch installation I had [this notes](arch_linux_host_install/)
on how to install and what to do afterwards.<br>
But after [archinstall script](https://wiki.archlinux.org/title/archinstall)
started to be included with arch ISO I switched to that.<br>
For after the install setup I created 
[Ansible-Arch repo](https://github.com/DoTheEvo/ansible-arch) that gets shit 
done in few minutes without danger of forgetting something.<br>
Ansible is really easy to use and very easy to read and understand playbooks,
so it might be worth the time to check out the concept to setup own ansible scripts.

The best aspect of having such repo is that it is a dedicated place where 
one can write solution to issues encountered, 
or enable freshly discovered feature for all deployments.

---

### SendGrid and Sendinblue

Services often need ability to send emails, for registration, password recset and such...

I got free sendgrid account which provides 100 free emails a day.
But I heard complains that is not as easy as it was to register on SendGrid.

I also use Sendinblue, I guess it was easy cuz I dont remember anything about it.
It works and got 300 mails a day

---

### other guides

* [StarWhiz/docker_deployment_notes](https://github.com/StarWhiz/docker_deployment_notes)
    - got inspired and wrote in similar way setup for various services
* [BaptisteBdn/docker-selfhosted-apps](https://github.com/BaptisteBdn/docker-selfhosted-apps)
   - many services using traefik for reverse proxy

