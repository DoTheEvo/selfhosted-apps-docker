# Prometheus+Grafana in docker

###### guide-by-example

![logo](https://i.imgur.com/e03aF8d.png)

WORK IN PROGRESS<br>
Loki and caddy monitoring parts are not finished yet

# Purpose

Monitoring of the host and the running cointaners.

* [Official Prometheus site](https://prometheus.io/)
* [Official Grafana site](https://grafana.com/)

Most of the stuff here is based off the magnificent
[stefanprodan/dockprom.](https://github.com/stefanprodan/dockprom)</br>
So maybe just go play with that.

# Chapters

* **[Core prometheus+grafana](#Overview)** - to get nice dashboards with metrics from docker host and containers
* **[Pushgateway](#Pushgateway)** - how to use it to allow pushing metrics in to prometheus from anywhere
* **[Alertmanager](#Alertmanager)** - how to use it for notifications
* **[Loki](#Loki)** - how to do the above things but for logs, not just metrics
* **[Caddy monitoring](#Caddy_monitoring)** - adding dashboard for reverse proxy info

# Overview

[Good youtube overview](https://youtu.be/h4Sl21AKiDg) of Prometheus.</br>

Prometheus is an open source system for monitoring and alerting,
written in golang.<br>
It periodicly collects metrics from configured targets,
makes these metrics available for visualization, and can trigger alerts.<br>
Prometheus is relatively young project, it is a **pull type** monitoring.

[Glossary.](https://prometheus.io/docs/introduction/glossary/)

* **Prometheus Server** is the core of the system, responsible for
  * pulling new metrics
  * storing the metrics in a database and evaluating them
  * making metrics available through PromQL API
* **Targets** - machines, services, applications that are monitored.</br>
  These need to have an **exporter**.
  *  **exporter** - a script or a service that gathers metrics on the target,
     converts them to prometheus server format,
     and exposes them at an endpoint so they can be pulled
* **Alertmanager** - responsible for handling alerts from Prometheus Server,
  and sending notifications through email, slack, pushover,..
  In this setup [ntfy](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/gotify-ntfy-signal) webhook will be used.<br>
  Grafana comes with own alerts, but grafana kinda feels... b-tier
* **pushgateway** - allows push type of monitoring.
  Should not be overused as it goes against the pull philosophy of prometheus.
  Most commonly it is used to collect data from batch jobs, or from services
  that have short execution time. Like a backup script.<br>
* **Grafana** - for web UI visualization of the collected metrics


![prometheus components](https://i.imgur.com/AxJCg8C.png)

# Files and directory structure

```
/home/
 └── ~/
     └── docker/
         └── prometheus/
             ├──── grafana_data/
             ├──── prometheus_data/
             ├── docker-compose.yml
             ├── .env
             └── prometheus.yml
```

* `grafana_data/` - a directory where grafana stores its data
* `prometheus_data/` - a directory where prometheus stores its database and data
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the containers
* `prometheus.yml` - a configuration file for prometheus

The three files must be provided.</br>
The directories are created by docker compose on the first run.

# docker-compose

* **Prometheus** - Container with some extra commands run at the start up.
  Setting stuff like storage, data rentetion (500hours - 20 days)...
  Bind mounted prometheus_data for persistent storage
  and `prometheus.yml` for some basic configuration.
* **Grafana** - Cotainer, bind mounted directory for persistent data storage
* **NodeExporter** - an exporter for linux machines,
  in this case gathering the metrics of the linux machine runnig docker,
  like uptime, cpu load, memory use, network bandwidth use, disk space,...<br>
  Also bind mount of some system directories to have access to required info.
* **cAdvisor** - an exporter for gathering docker **containers** metrics,
  showing cpu, memory, network use of each container<br>
  Runs in `privileged` mode and has some bind mounts of system directories
  to have access to required info.

*Note* - ports are only `expose`, since expectation of use of a reverse proxy
and accessing the services by hostname, not ip and port.

`docker-compose.yml`
```yml
services:

  # MONITORING SYSTEM AND THE METRICS DATABASE
  prometheus:
    image: prom/prometheus:v2.42.0
    container_name: prometheus
    hostname: prometheus
    user: root
    restart: unless-stopped
    depends_on:
      - cadvisor
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=500h'
      - '--web.enable-lifecycle'
    volumes:
      - ./prometheus_data:/prometheus
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    expose:
      - 9090:9090
    labels:
      org.label-schema.group: "monitoring"

  # WEB BASED UI VISUALISATION OF METRICS
  grafana:
    image: grafana/grafana:9.3.6
    container_name: grafana
    hostname: grafana
    user: root
    restart: unless-stopped
    env_file: .env
    volumes:
      - ./grafana_data:/var/lib/grafana
    expose:
      - 3000
    labels:
      org.label-schema.group: "monitoring"

  # HOST LINUX MACHINE METRICS EXPORTER
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

# prometheus.yml

[Official documentation.](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)

Contains the bare minimum setup of targets from where metrics are to be pulled.<br>
Stefanprodan [gives](https://github.com/stefanprodan/dockprom/blob/master/prometheus/prometheus.yml)
a custom shorter scrape intervals, but I feel thats not really
[necessary](https://www.robustperception.io/keep-it-simple-scrape_interval-id/).

`prometheus.yml`
```yml
global:
  scrape_interval:     15s
  evaluation_interval: 15s

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
```

# First run and Grafana configuration

* login admin/admin to `graf.example.com`, change the password
* add Prometheus as a Data source in configuration<br>
  set URL to `http://prometheus:9090`<br>
* import dashboards from [json files in this repo](dashboards/)<br>

These dashboards are the preconfigured ones from
[stefanprodan/dockprom](https://github.com/stefanprodan/dockprom)
with few changes.<br>
`docker_host.json` did not show free disk space, it needed `fstype` changed from
`aufs` to `ext4`. Also [a fix](https://github.com/stefanprodan/dockprom/issues/18#issuecomment-487023049)
for host network monitoring not showing traffick. And in all of them
the time interval is set to show last 1h instead of last 15m

* **docker_host.json** - dashboard showing linux host machine metrics
* **docker_containers.json** - dashboard showing docker containers metrics,
  except the ones labeled as `monitoring` in the compose file
* **monitoring_services.json** - dashboar showing docker containers metrics
  of containers that are labeled `monitoring`

![interface-pic](https://i.imgur.com/wzwgBkp.png)

---

<details>
<summary><h1>Pushgateway</h1></summary>

The setup and real world use of pushgateway, along with small steps 
when learning it are in the repo - 
[Veeam Prometheus Grafana](https://github.com/DoTheEvo/veeam-prometheus-grafana)<br>
Including pushing information from windows powershell.

![veeam-dash](https://i.imgur.com/dUyzuyl.png)

</details>

---
---

<details>
  <summary><h1>Alertmanager</h1></summary>

  Several changes are needed

  - New container - `alertmanager` added to the compose file.
  - New file - `alertmanager.yml` bind mounted in the alertmanager container.<br>
    This file contains configuration about where and how to deliver alerts.<br>
    A selfhosted
    [ntfy](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/gotify-ntfy-signal)
    webhook is used that gets alerts to a phone app.
  - New file - `alert.rules` mounted in to prometheus container<br>
    This files defines when value of some metric becomes an alert event.
  - Changed file - `prometheus.yml` added `alerting` section
    and the path to the `rule_files`

  <details>
    <summary>docker-compose.yml</summary>
  
  ```yml
  services:

    # MONITORING SYSTEM AND THE METRICS DATABASE
    prometheus:
      image: prom/prometheus:v2.42.0
      container_name: prometheus
      hostname: prometheus
      user: root
      restart: unless-stopped
      depends_on:
        - cadvisor
      command:
        - '--config.file=/etc/prometheus/prometheus.yml'
        - '--storage.tsdb.path=/prometheus'
        - '--web.console.libraries=/etc/prometheus/console_libraries'
        - '--web.console.templates=/etc/prometheus/consoles'
        - '--storage.tsdb.retention.time=500h'
        - '--web.enable-lifecycle'
      volumes:
        - ./prometheus_data:/prometheus
        - ./prometheus.yml:/etc/prometheus/prometheus.yml
        - ./alert.rules:/etc/prometheus/rules/alert.rules
      expose:
        - 9090:9090
      labels:
        org.label-schema.group: "monitoring"

    # WEB BASED UI VISUALISATION OF METRICS
    grafana:
      image: grafana/grafana:9.3.6
      container_name: grafana
      hostname: grafana
      user: root
      restart: unless-stopped
      env_file: .env
      volumes:
        - ./grafana_data:/var/lib/grafana
      expose:
        - 3000
      labels:
        org.label-schema.group: "monitoring"

    # HOST LINUX MACHINE METRICS EXPORTER
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

    # ALERT MANAGMENT BY PROMETHEUS
    alertmanager:
      image: prom/alertmanager:v0.25.0
      container_name: alertmanager
      hostname: alertmanager
      restart: unless-stopped
      volumes:
        - ./alertmanager.yml:/etc/alertmanager.yml
        - ./alertmanager_data:/alertmanager
      command:
        - '--config.file=/etc/alertmanager.yml'
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
  </details>

  <details>
    <summary>alertmanager.yml</summary>

  ```yml
  route:
    receiver: 'email'

  receivers:
    - name: "ntfy"
      webhook_configs:
      - url: 'https://ntfy.example.com/alertmanager'
        send_resolved: true
        
    - name: 'email'
      email_configs:
      - to: 'whoever@example.com'
        from: 'alertmanager@example.com'
        smarthost: smtp-relay.sendinblue.com:587
        auth_username: '<registration_email@gmail.com>'
        auth_identity: '<registration_email@gmail.com>'
        auth_password: '<long ass generated SMTP key>'
  ```
  </details>

  <details>
  <summary>alert.rules</summary>

  ```yml
  groups:
    - name: host
      rules:
        - alert: DiskSpaceLow
          expr: sum(node_filesystem_free_bytes{fstype="ext4"}) > 19
          for: 10s
          labels:
            severity: critical
          annotations:
            description: "Diskspace is low!"
  ```
  </details>

  <details>
    <summary>prometheus.yml</summary>

  ```yml
  global:
    scrape_interval:     15s
    evaluation_interval: 15s

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

  alerting:
    alertmanagers:
    - scheme: http
      static_configs:
      - targets: 
        - 'alertmanager:9093'

  rule_files:
    - '/etc/prometheus/rules/alert.rules'
  ```
  </details>

  test:<br>
  `curl -H 'Content-Type: application/json' -d '[{"labels":{"alertname":"blabla"}}]' https://alert.example.com/api/v1/alerts`

  reload rules
  `curl -X POST http://admin:admin@<host-ip>:9090/-/reload`

</details>

---
---

<details>
  <summary><h1>Loki</h1></summary>

  Loki is made by the grafana team, and they call it Prometheus for logs.<br>
  It is a **push** type monitoring, where an agent - **promtail**
  pushes logs on to a Loki instance, or **loki-docker-driver** is installed
  on a docker host and log pushing is set either globally in /etc/docker/daemon.json
  or per container in compose files.

  What this example will set out to do is monitor logs of a
  [minecraft server.](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/minecraft)
  Have some dashboards about logs and have an alert when a player joins.<br>
  Its just proof of concept, as there are prometheus exporters for minecraft,
  so digging through logs to get alert is less optimal.

  What needs to be done:

  - New container - `loki` added to the compose file. Loki stores logs and makes
    them available for grafana to visualize.
  - New file - `loki-docker-config.yml` bind mounted in the loki container.<br>
    The file is [all default](https://github.com/grafana/loki/tree/main/cmd/loki),
    except for alertmanager url.<br>
  - install [loki-docker-driver](https://grafana.com/docs/loki/latest/clients/docker-driver/)<br>
    `docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions`<br>
  - adding logging section to compose files of a containers 
    that should be monitored, like so:<br>
    ```
    services:
      whoami:
        image: "containous/whoami"
        container_name: "whoami"
        hostname: "whoami"
        ports:
         - 88:80
        logging:
          driver: "loki"
          options:
            loki-url: "http://localhost:3100/loki/api/v1/push"
    ```

  Promtail can be used to push logs to loki, older version of this readme
  has details - [here.](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/70830ac8679d81e73265c8522e06312db4905f3b/prometheus_grafana)

  <details>
    <summary>docker-compose.yml</summary>
  
  ```yml
  services:

    # MONITORING SYSTEM AND THE METRICS DATABASE
    prometheus:
      image: prom/prometheus:v2.42.0
      container_name: prometheus
      hostname: prometheus
      user: root
      restart: unless-stopped
      depends_on:
        - cadvisor
      command:
        - '--config.file=/etc/prometheus/prometheus.yml'
        - '--storage.tsdb.path=/prometheus'
        - '--web.console.libraries=/etc/prometheus/console_libraries'
        - '--web.console.templates=/etc/prometheus/consoles'
        - '--storage.tsdb.retention.time=500h'
        - '--web.enable-lifecycle'
      volumes:
        - ./prometheus_data:/prometheus
        - ./prometheus.yml:/etc/prometheus/prometheus.yml
        - ./alert.rules:/etc/prometheus/rules/alert.rules
      expose:
        - 9090:9090
      labels:
        org.label-schema.group: "monitoring"

    # WEB BASED UI VISUALISATION OF METRICS
    grafana:
      image: grafana/grafana:9.3.6
      container_name: grafana
      hostname: grafana
      user: root
      restart: unless-stopped
      env_file: .env
      volumes:
        - ./grafana_data:/var/lib/grafana
      expose:
        - 3000
      labels:
        org.label-schema.group: "monitoring"

    # HOST LINUX MACHINE METRICS EXPORTER
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

    # ALERT MANAGMENT BY PROMETHEUS
    alertmanager:
      image: prom/alertmanager:v0.25.0
      container_name: alertmanager
      hostname: alertmanager
      restart: unless-stopped
      volumes:
        - ./alertmanager.yml:/etc/alertmanager.yml
        - ./alertmanager_data:/alertmanager
      command:
        - '--config.file=/etc/alertmanager.yml'
        - '--storage.path=/alertmanager'
      expose:
        - 9093
      labels:
        org.label-schema.group: "monitoring"

    # LOG MANAGMENT WITH LOKI
    loki:
      image: grafana/loki:2.7.3
      container_name: loki
      hostname: loki
      user: root
      restart: unless-stopped
      volumes:
        - ./loki_data:/loki
        - ./loki-docker-config.yml:/etc/loki-docker-config.yml
      command:
        - '-config.file=/etc/loki-docker-config.yml'
      ports:
        - 3100:3100
      labels:
        org.label-schema.group: "monitoring"

  networks:
    default:
      name: $DOCKER_MY_NETWORK
      external: true
  ```
  </details>

  <details>
    <summary>loki-docker-config.yml</summary>

  ```yml
  auth_enabled: false

  server:
    http_listen_port: 3100

  common:
    path_prefix: /loki
    storage:
      filesystem:
        chunks_directory: /loki/chunks
        rules_directory: /loki/rules
    replication_factor: 1
    ring:
      kvstore:
        store: inmemory

  schema_config:
    configs:
      - from: 2020-10-24
        store: boltdb-shipper
        object_store: filesystem
        schema: v11
        index:
          prefix: index_
          period: 24h

  ruler:
    alertmanager_url: http://alertmanager:9093

  analytics:
    reporting_enabled: false
  ```
  </details>

  
Now with driver installed, files in place, compose edited,..

* In grafana, loki needs to be added as a datasource.<br>
  If everything works as it should, there should be no red notice, down left side
  only gree:<br>
  `Data source connected and labels found.`
* In `Explore` section, if the input is set to `Builder`, picking from dropdown
  filter menu container_name = minecraft, and hitting run query.. 
  this should result in seeing minecraft logs. 
* In Alert grafana section, 





</details>

---
---

<details>
  <summary><h1>Caddy monitoring</h1></summary>

</details>

---
---

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
