# Prometheus+Grafana in docker

###### guide-by-example

![logo](https://i.imgur.com/q41QfyI.png)

WORK IN PROGRESS<br>
Loki and caddy monitoring parts are not finished yet

# Purpose

Monitoring of the host and the running cointaners.

* [Official Prometheus](https://prometheus.io/)
* [Official Grafana](https://grafana.com/)
* [Official Loki](https://grafana.com/oss/loki/)

Monitoring in this case means gathering and showing information on how services
or machines or containers are running. Can be cpu, io, ram, disk use... 
can be number of http requests, errors, or results of backups.<br>
Prometheus deals with metrics. Loki deals with logs. Grafana is there to show
the data on a dashboard.

Lot of the prometheus stuff here is based off the magnificent
[stefanprodan/dockprom.](https://github.com/stefanprodan/dockprom)

# Chapters

* **[Core prometheus+grafana](#Overview)** - nice dashboards with metrics of docker host and containers
* **[Pushgateway](#Pushgateway)** - push data to prometheus from anywhere
* **[Alertmanager](#Alertmanager)** - setting alerts and getting notifications
* **[Loki](#Loki)** - all of the above but for log files
* **[Caddy monitoring](#Caddy_monitoring)** - monitoring a reverse proxy

# Overview

[Good youtube overview](https://youtu.be/h4Sl21AKiDg) of Prometheus.</br>

Prometheus is an open source system for monitoring and alerting,
written in golang.<br>
It periodically collects metrics from configured targets,
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
  **In this setup [ntfy](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/gotify-ntfy-signal)
  webhook will be used.**
* **pushgateway** - allows push type of monitoring. Meaning a machine anywhere
  in the world can push data in to your prometheus. Should not be overused
  as it goes against the pull philosophy of prometheus.
* **Grafana** - for web UI visualization of the collected metrics


![prometheus components](https://i.imgur.com/AxJCg8C.png)

# Files and directory structure

```
/home/
 └── ~/
     └── docker/
         └── prometheus/
             ├── 🗁 grafana_data/
             ├── 🗁 prometheus_data/
             ├── 🗋 docker-compose.yml
             ├── 🗋 .env
             └── 🗋 prometheus.yml
```

* `grafana_data/` - a directory where grafana stores its data
* `prometheus_data/` - a directory where prometheus stores its database and data
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the containers
* `prometheus.yml` - a configuration file for prometheus

The three files must be provided.</br>
The directories are created by docker compose on the first run.

# docker-compose

* **Prometheus** - The official image used. Few extra commands passing configuration.
  Of note is 240 hours(10days) retention policy.
* **Grafana** - The official image used. Bind mounted directory
  for persistent data storage. User sets as root, as it solves issues I am
  lazy to investigate.
* **NodeExporter** - An exporter for linux machines,
  in this case gathering the metrics of the linux machine runnig docker,
  like uptime, cpu load, memory use, network bandwidth use, disk space,...<br>
  Also bind mount of some system directories to have access to required info.
* **cAdvisor** - An exporter for gathering docker **containers** metrics,
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
      - '--storage.tsdb.retention.time=240h'
      - '--web.enable-lifecycle'
    volumes:
      - ./prometheus_data:/prometheus
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    expose:
      - "9090"
    labels:
      org.label-schema.group: "monitoring"

  # WEB BASED UI VISUALISATION OF METRICS
  grafana:
    image: grafana/grafana:9.4.3
    container_name: grafana
    hostname: grafana
    user: root
    restart: unless-stopped
    env_file: .env
    volumes:
      - ./grafana_data:/var/lib/grafana
    expose:
      - "3000"
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
      - "9100"
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
      - "3000"
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
DOCKER_MY_NETWORK=caddy_net
TZ=Europe/Bratislava

# GRAFANA
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=admin
GF_USERS_ALLOW_SIGN_UP=false
# GRAFANA EMAIL
GF_SMTP_ENABLED=true
GF_SMTP_HOST=smtp-relay.sendinblue.com:587
GF_SMTP_USER=example@gmail.com
GF_SMTP_PASSWORD=xzu0dfFhn3eqa
```

**All containers must be on the same network**.</br>
Which is named in the `.env` file.</br>
If one does not exist yet: `docker network create caddy_net`

## prometheus.yml

[Official documentation.](https://prometheus.io/docs/prometheus/latest/configuration/configuration/)

Contains the bare minimum setup of targets from where metrics are to be pulled.

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

## Reverse proxy

Caddy v2 is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

`Caddyfile`
```php
graf.{$MY_DOMAIN} {
  reverse_proxy grafana:3000
}

prom.{$MY_DOMAIN} {
  reverse_proxy prometheus:9090
}
```

## First run and Grafana configuration

* login admin/admin to `graf.example.com`, change the password
* add Prometheus as a Data source in configuration<br>
  set URL to `http://prometheus:9090`<br>
* import dashboards from [json files in this repo](dashboards/)<br>

These dashboards are the preconfigured ones from
[stefanprodan/dockprom](https://github.com/stefanprodan/dockprom)
with few changes.<br>
`docker_host.json` did not show free disk space for me, had to change `fstype`
from `aufs` to `ext4`.
Also included is [a fix](https://github.com/stefanprodan/dockprom/issues/18#issuecomment-487023049)
for host network monitoring not showing traffick. In all of them
the default time interval is set to 1h instead of 15m

* **docker_host.json** - dashboard showing linux host machine metrics
* **docker_containers.json** - dashboard showing docker containers metrics,
  except the ones labeled as `monitoring` in the compose file
* **monitoring_services.json** - dashboar showing docker containers metrics
  of containers that are labeled `monitoring`

![interface-pic](https://i.imgur.com/wzwgBkp.png)

---
---

# Pushgateway

Gives freedom to push information in to prometheus from anywhere.

## The setup

To add pushgateway functionality to the current stack:

* New container `pushgateway` added to the compose file.

  <details>
  <summary>docker-compose.yml</summary>
  ```yml
  services:

  # PUSHGATEWAY FOR PROMETHEUS
  pushgateway:
    image: prom/pushgateway:v1.5.1
    container_name: pushgateway
    hostname: pushgateway
    restart: unless-stopped
    command:
      - '--web.enable-admin-api'    
    expose:
      - "9091"

  networks:
  default:
    name: $DOCKER_MY_NETWORK
    external: true
  ```
  </details>

* Adding pushgateway to the Caddyfile of the reverse proxy so that it can be reached at `https://push.example.com`<br>

  <details>
  <summary>Caddyfile</summary>
  ```php
  push.{$MY_DOMAIN} {
      reverse_proxy pushgateway:9091
  }
  ```
  </details>  

* Adding pushgateway's scrape point to `prometheus.yml`<br>

  <details>
  <summary>prometheus.yml</summary>
  ```yml
  global:
    scrape_interval:     15s
    evaluation_interval: 15s

  scrape_configs:
    - job_name: 'pushgateway-scrape'
      honor_labels: true
      static_configs:
        - targets: ['pushgateway:9091']
  ```
  </details>

## The basics

![veeam-dash](https://i.imgur.com/TOuv9bM.png)

To **test pushing** some metric, execute in linux:<br>
`echo "some_metric 3.14" | curl --data-binary @- https://push.example.com/metrics/job/blabla/instance/whatever`

You see **labels** being set to the pushed metric in the path.<br>
Label `job` is required, but after that it's whatever you want,
though use of `instance` label is customary.<br>
Now in grafana, in **Explore** section you should see some results
when quering for `some_metric`.

The metrics sit on the pushgateway **forever**, unless deleted or container
shuts down. Prometheus will not remove the metrics from it after scraping,
it will keep scraping the pushgateway and store the value there with the time of
scraping.

To wipe the pushgateway clean<br>
`curl -X PUT https://push.example.com/api/v1/admin/wipe`

More on pushgateway setup, with the real world use to monitor backups,
along with pushing metrics from windows in powershell - 
[**Veeam Prometheus Grafana**](https://github.com/DoTheEvo/veeam-prometheus-grafana)<br>

![veeam-dash](https://i.imgur.com/dUyzuyl.png)

---
---

# Alertmanager

To send a notification about some metric breaching some preset condition.<br>
Notifications chanels set here will be email and
[ntfy](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/gotify-ntfy-signal) 

![alert](https://i.imgur.com/b4hchSu.png)

## The setup

To add alertmanager to the current stack:

* New file - `alertmanager.yml` will be bind mounted in alertmanager container.<br>
  This file contains configuration on how and where to deliver alerts.<br>

  <details>
  <summary>alertmanager.yml</summary>
  ```yml
  route:
    receiver: 'email'

  receivers:
    - name: 'ntfy'
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

* New file - `alert.rules` will be mounted in to prometheus container<br>
  This file defines which value of some metric becomes an alert event.

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

* Changed `prometheus.yml`. Added `alerting` section that points to alertmanager
  container, and also set is a path to a `rules` file.

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

* New container - `alertmanager` added to the compose file and prometheus
  container has bind mount rules file added.

  <details>
    <summary>docker-compose.yml</summary>

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
        - '--storage.tsdb.retention.time=240h'
        - '--web.enable-lifecycle'
      volumes:
        - ./prometheus_data:/prometheus
        - ./prometheus.yml:/etc/prometheus/prometheus.yml
        - ./alert.rules:/etc/prometheus/rules/alert.rules
      expose:
        - "9090"
      labels:
        org.label-schema.group: "monitoring"

    # ALERT MANAGMENT FOR PROMETHEUS
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
        - "9093"
      labels:
        org.label-schema.group: "monitoring"

  networks:
    default:
      name: $DOCKER_MY_NETWORK
      external: true
  ```
  </details>

* Adding alertmanager to the Caddyfile of the reverse proxy so that it can be reached
  at `https://alert.example.com`. Not really necessary, but useful as it allows
  to send alerts from anywhere, not just from prometheus.

  <details>
  <summary>Caddyfile</summary>
  ```php
  alert.{$MY_DOMAIN} {
      reverse_proxy alertmanager:9093
  }
  ```
  </details>  

## The basics

![alert](https://i.imgur.com/C7g0xJt.png)


Once above setup is done an alert about low disk space should fire and notification
email should come.<br>
In `alertmanager.yml` switch from email to ntfy can be done.

*Useful*

* alert from anywhere using curl:<br>
  `curl -H 'Content-Type: application/json' -d '[{"labels":{"alertname":"blabla"}}]' https://alert.example.com/api/v1/alerts`
* reload rules:<br>
  `curl -X POST https://prom.example.com/-/reload`

[stefanprodan/dockprom](https://github.com/stefanprodan/dockprom#define-alerts)
has more detailed section on alerting worth checking out.    

# Loki

![loki_arch](https://i.imgur.com/aoMPrVV.png)

Loki is made by the grafana team. It's often refered as a Prometheus for logs.<br>
It is a **push** type monitoring, where an agent - **promtail**
pushes logs on to a Loki instance.<br>
For docker containers theres also an option to install **loki-docker-driver**
on a docker host and log pushing is set either globally in /etc/docker/daemon.json
or per container in compose files.

There will be **two examples**.<br>
A **minecraft server** and a **caddy revers proxy**, both docker containers.

## The setup

To add Loki to the current stack:

* New container - `loki` added to the compose file.<br>
  Note the port 3100 is actually mapped to the host,
  allowing `localhost:3100` from driver to work.

  <details>
  <summary>docker-compose.yml</summary>
  
  ```yml
  services:

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
        - "3100:3100"
      labels:
        org.label-schema.group: "monitoring"

  networks:
    default:
      name: $DOCKER_MY_NETWORK
      external: true
  ```
  </details>

* New file - `loki-docker-config.yml` bind mounted in the loki container.<br>
  The file comes from
  [the official example](https://github.com/grafana/loki/tree/main/cmd/loki),
  but url is changed, and compactor section is added, to have control over
  [data retention.](https://grafana.com/docs/loki/latest/operations/storage/retention/)

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

  compactor:
    working_directory: /loki/compactor
    compaction_interval: 10m
    retention_enabled: true
    retention_delete_delay: 2h
    retention_delete_worker_count: 150

  limits_config:
    retention_period: 240h

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

* Install [loki-docker-driver](https://grafana.com/docs/loki/latest/clients/docker-driver/)<br>
  `docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions`<br>
  To check if it's installed and enabled: `docker plugin ls`
* Containers that should be monitored need `logging` section in their compose.<br>

  <details>
  <summary>docker-compose.yml</summary>

  ```yml
  services:

    whoami:
      image: "containous/whoami"
      container_name: "whoami"
      hostname: "whoami"
      logging:
        driver: "loki"
        options:
          loki-url: "http://localhost:3100/loki/api/v1/push"
  ```
  </details>

## Minecraft example

Loki will be used to monitor logs of a [minecraft server.](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/minecraft)<br>
A dashboard will be created, showing logs volume in time.<br>
Alert will be set to send a notification when a player joins.<br>
  
**Requirements** - grafana, loki, loki-docker-driver, minecraft with logging
set in compose

![logo](https://i.imgur.com/M1k0Dn4.png)

### First steps

* In grafana, loki needs to be added as a datasource, `http://loki:3100`
* In `Explore` section, filter, container_name = minecraft, query... 
  this should result in seeing minecraft logs and their volume/time graph.

This Explore view will be recreated as a dashboard.

### Dashboard minecraft_logs

* New dashboard, new panel
  * Data source - Loki
  * Switch from `builder` to `code`<br>
  * query - `count_over_time({container_name="minecraft"} |= `` [1m])`<br>
  * Transform - Rename by regex - `(.*)` - `Logs`
  * Graph type - `Time series`
  * Title - Logs volume
  * Transparent background
  * Legend off
  * Graph styles - bar
  * Fill opacity - 50
  * Color scheme - single color
  * `Query options` - Min interval=1m
  * Save
* Add another pane to the dashboard
  * Graph type - `Logs`
  * Data source - Loki
  * Switch from `builder` to `code`<br>
    query - `{container_name="minecraft"} |= ""`<br>
  * Title - *empty*
  * Deduplication - Signature
  * Save

This should create a similar dashboard to the one in the picture above.<br>

[Performance tips](https://www.youtube.com/watch?v=YED8XIm0YPs)
for grafana loki queries 

### Alerts in Grafana for Loki

When a player joins minecraft server a log appears *"Bastard joined the game"*<br>
Alert will be set to look for string *"joined the game"* and send notification
when it occurs.

Grafana rules are based around a `Query` and `Expressions` and each 
and every one has to result in a a simple number or a true or false condition.

#### Create alert rule

- **1 Set an alert rule name**
  - Rule name = Minecraft-player-joined-alert
- **2 Set a query and alert condition**
  - **A** - Loki; Last 5 minutes
    - switch from builder to code
    - `count_over_time({compose_service="minecraft"} |= "joined the game" [5m])`
  - **B** - Reduce
    - Function = Last
    - Input = A
    - Mode = Strict
  - **C** - Treshold
    - Input = B
    - is above 0
    - Make this the alert condition
- **3 Alert evaluation behavior**
  - Folder = "Alerts"
  - Evaluation group (interval) = "five-min"<br>
  - Evaluation interval = 5m
  - For 0s
  - Configure no data and error handling
    - Alert state if no data or all values are null = OK
- **4 Add details for your alert rule**
  - Can pass values from logs to alerts, by targeting A/B/C/.. expressions
    from step2.
  - Summary = `Number of players: {{ $values.B }}`<br>
- **5 Notifications**
  - nothing
- Save and exit

#### Contact points

  - New contact point
  - Name = ntfy
  - Integration = Webhook
  - URL = https://ntfy.example.com/grafana
  - Disable resolved message = check
  - Test
  - Save

#### Notification policies

  - Edit default
  - Default contact point = ntfy
  - Save

After all this, there should be notification coming when a player joins.

`.*:\s(?P<player>.*)\sjoined the game$` - if ever I find out how to extract
string from a log like and pass it on to an alert.

# Caddy monitoring

Described in
[the caddy guide](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2)

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
