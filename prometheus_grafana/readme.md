# Prometheus+Grafana in docker

###### guide by example

![logo](https://i.imgur.com/e03aF8d.png)

## Purpose

Monitoring of the host and the running cointaners.

* [Official site](https://prometheus.io/)
* [Github](https://github.com/prometheus)
* [DockerHub](https://hub.docker.com/r/prom/prometheus/)

Everything here is based on an excelent
[stefanprodan/dockprom](https://github.com/stefanprodan/dockprom)

## The containers

* Prometheus - monitoring system and the metrics database
* Grafana - web based ui visualisation of the metrics
* NodeExporter - hosts metrics collector
* cAdvisor - docker containers metrics collector

## Files and directory structure

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

## docker-compose

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

## Other files

**prometheus.yml** - config for prometheus, bind mounted in to prometheus container.
This one contains the bare minimum setup of metric endpoints to be scarepd for data.

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

**The entire /grafana/provisioning directory is bind mounted in to grafana container**

/grafana/provisioning/datasources/**datasource.yml** - grafana's datasource config file
if one would not exist then during the first run it would ask for this info.

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
    editable: true
```

* grafana/provisioning/dashboards/**dashboard.yml** - not sure


`dashboard.yml`
```yml
apiVersion: 1

providers:
  - name: 'Prometheus'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    editable: true
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards
```

* grafana/provisioning/dashboards/**<dashboards.json files>** - pre configured dashboards

Premade Dashboards are in the `dashboards` of this tutorial.

## Reverse proxy

  Caddy v2 is used,
  details [here](https://github.com/DoTheEvo/Caddy-v2-examples)

  `Caddyfile`
  ```
  grafana.{$MY_DOMAIN} {
      reverse_proxy grafana:3000
  }
  ```

## Explanation

  asdasd


---

![interface-pic](https://i.imgur.com/RrK29wC.png)

## Update

  * [watchtower](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/watchtower) updates the image automaticly

  * manual image update</br>
    `docker-compose pull`</br>
    `docker-compose up -d`</br>
    `docker image prune`

## Backup and restore

  * **backup** using [borgbackup setup](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/borg_backup)
  that makes daily snapshot of the entire directory
    
  * **restore**</br>
    down the bookstack containers `docker-compose down`</br>
    delete the entire bookstack directory</br>
    from the backup copy back the bookstack directortory</br>
    start the container `docker-compose up -d`

## Backup of just user data


## Restore the user data

