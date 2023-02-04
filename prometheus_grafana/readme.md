# Prometheus+Grafana in docker

###### guide-by-example

![logo](https://i.imgur.com/e03aF8d.png)

# Purpose

Monitoring of the host and the running cointaners.

* [Official site](https://prometheus.io/)
* [Github](https://github.com/prometheus)
* [DockerHub](https://hub.docker.com/r/prom/prometheus/)

Everything here is based on the magnificent
[stefanprodan/dockprom.](https://github.com/stefanprodan/dockprom)</br>
So maybe just go get that.

[Good youtube overview](https://youtu.be/h4Sl21AKiDg) of Prometheus.</br>
Here's [veeam-prometheus-grafana](https://github.com/DoTheEvo/veeam-prometheus-grafana)
how to setup pushgateway a and send to it info on done backups
and visualize history of that in grafana. 
---

Prometheus is an open source system for monitoring and alerting,
written in golang.<br>
It periodicly collects metrics from configured targets,
exposes collected metrics for visualization, and can trigger alerts.<br>
Prometheus is relatively young project, it is a **pull type** monitoring
and consists of several components.

* **Prometheus Server** is the core of the system, responsible for
  * pulling new metrics
  * storing the metrics in a database and evaluating them
  * making metrics available through PromQL API
* **Targets** - machines, services, applications that are monitored.</br>
  These need to have an **exporter**.
  *  **exporter** - a script or a service that gathers metrics on the target,
     converts them to prometheus server format,
     and exposes them at an endpoint so they can be pulled
* **AlertManager** - responsible for handling alerts from Prometheus Server,
  and sending notifications through email, slack, pushover,..
  In this setup [ntfy](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/gotify-ntfy-signal) webhook will be used.<br>
  Grafana comes with own alerts, but grafana kinda feels... b-tier
* **pushgateway** - allows push type of monitoring.
  Should not be overused as it goes against the pull philosophy of prometheus.
  Most commonly it is used to collect data from batch jobs, or from services
  that have short execution time. Like a backup script.<br>
  [Here's](https://github.com/DoTheEvo/veeam-prometheus-grafana) my use of it
  to monitor veeam backup servers.
* **Grafana** - for web UI visualization of the collected metrics 

[glossary](https://prometheus.io/docs/introduction/glossary/)

![prometheus components](https://i.imgur.com/AxJCg8C.png)

# Files and directory structure

```
/home/
 └── ~/
     └── docker/
         └── prometheus/
             ├─── alertmanager/
             ├─── grafana/
             ├─── grafana-data/
             ├─── prometheus-data/
             ├── docker-compose.yml
             ├── .env
             └── prometheus.yml
```

* `alertmanager/` - ...
* `grafana/` - a directory containing grafanas configs and dashboards
* `grafana-data/` - a directory where grafana stores its data
* `prometheus-data/` - a directory where prometheus stores its database and data
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the containers
* `prometheus.yml` - a configuration file for prometheus

The three files must be provided.</br>
The directories are created by docker compose on the first run.

# docker-compose

* **Prometheus** - prometheus server, pulling, storing, evaluating metrics
* **Grafana** - web UI visualization of the collected metrics
  in nice dashboards
* **NodeExporter** - an exporter for linux machines,
  in this case gathering the metrics of the linux machine runnig docker,
  like uptime, cpu load, memory use, network bandwidth use, disk space,...
* **cAdvisor** - exporter for gathering docker **containers** metrics,
  showing cpu, memory, network use of each container
* **alertmanager** - guess what that one do

`docker-compose.yml`
```yml
services:

  # MONITORING SYSTEM AND THE METRICS DATABASE
  prometheus:
    image: prom/prometheus:v2.42.0
    container_name: prometheus
    hostname: prometheus
    restart: unless-stopped
    user: root
    depends_on:
      - cadvisor
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - ./prometheus_data:/prometheus
    ports:
      - 9090:9090
    labels:
      org.label-schema.group: "monitoring"

  # WEB BASED UI VISUALISATION OF THE METRICS
  grafana:
    image: grafana/grafana:9.3.6
    container_name: grafana
    hostname: grafana
    restart: unless-stopped
    env_file: .env
    user: root
    volumes:
      - ./grafana_data:/var/lib/grafana
      - ./grafana/provisioning/dashboards:/etc/grafana/provisioning/dashboards
      - ./grafana/provisioning/datasources:/etc/grafana/provisioning/datasources
    expose:
      - 3000
    labels:
      org.label-schema.group: "monitoring"

  # HOST MACHINE METRICS EXPORTER
  nodeexporter:
    image: prom/node-exporter:v1.5.0
    container_name: nodeexporter
    hostname: nodeexporter
    restart: unless-stopped
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    expose:
      - 9100
    labels:
      org.label-schema.group: "monitoring"

  # DOCKER CONTAINERS METRICS EXPORTER
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:v0.47.1
    container_name: cadvisor
    hostname: cadvisor
    restart: unless-stopped
    privileged: true
    devices:
      - /dev/kmsg:/dev/kmsg
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker:/var/lib/docker:ro
      - /cgroup:/cgroup:ro #doesn't work on MacOS only for Linux
    expose:
      - 3000
    labels:
      org.label-schema.group: "monitoring"

  # NOTIFICATIONS MANAGMENT
  alertmanager:
    image: prom/alertmanager:v0.25.0
    container_name: alertmanager
    hostname: alertmanager
    restart: unless-stopped
    volumes:
      - ./alertmanager:/etc/alertmanager
    command:
      - '--config.file=/etc/alertmanager/config.yml'
      - '--storage.path=/alertmanager'
    expose:
      - 9093
    labels:
      org.label-schema.group: "monitoring"

networks:
  default:
    name: $DOCKER_MY_NETWORK
    external: true
```

`.env`

```bash
# GENERAL
MY_DOMAIN=example.com
DOCKER_MY_NETWORK=caddy_net
TZ=Europe/Bratislava

# GRAFANA
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=admin
GF_USERS_ALLOW_SIGN_UP=false
```

**All containers must be on the same network**.</br>
Which is named in the `.env` file.</br>
If one does not exist yet: `docker network create caddy_net`

# Prometheus configuration

* /prometheus/**prometheus.yml**

[Official documentation.](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)

A config file for prometheus, bind mounted in to prometheus container.</br>
Contains the bare minimum setup of targets from where metrics are to be pulled.

`prometheus.yml`
```yml
global:
  scrape_interval:     15s
  evaluation_interval: 15s

# A scrape configuration containing exactly one endpoint to scrape.
scrape_configs:
  - job_name: 'nodeexporter'
    static_configs:
      - targets: ['nodeexporter:9100']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']

  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
```

# Reverse proxy

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

`Caddyfile`
```
graf.{$MY_DOMAIN} {
  reverse_proxy grafana:3000
}

prom.{$MY_DOMAIN} {
  reverse_proxy prometheus:9090
}

push.{$MY_DOMAIN} {
  reverse_proxy pushgateway:9091
}
```

# First run and Grafana configuration

* login admin/admin, afterwards change password
* add Prometheus as a `Data source` in configuration<br>
  set `URL` to `http://prometheus:9090`<br>
  Save & test should return *Green*
* import dashboards from [json files in this repo](dashboards/)<br>
  Dashboards > +import > ..either copy paste or point to downloaded file

  
Preconfigured dashboards from
[stefanprodan/dockprom](https://github.com/stefanprodan/dockprom).</br>
Mostly unchanged, except for the default time range shown,
changed from 15min to 1hour,
and [a fix](https://github.com/stefanprodan/dockprom/issues/18#issuecomment-487023049)
for host network monitoring not showing traffick.

* **docker_host.json** - dashboard showing linux host metrics
* **docker_containers.json** - dashboard showing docker containers metrics,
  except the ones labeled as `monitoring` in the compose file
* **monitoring_services.json** - dashboar showing docker containers metrics
  of containers that are labeled `monitoring`, which are this repo containers.



---

![interface-pic](https://i.imgur.com/wzwgBkp.png)

# Update

Manual image update:

- `docker-compose pull`</br>
- `docker-compose up -d`</br>
- `docker image prune`

# Backup and restore

#### Backup

Using [borg](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)
that makes daily snapshot of the entire directory.
  
#### Restore

* down the prometheus containers `docker-compose down`</br>
* delete the entire prometheus directory</br>
* from the backup copy back the prometheus directory</br>
* start the containers `docker-compose up -d`
