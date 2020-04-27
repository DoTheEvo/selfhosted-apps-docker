# Prometheus+Grafana in docker

###### guide by example

![logo](https://i.imgur.com/e03aF8d.png)

# Purpose

Monitoring of the host and the running cointaners.

* [Official site](https://prometheus.io/)
* [Github](https://github.com/prometheus)
* [DockerHub](https://hub.docker.com/r/prom/prometheus/)

Everything here is based on the magnificent
[stefanprodan/dockprom](https://github.com/stefanprodan/dockprom)

# Containers

* **Prometheus** - monitoring system that pulls and stores data from exporters
  and then exposes them for visualization.
  Can also alert if a metric fails preset rule.
* **Grafana** - web based visualization of the collected metrics
  in nice graphs, gauges, tables,...
* **NodeExporter** - exporter for linux machines,
  in this case gathering docker host metrics,
  like uptime, cpu load, memory use, network bandwidth use, disk space,...
* **cAdvisor** - exporter for gathering docker containers metrics,
  showing cpu, memory, network use of each container

# Files and directory structure

```
/home
└── ~
    └── docker
        └── prometheus
            │ 
            ├── 🗁 grafana
            │   └── 🗁 provisioning
            │       ├── 🗁 dashboards
            │       │   ├── 🗋 dashboard.yml            
            │       │   ├── 🗋 docker_host.json
            │       │   ├── 🗋 docker_containers.json
            │       │   └── 🗋 monitor_services.json
            │       │
            │       └── 🗁 datasources 
            │           └── 🗋 datasource.yml
            │
            ├── 🗁 grafana-data
            ├── 🗁 prometheus-data
            │
            ├── 🗋 .env
            ├── 🗋 docker-compose.yml
            └── 🗋 prometheus.yml
```

# docker-compose

`docker-compose.yml`
```yml
version: '3'
services:

  # MONITORING SYSTEM AND THE METRICS DATABASE
  prometheus:
    image: prom/prometheus
    container_name: prometheus
    hostname: prometheus
    restart: unless-stopped
    user: root
    depends_on:
      - cadvisor
    ports:
      - "9090:9090"
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=200h'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--web.enable-lifecycle'
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - ./prometheus_data:/prometheus
    labels:
      org.label-schema.group: "monitoring"

  # WEB BASED UI VISUALISATION OF THE METRICS
  grafana:
    image: grafana/grafana
    container_name: grafana
    hostname: grafana
    restart: unless-stopped
    user: root
    environment:
      - GF_SECURITY_ADMIN_USER
      - GF_SECURITY_ADMIN_PASSWORD
      - GF_USERS_ALLOW_SIGN_UP
    volumes:
      - ./grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
    labels:
      org.label-schema.group: "monitoring"

  # HOSTS METRICS COLLECTOR
  nodeexporter:
    image: prom/node-exporter
    container_name: nodeexporter
    hostname: nodeexporter
    restart: unless-stopped
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.ignored-mount-points=^/(sys|proc|dev|host|etc)($$|/)'
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    labels:
      org.label-schema.group: "monitoring"

  # DOCKER CONTAINERS METRICS COLLECTOR
  cadvisor:
    image: google/cadvisor
    container_name: cadvisor
    hostname: cadvisor
    restart: unless-stopped
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /sys:/sys:ro
      - /var/lib/docker:/var/lib/docker:ro
      - /cgroup:/cgroup:ro
    labels:
      org.label-schema.group: "monitoring"

networks:
  default:
    external:
      name: $DEFAULT_NETWORK
```

`.env`

```bash
# GENERAL
MY_DOMAIN=blabla.org
DEFAULT_NETWORK=caddy_net
TZ=Europe/Prague

# GRAFANA
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=admin
GF_USERS_ALLOW_SIGN_UP=false
```

**All containers must be on the same network**.</br>
If one does not exist yet: `docker network create caddy_net`

# Configuration files

Setup is mostly configured through config files.
Some of the grafana config files could be ommited and info passed on the first run,
but setting it through GUI wont generate these files which hinders backup.

#### prometheus.yml

* [official documentation](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)

A config file for prometheus, bind mounted in to prometheus container.</br>
This one contains the bare minimum setup of endpoints to be scraped for data.

`prometheus.yml`
```yml
global:
  scrape_interval:     15s
  evaluation_interval: 15s

# A scrape configuration containing exactly one endpoint to scrape.
scrape_configs:
  - job_name: 'nodeexporter'
    scrape_interval: 5s
    static_configs:
      - targets: ['nodeexporter:9100']

  - job_name: 'cadvisor'
    scrape_interval: 5s
    static_configs:
      - targets: ['cadvisor:8080']

  - job_name: 'prometheus'
    scrape_interval: 10s
    static_configs:
      - targets: ['localhost:9090']
```

#### datasource.yml

* /grafana/provisioning/datasources/**datasource.yml**
* [official documentation](https://grafana.com/docs/grafana/latest/administration/provisioning/#datasources)

Grafana's datasources config file, from where it suppose to get metrics.</br>
Here it ust points at prometheus container.

`datasource.yml`
```yml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    orgId: 1
    url: http://prometheus:9090
    basicAuth: false
    isDefault: true
    editable: false
```

#### dashboard.yml

* grafana/provisioning/dashboards/**dashboard.yml**
* [official documentation](https://grafana.com/docs/grafana/latest/administration/provisioning/#dashboards)

Config file telling grafana from where to load dashboards.

`dashboard.yml`
```yml
apiVersion: 1

providers:
  - name: 'Prometheus'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    editable: false
    allowUiUpdates: false
    options:
      path: /etc/grafana/provisioning/dashboards
```

#### \<dashboards>.json

* grafana/provisioning/dashboards/**<dashboards.json>**
* [official documentation](https://grafana.com/docs/grafana/latest/reference/dashboard/)

Preconfigured dashboards from prodigious
[stefanprodan/dockprom](https://github.com/stefanprodan/dockprom).</br>
Mostly unchanged, except for default time interval shown changed from 15min to 1 hour,
and [a fix](https://github.com/stefanprodan/dockprom/issues/18#issuecomment-487023049)
for host network monitoring not showing traffick.

# Reverse proxy

Caddy v2 is used,
details [here](https://github.com/DoTheEvo/Caddy-v2-examples)

The setup is accessed through grafana.
But occasionally there might be need to check with prometheus,
which will be available on \<docker-host-ip>:9090,
assuming port 9090 is kept mapped in the compose file.

`Caddyfile`
```
grafana.{$MY_DOMAIN} {
    reverse_proxy grafana:3000
}

:9090 {
    reverse_proxy prometheus:9090
}
```

---

![interface-pic](https://i.imgur.com/RrK29wC.png)

# Update

  * [watchtower](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/watchtower) updates the image automaticly

  * manual image update</br>
    `docker-compose pull`</br>
    `docker-compose up -d`</br>
    `docker image prune`

# Backup and restore

  * **backup** using [borgbackup setup](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)
  that makes daily snapshot of the entire directory
    
  * **restore**</br>
    down the containers `docker-compose down`</br>
    delete the entire prometheus directory</br>
    from the backup copy back the prometheus directortory</br>
    start the container `docker-compose up -d`
