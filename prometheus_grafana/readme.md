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

![dashboards_pic](https://i.imgur.com/ac9Qj1F.png)

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

# PromQL

Some concept, highlights and examples of PromQL.

PromQL returns results as vectors"

* [The official](https://prometheus.io/docs/prometheus/latest/querying/basics/) basics page, quite to the point and short
* [Introduction to PromQL](https://blog.knoldus.com/introduction-to-promql/)
* [relatively short video to the point](https://youtu.be/yLPTHinHB6Y)
* [Prometheus Cheat Sheet - How to Join Multiple Metrics](https://iximiuz.com/en/posts/prometheus-vector-matching/)
* [decent stackoverflow answer](https://stackoverflow.com/questions/68223824/prometheus-instant-vector-vs-range-vector)


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
it will keep scraping the pushgateway and store the value with the time of
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

Loki is made by the grafana team. Sometimes called a Prometheus for logs,
it's a **push** type monitoring, where an agent - **promtail**
scrapes logs and then pushes them on to a Loki instance.<br>

For docker containers theres also an option to install
[**loki-docker-driver**](https://grafana.com/docs/loki/latest/clients/docker-driver/)
on a docker host and log pushing is set either globally in /etc/docker/daemon.json
or per container in compose files.<br>
But as it turns out, **promtail** capabilities might be missed,
like its ability to add labels to logs it scrapes based on some rule.
Or processing data in some way, like translate IP addresses in to country
names or cities.<br>
Still loki-docker-driver is useful for getting containers logs in to loki
quickly and easily, with less cluttering of compose and less containers runnig.

There will be **two examples** of logs monitoring.<br>
A **minecraft server** and a **caddy revers proxy**, both docker containers.

## Loki setup

* **New container** - `loki` added to the compose file.<br>
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

* **New file** - `loki-docker-config.yml` bind mounted in the loki container.<br>
  The file comes from
  [the official example](https://github.com/grafana/loki/tree/main/cmd/loki),
  but url is changed, and **compactor** section is added, to have control over
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

* #### loki-docker-driverdriver

  * **Install** [loki-docker-driver](https://grafana.com/docs/loki/latest/clients/docker-driver/)<br>
    `docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions`<br>
    To check if it's installed and enabled: `docker plugin ls`<br>
  * Containers that should be monitored usind loki-docker-driver need
   `logging` section in their compose.

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

* #### promtail

  * Containers that should be monitored with **promtail** need it **added**
    **to** their **compose** file, and made sure that it has access to the log files.

    <details>
    <summary>minecraft-docker-compose.yml</summary>

    ```yml
    services:

      minecraft:
        image: itzg/minecraft-server
        container_name: minecraft
        hostname: minecraft
        restart: unless-stopped
        env_file: .env
        tty: true
        stdin_open: true
        ports:
          - 25565:25565     # minecraft server players connect
        volumes:
          - ./minecraft_data:/data

      # LOG AGENT PUSHING LOGS TO LOKI
      promtail:
        image: grafana/promtail
        container_name: minecraft-promtail
        hostname: minecraft-promtail
        restart: unless-stopped
        volumes:
          - ./minecraft_data/logs:/var/log/minecraft:ro
          - ./promtail-config.yml:/etc/promtail-config.yml
        command:
          - '-config.file=/etc/promtail-config.yml'

    networks:
      default:
        name: $DOCKER_MY_NETWORK
        external: true
    ```
    </details>

    <details>
    <summary>caddy-docker-compose.yml</summary>

    ```yml
    services:

      caddy:
        image: caddy
        container_name: caddy
        hostname: caddy
        restart: unless-stopped
        env_file: .env
        ports:
          - "80:80"
          - "443:443"
          - "443:443/udp"
        volumes:
          - ./Caddyfile:/etc/caddy/Caddyfile
          - ./caddy_config:/data
          - ./caddy_data:/config
          - ./caddy_logs:/var/log/caddy

      # LOG AGENT PUSHING LOGS TO LOKI
      promtail:
        image: grafana/promtail
        container_name: caddy-promtail
        hostname: caddy-promtail
        restart: unless-stopped
        volumes:
          - ./caddy_logs:/var/log/caddy:ro
          - ./promtail-config.yml:/etc/promtail-config.yml
        command:
          - '-config.file=/etc/promtail-config.yml'

    networks:
      default:
        name: $DOCKER_MY_NETWORK
        external: true

    ```
    </details>

  * Generic **config file for promtail**, needs to be bind mounted 

    <details>
    <summary>promtail-config.yml</summary>

    ```yml
    clients:
      - url: http://loki:3100/loki/api/v1/push

    scrape_configs:
      - job_name: blablabla
        static_configs:
          - targets:
              - localhost
            labels:
              job: blablabla_log
              __path__: /var/log/blablabla/*.log
    ```
    </details>

# Minecraft Loki example

What can be seen in this example:

* How to monitor logs of a docker container,
  a [minecraft server](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/minecraft).
* How to visualize the logs in a dashboard.
* How to set an alert when a specific pattern appears in the logs.
* How to extract information from log to include it in the alert notification.
* Basic of grafana alert templates, so that the notification actually looks good,
  and shows only relevant info.

**Requirements** - grafana, loki, minecraft.

![logo-minecraft](https://i.imgur.com/VphJTKG.png)

### The Setup

Initially **loki-docker-driver was used** to get logs to Loki, and it was simple
and worked nicely. But during alert stage
I **could not** figure out how to extract string from logs and include it in
an **alert** notification. Specificly to not just say that "a player joined",
but to have there name of the player that joined.<br>
The way to solve that was to **switch to promtail** and make use of its 
[pipeline_stages](https://grafana.com/docs/loki/latest/clients/promtail/pipelines/).
Which was **suprisingly simple** and elegant.

**Promtail** container is added to minecraft's **compose**, with bind mount
access to minecraf's logs.<br>

<details>
<summary>minecraft-docker-compose.yml</summary>

```yml
services:

  minecraft:
    image: itzg/minecraft-server
    container_name: minecraft
    hostname: minecraft
    restart: unless-stopped
    env_file: .env
    tty: true
    stdin_open: true
    ports:
      - 25565:25565     # minecraft server players connect
    volumes:
      - ./minecraft_data:/data

  # LOG AGENT PUSHING LOGS TO LOKI
  promtail:
    image: grafana/promtail
    container_name: minecraft-promtail
    hostname: minecraft-promtail
    restart: unless-stopped
    volumes:
      - ./minecraft_data/logs:/var/log/minecraft:ro
      - ./promtail-config.yml:/etc/promtail-config.yml
    command:
      - '-config.file=/etc/promtail-config.yml'

networks:
  default:
    name: $DOCKER_MY_NETWORK
    external: true
```
</details>

**Promtail's config** is similar to the generic config in the previous section.<br>
The only addition is a short **pipeline** stage with a **regex** that runs against 
every log line before sending it to Loki. When a line matches, **a label** `player`
is added to that log line.
The value of that label comes from the **named capture group** thats part of 
that regex, the [syntax](https://www.regular-expressions.info/named.html)
is: `(?P<name>group)`<br>
This label will be easy to use later in the alert stage.

<details>
<summary>promtail-config.yml</summary>

```yml
clients:
  - url: http://loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: minecraft
    static_configs:
      - targets:
          - localhost
        labels:
          job: minecraft_logs
          __path__: /var/log/minecraft/*.log
    pipeline_stages:
    - regex:
        expression: '.*:\s(?P<player>.*)\sjoined the game$'
    - labels:
        player:
```
</details>

[Here's regex101](https://regex101.com/r/5vkOU2/1) of it,
with some data to show how it works and bit of explanation.<br>
[Here's](https://stackoverflow.com/a/74962269/1383369)
the stackoverflow answer that is the source for that config.

![regex](https://i.imgur.com/bT5XSHn.png)

### First steps in Grafana

* In grafana, loki needs to be added as a datasource, `http://loki:3100`
* In `Explore` section, filter, job = minecraft_logs, Run query button... 
  this should result in seeing minecraft logs and their volume/time graph.

This Explore view will be recreated as a dashboard.

### Dashboard minecraft_logs

![dashboard-minecraft](https://i.imgur.com/M1k0Dn4.png)

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

## Alerts in Grafana for Loki

![alert-labels](https://i.imgur.com/LuUBZFn.png)

When a player joins minecraft server a log appears *"Bastard joined the game"*<br>
Alert will be set to look for string *"joined the game"* and send notification
when it occurs.

At this point might be good time to brush up on promQL/logQL and the data types
they return when a query happens. That instant vector and range vector thingie.

### Create alert rule

- **1 Set an alert rule name**
  - Rule name = Minecraft-player-joined-alert
- **2 Set a query and alert condition**
  - **A** - Switch to Loki; set Last 5 minutes
    - switch from builder to code
    - `count_over_time({job="minecraft_logs"} |= "joined the game" [5m])`
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
  - Here is where the label `player` that was set in **promtail** is used<br>
    Summary = `{{ $labels.player  }} joined the Minecraft server.`
  - Can also pass values from expressions by targeting A/B/C/.. from step2<br>
    Description = `Number of players that joined in the last 5 min: {{ $values.B }}`<br>
- **5 Notifications**
  - nothing
- Save and exit

### Contact points 

  - New contact point
  - Name = ntfy
  - Integration = Webhook
  - URL = https://ntfy.example.com/grafana
  - Title = `{{ .CommonAnnotations.summary }}`
  - Message = I put in [empty space unicode character](https://emptycharacter.com/)
  - Disable resolved message = check
  - Test
  - Save

### Notification policies

  - Edit default
  - Default contact point = ntfy
  - Save

After all this, there should be notification coming when a player joins.

### grafana-to-ntfy

For alerts one can use 
[ntfy](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/gotify-ntfy-signal)
but on its own the alerts from grafana are just plain text json.<br>
[Here's](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/gotify-ntfy-signal#grafana-to-ntfy)
how to setup grafana-to-ntfy, to make the alerts look good.

![ntfy](https://i.imgur.com/gL81jRg.png)

---
---

### Templates

Not really used here, but they are pain in the ass and I got some info
as it took me embarrassingly long to find that
`{{ .CommonAnnotations.summary }}` for the title.

* Testing should be done in contact point when editing,
  useful Test button that allows you send alerts with custom values.
* To [define a template.](https://i.imgur.com/ZczwCx2.png)
* To [call a template.](https://i.imgur.com/0YdWA8Q.png)
* My big mistake when playing with this was missing a dot.<br>
  In Contact point, in Title/Message input box. 
  * correct one - `{{ template "test" . }}`
  * the one I had - `{{ template "test" }}`<br>
* So yeah, dot is important in here. It represents data and context 
  passed to a template. It can represent global context or when used inside
  `{{ range }}` it represents iteration loop value.
* [This](https://pastebin.com/id3264k6) json structure is what an alert looks
  like. Notice `alerts` being an array and `commonAnnotations` being object.
  If something is an array, theres need to loop over it to get access to the
  values in it. For objects one just needs to target the value
  from global context.. using dot at the beginning.
* To [iterate over alerts array.](https://i.imgur.com/gdwGhjN.png)
* To just access a value - `{{ .CommonAnnotations.summary }}`

Templates resources

* [Overview of Grafana Alerting and Message Templating for Slack](https://faun.pub/overview-of-grafana-alerting-and-message-templating-for-slack-6bb740ec44af)
* [youtube - Unified Alerting Grafana 8 | Prometheus | Victoria | Telegraf | Notifications | Alert Templating](https://youtu.be/UtmmhLraSnE)
* [Dot notation](https://www.practical-go-lessons.com/chap-32-templates#dot-notation)
* 

---
---

# Caddy reverse proxy monitoring

What can be seen in this example:

* Use of Prometheus to monitor a docker container - 
  [caddy](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy).
* How to import a dashobard to grafana.
* Use of Loki to monitor logs of a docker container.
* How to set promtail to push only certain values and label them.
* Create dashboard in grafana from data in Loki.

**Requirements** - grafana, loki, caddy.

![logo-minecraft](https://i.imgur.com/HU4kHCj.png)

Reverse proxy is kinda linchpin of a selfhosted setup as it is in charge
of all the http/https traffic that goes in. So focus on monitoring this
keystone makes sense.

**Requirements** - grafana, prometheus, loki, caddy container

## Metrics - Prometheus

![logo](https://i.imgur.com/6QdZuVR.png)

Caddy has build in exporter of metrics for prometheus, so all that is needed
is enabling it, scrape it by prometheus, and import a dashboard.

* Edit Caddyfile to [enable metrics.](https://caddyserver.com/docs/metrics)

  <details>
  <summary>Caddyfile</summary>

  ```php
  {
      servers {
          metrics
      }

      admin 0.0.0.0:2019
  }


  a.{$MY_DOMAIN} {
      reverse_proxy whoami:80
  }
  ```
  </details>

* Edit compose to publish 2019 port.<br>
  Likely not necessary if Caddy and Prometheus are on the same docker network,
  but its nice to check if the metrics export works at `<docker-host-ip>:2019/metrics`

  <details>
  <summary>docker-compose.yml</summary>

  ```yml
  services:

    caddy:
      image: caddy
      container_name: caddy
      hostname: caddy
      restart: unless-stopped
      env_file: .env
      ports:
        - "80:80"
        - "443:443"
        - "443:443/udp"
        - "2019:2019"
      volumes:
        - ./Caddyfile:/etc/caddy/Caddyfile
        - ./caddy_config:/data
        - ./caddy_data:/config

  networks:
    default:
      name: $DOCKER_MY_NETWORK
      external: true
  ```
  </details>

* Edit prometheus.yml to add caddy scraping point

  <details>
  <summary>prometheus.yml</summary>

  ```yml
  global:
    scrape_interval:     15s
    evaluation_interval: 15s

  scrape_configs:
    - job_name: 'caddy'
      static_configs:
        - targets: ['caddy:2019']
  ```
  </details>

* In grafana import [caddy dashboard](https://grafana.com/grafana/dashboards/14280-caddy-exporter/)<br>
  or make your own, `caddy_reverse_proxy_upstreams_healthy` shows reverse proxy
  upstreams, but thats all.

But these metrics are more about performance and load put on Caddy,
which in selfhosted enviroment will likely be minmal and not interesting.<br>
To get more intriguing info of who, when, from where, connects to what service,.. 
for that acces logs monitoring is needed.

---
---

## Logs - Loki

Loki itself just stores the logs, to get logs a promtail container is used
that has access to caddy's logs. Its job is to scrape them regularly, maybe
process them in some way, and then push them to Loki.<br>
Once there, a basic grafana dashboard can be made.

![logs_dash](https://i.imgur.com/lWToTMd.png)

### The setup

* Have Grafana, Loki, Caddy working
* Edit Caddy compose, bind mount `/var/log/caddy`.<br>
  Add to the compose also Promtail container, that has the same logs bind mount,
  along with bind mount of its config file.<br>
  Promtail will scrape logs to which it now has access and pushes them to Loki.
  
  <details>
  <summary>docker-compose.yml</summary>

  ```yml
  services:

    caddy:
      image: caddy
      container_name: caddy
      hostname: caddy
      restart: unless-stopped
      env_file: .env
      ports:
        - "80:80"
        - "443:443"
        - "443:443/udp"
        - "2019:2019"
      volumes:
        - ./Caddyfile:/etc/caddy/Caddyfile
        - ./caddy_data:/data
        - ./caddy_config:/config
        - ./caddy_logs:/var/log/caddy

    # LOG AGENT PUSHING LOGS TO LOKI
    promtail:
      image: grafana/promtail
      container_name: caddy-promtail
      hostname: caddy-promtail
      restart: unless-stopped
      volumes:
        - ./promtail-config.yml:/etc/promtail-config.yml
        - ./caddy_logs:/var/log/caddy:ro
      command:
        - '-config.file=/etc/promtail-config.yml'

  networks:
    default:
      name: $DOCKER_MY_NETWORK
      external: true
  ```
  </details>

  <details>
  <summary>promtail-config.yml</summary>

  ```yml
  clients:
    - url: http://loki:3100/loki/api/v1/push

  scrape_configs:
    - job_name: caddy_access_log
      static_configs:
        - targets:
            - localhost
          labels:
            job: caddy_access_log
            host: example.com
            agent: caddy-promtail
            __path__: /var/log/caddy/*.log
  ```
  </details>

* If one would desire to customize what gets pushed by promtail,
  [here's](https://zerokspot.com/weblog/2023/01/25/testing-promtail-pipelines/)
  something to read and config derived from it.

  <details>
  <summary>promtail-config.yml customizing fields</summary>

  ```yml
  clients:
    - url: http://loki:3100/loki/api/v1/push

  scrape_configs:
    - job_name: caddy_access_log
      static_configs:
      - targets: # tells promtail to look for the logs on the current machine/host
          - localhost
        labels:
          job: caddy_access_log
          __path__: /var/log/caddy/*.log
      pipeline_stages:
        # Extract all the fields I care about from the
        # message:
        - json:
            expressions:
              "level": "level"
              "timestamp": "ts"
              "duration": "duration"
              "response_status": "status"
              "request_path": "request.uri"
              "request_method": "request.method"
              "request_host": "request.host"
              "request_useragent": "request.headers.\"User-Agent\""
              "request_remote_ip": "request.remote_ip"

        # Promote the level into an actual label:
        - labels:
            level:

        # Regenerate the message as all the fields listed
        # above:
        - template:
            # This is a field that doesn't exist yet, so it will be created
            source: "output"
            template: |
                          {{toJson (unset (unset (unset . "Entry") "timestamp") "filename")}}
        - output:
            source: output

        # Set the timestamp of the log entry to what's in the
        # timestamp field.
        - timestamp:
            source: "timestamp"
            format: "Unix"
  ```
  </details>

* Edit `Caddyfile` to enable [access logs](https://caddyserver.com/docs/caddyfile/directives/log).
  Unfortunetly this can't be globally enabled, so the easiest way seems to be 
  to create a logging [snippet](https://caddyserver.com/docs/caddyfile/concepts#snippets)
  and copy paste import line in to every site block.

  <details>
  <summary>Caddyfile</summary>

  ```yml
  (log_common) {
    log {
      output file /var/log/caddy/caddy_access.log
    }
  }

  ntfy.example.com {
    import log_common
    reverse_proxy ntfy:80
  }

  mealie.{$MY_DOMAIN} {
    import log_common
    reverse_proxy mealie:80
  }
  ```
  </details>
  
* at this points logs should be visible and explorable in grafana<br>
  Explore > `{job="caddy_access_log"} |= "" | json`

## dashboard

* new pane, will be time series graph showing logs volume in time

  * Data source = Loki
  * switch from builder to code<br>
    `sum(count_over_time({job="caddy_access_log"} |= "" | json [1m])) by (request_host)`
  * Transform > Rename by regex > Match = `\{request_host="(.*)"\}`; Replace = $1
  * Query options > Min interval = 1m
  * Graph type = Time series
  * Title = "Access timeline"
  * Transparent
  * Tooltip mode = All
  * Tooltip values sort order = Descending
  * Legen Placement = Right
  * Value = Total
  * Graph style = Bars
  * Fill opacity = 50

* Add another pane, will be a pie chart, showing subdomains divide

  * Data source = Loki
  * switch from builder to code<br>
    `sum(count_over_time({job="caddy_access_log"} |= "" | json [$__range])) by (request_host)`
  * Transform > Rename by regex > Match = `\{request_host="(.*)"\}`; Replace = $1
  * Graph type = Pie chart
  * Title = "Subdomains divide"
  * Transparent
  * Legen Placement = Right
  * Value = Total
  * Graph style = Bars

  
* Add another pane, this will be actual log view

  * Graph type - Logs
  * Data source - Loki
  * Switch from builder to code
  * query - `{job="caddy_access_log"} |= "" | json`
  * Title - empty
  * Deduplication - Signature
  * Save

useful resources

* https://www.youtube.com/watch?v=UtmmhLraSnE

## Geoip

[to-do](https://github.com/grafana/loki/blob/main/docs/sources/clients/promtail/stages/geoip.md)

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
