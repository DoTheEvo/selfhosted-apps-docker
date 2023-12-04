# Selfhosted-Apps-Docker

###### guide-by-example

---

![logo](https://i.imgur.com/u5LH0jI.png)

---

* [caddy_v2](caddy_v2/) - reverse proxy
* [vaultwarden](vaultwarden/) - password manager
* [bookstack](bookstack/) - notes and documentation
* [kopia](kopia_backup/) - backup utility replacing borg
* [borg_backup](borg_backup/) - backup utility
* [ddclient](ddclient/) - automatic DNS update
* [dnsmasq](dnsmasq/) - DNS and DHCP server
* [gotify / ntfy / signal](gotify-ntfy-signal/) - instant notifications apps
* [frigate](frigate/) - managing security cameras
* [jellyfin](jellyfin/) - video and music streaming
* [minecraft](minecraft/) - game server
* [meshcrentral](meshcrentral/) - web based remote desktop, like teamviewer or anydesk
* [rustdesk](rustdesk/) - remote desktop, like teamviewer or anydesk
* [nextcloud](nextcloud/) - file share & sync
* [opnsense](opnsense/) - a firewall, enterprise level 
* [qbittorrent](qbittorrent/) - torrent client
* [portainer](portainer/) - docker management
* [prometheus_grafana_loki](prometheus_grafana_loki/) - monitoring
* [unifi](unifi/) - management utility for ubiquiti devices
* [snipeit](snipeit/) - IT inventory management
* [trueNAS scale](trueNASscale/) - network file sharing
* [uptime kuma](uptime-kuma/) - uptime alerting tool 
* [squid](squid/) - anonymize forward proxy
* [wireguard](wireguard/) - the one and only VPN to ever consider
* [wg-easy](wg-easy/) - wireguard in docker with web gui
* [zammad](zammad/) - ticketing system
* [arch_linux_host_install](arch_linux_host_install)

Can also just check the directories listed at the top for work in progress

Check also [StarWhiz / docker_deployment_notes](https://github.com/StarWhiz/docker_deployment_notes/blob/master/README.md)<br>
Repo documents self hosted apps in similar format and also uses caddy for reverse proxy

---

* ### [For Docker Noobs](#for-docker-noobs-1)

---

# Core concepts

- `docker-compose.yml` does **not** need any **editing** to get something up,
   **changes** are to be done in the `.env` file.
- For **persistent** storage **bind mount** `./whatever_data` is used.
  No volumes, nor static path somewhere... just relative path next to compose file.
- **No version** declaration at the beginning of **compose**, as the practice was
  [**deprecated**](https://nickjanetakis.com/blog/docker-tip-51-which-docker-compose-api-version-should-you-use)

---

### Requirements 

**Basic linux and basic docker-compose knowledge.**
The shit here is pretty hand holding and detailed, but it still should not be
your first time running a docker container.

---

### Caddy reverse proxy

Kinda the heart of the setup is [Caddy reverse proxy](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>
It's described in most details and all guides have reverse proxy section
with Caddyfile config specific for them.</br>
Caddy is really great at simplifying the mess of https certificates, where
you don't really have to deal with anything, while having a one simple,
readable config file.

But no problem if using [traefik](https://github.com/DoTheEvo/Traefik-v2-examples)
or nginx proxy manager. You just have to deal with proxy settings on your own,
and 90% of the time its just sending traffic to port 80 and nothing else.

---

### Docker network

You really want to create a custom named docker network and use it.

`docker network create caddy_net`

It can be named whatever, but what it does over default is that it provides
[automatic DNS resolution](https://docs.docker.com/network/bridge/)
between containers. Meaning one can exec in to a container and ping another
container by its hostname.<br>
This makes config files simpler and cleaner.

---

### .env

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
So one of the troubleshooting steps might be abandoning `.env` and write out 
the variables directly in the compose file only under containers that want them.

---

### Docker images latest tag

Most of the time the images are without any tag,
which defaults to `latest` tag being used.</br>
This is [frowned upon](https://vsupalov.com/docker-latest-tag/),
and you should put there the current tags once things are going.
It will make updates easier when you know you can go back to a working version
with backups and knowing image version.<br>

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

Written in Go, so its super fast and installation is trivial when it is a single binary.<br>
download `linux-amd64` version; make it executable with chmod +x; move it to `/usr/bin/`;
now you can ctop anywhere.

---

### Brevo

Services often need ability to send emails, for notification, registration,
password reset and such... Sendinblue is free, offers 300 mails a day
and is easy to setup.

```
EMAIL_HOST=smtp-relay.brevo.com
EMAIL_PORT=587
EMAIL_HOST_USER=whoever_example@gmail.com
EMAIL_HOST_PASSWORD=xcmpwik-c31d9eykwef3342df2fwfj04-FKLzpHgMjGqP23
EMAIL_USE_TLS=1
```

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
or enable freshly discovered feature for all future deployments.

---

### Other guides

* [StarWhiz/docker_deployment_notes](https://github.com/StarWhiz/docker_deployment_notes)
    - got inspired and wrote in similar way setup for various services
* [BaptisteBdn/docker-selfhosted-apps](https://github.com/BaptisteBdn/docker-selfhosted-apps)
   - many services using traefik for reverse proxy
* [Awesome Docker Compose Examples](https://github.com/Haxxnet/Compose-Examples)

---

### For docker noobs

Docker is easy. Really.<br>

There are two main uses.

* For developers who daily work on apps and docker eases everything about it,
  from setting up environment, to testing and deployment.
* A hosting approach, where you mostly care about getting containers, that are
  prepared for you by developers, up and running.

This repo is about the second use. So be careful that you wont
spend time on resources used to educate developers. Sure, if you get through
that you will know docker better, but theres the danger that after sinking
4 hours reading and watching videos you still cant get a plain nginx web server
up and running and loses motivation.<br>

So when googling for guides, look for **docker compose**
rather than just **docker** tutorials.

[Beginners speedrun to selfhosting something in docker](beginners-speedrun-selfhosting/)

* [Good stuff](https://adamtheautomator.com/docker-compose-tutorial/)
* [https://devopswithdocker.com/getting-started](https://devopswithdocker.com/getting-started)
* [This](https://youtu.be/DM65_JyGxCo) one is pretty good. That entire channel
has good stuff. 

Will add shit I encounter and like.
