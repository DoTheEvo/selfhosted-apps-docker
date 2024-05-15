# Prometheus + Grafana + Loki in docker

###### guide-by-example

![logo](https://i.imgur.com/q41QfyI.png)

# Purpose

Monitoring of machines, containers, services, logs, ...

* [Official Prometheus](https://prometheus.io/)
* [Official Grafana](https://grafana.com/)
* [Official Loki](https://grafana.com/oss/loki/)

Monitoring in this case means gathering and showing information on how services
or machines or containers are running.<br>
Can be cpu, io, ram, disk use... can be number of http requests, errors,
results of backups, or a world map showing location of IP addresses
that access your services.<br>
Prometheus deals with **metrics**. Loki deals with **logs**.
Grafana is there to show the data on **dashboards**.

Most of the prometheus stuff here is based off the magnificent
[**stefanprodan/dockprom**.](https://github.com/stefanprodan/dockprom)

# Chapters

* **[Core prometheus+grafana](#Overview)** - nice dashboards with metrics of docker host and containers
* **[Pushgateway](#Pushgateway)** - push data to prometheus from anywhere
* **[Alertmanager](#Alertmanager)** - setting alerts and getting notifications
* **[Loki](#Loki)** - prometheus for logs
* **[Minecraft Loki example](#minecraft-loki-example)** - logs, grafana alerts
  and templates
* **[Caddy reverse proxy monitoring](#caddy-reverse-proxy-monitoring)** - 
  metrics, logs and geoip map

![dashboards_pic](https://i.imgur.com/ZmyP0T8.png)

# Overview

[Good youtube overview](https://youtu.be/h4Sl21AKiDg) of Prometheus.</br>

Prometheus is an open source system for monitoring and alerting,
written in golang.<br>
It periodically collects **metrics** from configured **targets**,
makes these metrics available for visualization, and can trigger **alerts**.<br>
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
         └── monitoring/
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
  Of note is 240 hours(10days) **retention** policy.
* **Grafana** - The official image used. Bind mounted directory
  for persistent data storage. User sets **as root**, as it solves issues I am
  lazy to investigate, likely me editing some files as root.
* **NodeExporter** - An exporter for linux machines,
  in this case gathering the **metrics** of the docker host,
  like uptime, cpu load, memory use, network bandwidth use, disk space,...<br>
  Also **bind mount** of some system directories to have access to required info.
* **cAdvisor** - An exporter for gathering docker **containers** metrics,
  showing cpu, memory, network use of **each container**<br>
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

Contains the bare minimum settings of targets from where metrics are to be pulled.

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

* Login **admin/admin** to `graf.example.com`, change the password.
* **Add** Prometheus as a **Data source** in Configuration<br>
  Set **URL** to `http://prometheus:9090`<br>
* **Import** dashboards from [json files in this repo](dashboards/)<br>

These **dashboards** are the preconfigured ones from
[stefanprodan/dockprom](https://github.com/stefanprodan/dockprom)
with **few changes**.<br>
**Docker host** dashboard did not show free disk space for me, **had to change fstype**
from `aufs` to `ext4`.
Also included is [a fix](https://github.com/stefanprodan/dockprom/issues/18#issuecomment-487023049)
for **host network monitoring** not showing traffick. In all of them
the default time interval is set to 1h instead of 15m

* **docker_host.json** - dashboard showing linux docker host metrics
* **docker_containers.json** - dashboard showing docker containers metrics,
  except the ones labeled as `monitoring` in the compose file
* **monitoring_services.json** - dashboar showing docker containers metrics
  of containers that are labeled `monitoring`

![interface-pic](https://i.imgur.com/wzwgBkp.png)

---
---

# PromQL basics

My understanding of this shit.. 

* Prometheus stores **metrics**, each metric has a name, like `cpu_temp`.
* the metrics values are stored as **time series**, just simple - timestamped values<br>
  `[43 @1684608467][41 @1684608567][48 @1684608667]`.
* This metric has **labels** `[name="server-19", state="idle", city="Frankfurt"]`.<br>
  These allow far better **targeting** of the data, or as they say **multidimensionality.**

**Queries** to retrieve metrics.

* `cpu_temp` - **simple query** will show values over whatever time period
is selected in the interface.
* `cpu_temp{state="idle"}` - will narrow down results by applying a **label**.<br>
  `cpu_temp{state="idle", name="server-19"}` - **multiple labels** narrow down results.

A query can return various **data type**, kinda tricky concept is difference between:

* **instant vector** - query returns a single value with a single timestamp.
  It is simple and intuitive. All the above examples are instant vectors.<br>
  Of note, there is **no thinking about time range here**. That is few layers above,
  if one picks last 1h or last 7 days... that plays no role here,
  this is a query response datatype and it is still instant vector - a single value in
  point of time.

* **range vector** - returns multiple values with a single timestamp<br>
  This is **needed by some [query functions](https://prometheus.io/docs/prometheus/latest/querying/functions)**
  but on its own useless.<br>
  A useless example would be `cpu_temp[10m]`. This query first looks at the last
  timestamp data, then it would take all data points within the previous 10m
  before that one timestamp, and return all those values.
  **This colletion would have a single timestamp.**<br>
  This functionality allows use of various **functions** that can do complex tasks.<br> 
  Actual useful example of a range vector would be `changes(cpu_temp[10m])`
  where the function
  [changes\(\)](https://prometheus.io/docs/prometheus/latest/querying/functions/#changes)
  would take that range vector info, look at those 10min of data and return 
  a single value, telling how many times the value of that metric changed in those 10 min.

Links

* [Stackoverflow - Prometheus instant vector vs range vector](https://stackoverflow.com/questions/68223824/prometheus-instant-vector-vs-range-vector)
* [The Anatomy of a PromQL Query](https://promlabs.com/blog/2020/06/18/the-anatomy-of-a-promql-query/)
* [Why are Prometheus queries hard?](https://fiberplane.com/blog/why-are-prometheus-queries-hard)
* [Prometheus Cheat Sheet - Basics \(Metrics, Labels, Time Series, Scraping\)](https://iximiuz.com/en/posts/prometheus-metrics-labels-time-series/)
* [Learning Prometheus and PromQL - Learning Series](https://iximiuz.com/en/series/learning-prometheus-and-promql/)
* [The official](https://prometheus.io/docs/prometheus/latest/querying/basics/)

</details>

---
---

# Pushgateway

Gives freedom to **push** information in to prometheus from **anywhere**.<br>

Be aware that it should **not be abused** to turn prometheus in to push type
monitoring. It is only intented for
[specific situations.](https://github.com/prometheus/pushgateway/blob/master/README.md)

### The setup

To **add** pushgateway functionality to the current stack:

* **New container** `pushgateway` added to the **compose** file.

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

* Adding pushgateway to the **Caddyfile** of the reverse proxy so that
  it can be reached at `https://push.example.com`<br>

  <details>
  <summary>Caddyfile</summary>

  ```php
  push.{$MY_DOMAIN} {
      reverse_proxy pushgateway:9091
  }
  ```
  </details>  

* Adding pushgateway as a **scrape point** to `prometheus.yml`<br>
  Of note is **honor_labels** set to true,
  which makes sure that **conflicting labels** like `job`, set during push
  are kept over labels set in `prometheus.yml` for the scrape job.
  [Docs](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#scrape_config).

  <details>
  <summary>prometheus.yml</summary>

  ```yml
  global:
    scrape_interval:     15s
    evaluation_interval: 15s

  scrape_configs:
    - job_name: 'pushgateway-scrape'
      scrape_interval: 60s
      honor_labels: true
      static_configs:
        - targets: ['pushgateway:9091']
  ```
  </details>

### The basics

![push-web](https://i.imgur.com/9Jk0HKu.png)

To **test pushing** some metric, execute in linux:<br>
  * `echo "some_metric 3.14" | curl --data-binary @- https://push.example.com/metrics/job/blabla/instance/whatever`
  * Visit `push.example.com` and see the metric there.
  * In Grafana > Explore > query for `some_metric` and see its value there.

In that command you see the metric itself: `some_metric` and it's value: `3.14`<br>
But there are also **labels** being set as part of the url. One label named `job`,
which is required, but after that it's whatever you want.
They just need to be in **pairs** - label name and label value.

The metrics sit on the pushgateway **forever**, unless deleted or container
shuts down. **Prometheus will not remove** the metrics **after scraping**,
it will keep scraping the pushgateway, every X seconds,
and store the value that sits there with the timestamp of scraping.

To **wipe** the pushgateway clean<br>
`curl -X PUT https://push.example.com/api/v1/admin/wipe`

### The real world use

* [**Veeam Prometheus Grafana**](https://github.com/DoTheEvo/veeam-prometheus-grafana) 

Linked above is a guide-by-example with more info on **pushgateway setup**.<br>
A real world use to **monitor backups**, along with pushing metrics
from **windows in powershell**.<br>

![veeam-dash](https://i.imgur.com/dUyzuyl.png)

---
---

# Alertmanager

To send a **notification** about some **metric** breaching some preset **condition**.<br>
Notifications channels used here are **email** and
[**ntfy**](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/gotify-ntfy-signal) 

*Note*<br>
I myself am **not** planning on using alertmanager. 
Grafana can do alerts for both logs and metrics.

![alert](https://i.imgur.com/b4hchSu.png)

## The setup

To **add** alertmanager to the current stack:

* **New file** - `alertmanager.yml` to be **bind mounted** in alertmanager container.<br>
  This is the **configuration** on how and where **to deliver** alerts.<br>
  Correct smtp or ntfy info needs to be filled out.

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

* **New file** - `alert.rules` to be **bind mounted** in to prometheus container<br>
  This file **defines** at what value a metric becomes an **alert** event.

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

* **Changed** `prometheus.yml`. Added **alerting section** that points to alertmanager
  container, and also **set path** to a `rules` file.

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

* **New container** - `alertmanager` added to the compose file and **prometheus
  container** has bind mount **rules file** added.

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
      user: root
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

* **Adding** alertmanager to the **Caddyfile** of the reverse proxy so that
  it can be reached at `https://alert.example.com`. **Not necessary**,
  but useful as it **allows to send alerts from anywhere**,
  not just from prometheus, or other containers on same docker network.

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


Once above setup is done, **an alert** about low disk space **should fire**
and a **notification** email should come.<br>
In `alertmanager.yml` a switch from email **to ntfy** can be done.

*Useful*

* **alert** from anywhere using **curl**:<br>
  `curl -H 'Content-Type: application/json' -d '[{"labels":{"alertname":"blabla"}}]' https://alert.example.com/api/v1/alerts`
* **reload rules**:<br>
  `curl -X POST https://prom.example.com/-/reload`

[stefanprodan/dockprom](https://github.com/stefanprodan/dockprom#define-alerts)
has more detailed section on alerting worth checking out.    

---
---

![Loki-logo](https://i.imgur.com/HUohN3P.png)

# Loki

Loki is a log aggregation tool, made by the grafana team.
Sometimes called a Prometheus for logs, it's a **push** type monitoring.<br>

It uses [LogQL](https://promcon.io/2019-munich/slides/lt1-08_logql-in-5-minutes.pdf)
for queries, which is similar to PromQL in its use of labels.

[The official documentation overview](https://grafana.com/docs/loki/latest/fundamentals/overview/)

There are two ways to **push logs** to Loki from a docker container.

  * [**Loki-docker-driver**](https://grafana.com/docs/loki/latest/clients/docker-driver/)
    **installed** on a docker host and log pushing is set either globally in
    `/etc/docker/daemon.json` or per container in compose files.<br>
    It's the simpler, easier way, but **lacks fine control** over the logs
    being pushed.
  * **[Promtail](https://grafana.com/docs/loki/latest/clients/promtail/)**
    deployed as an another **container**, with bind mount of logs it should scrape,
    and bind mount of its config file. This config file is very powerful,
    giving a lot of **control** how logs are processed and pushed.

![loki_arch](https://i.imgur.com/aoMPrVV.png)

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
      image: grafana/loki:main-0295fd4
      container_name: loki
      hostname: loki
      user: root
      restart: unless-stopped
      volumes:
        - ./loki_data:/loki
        - ./loki-config.yml:/etc/loki-config.yml
      command:
        - '-config.file=/etc/loki-config.yml'
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

* **New file** - `loki-config.yml` bind mounted in the loki container.<br>
  The config here comes from
  [the official example](https://github.com/grafana/loki/tree/main/cmd/loki)
  with some changes.
    * **URL** changed for this setup.
    * **Compactor** section is added, to have control over
      [data retention.](https://grafana.com/docs/loki/latest/operations/storage/retention/)
    * **Fixing** error - *"too many outstanding requests"*, discussion
      [here.](https://github.com/grafana/loki/issues/5123)<br>
      It turns off parallelism, both split by time interval and shards split.

  <details>
  <summary>loki-config.yml</summary>

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

  # --- disable splitting to fix "too many outstanding requests"

  query_range:
    parallelise_shardable_queries: false

  # ---  compactor to have control over length of data retention

  compactor:
    working_directory: /loki/compactor
    compaction_interval: 10m
    retention_enabled: true
    retention_delete_delay: 2h
    retention_delete_worker_count: 150

  limits_config:
    retention_period: 240h
    split_queries_by_interval: 0  # part of disable splitting fix

  # -------------------------------------------------------

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

#### First Loki use in Grafana

* In **grafana**, loki needs to be added as a **datasource**, `http://loki:3100`
* In **Explore section**, switch to Loki as source
  * if loki-docker-driver then filter by `container_name` or `compose_project`
  * if promtail then filter by job name set in promtail config
    in the labels section

If all was set correctly logs should be visible in Grafana.

![query](https://i.imgur.com/XSevjIR.png)

# Minecraft Loki example

What can be seen in this example:

* How to monitor logs of a docker container,
  a [minecraft server](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/minecraft).
* How to visualize the logs in a dashboard.
* How to set an alert when a specific pattern appears in the logs.
* How to extract information from log to include it in the alert notification.
* Basics of grafana alert templates, so that notifications actually look good,
  and show only relevant info.

**Requirements** - grafana, loki, minecraft.

![logo-minecraft](https://i.imgur.com/VphJTKG.png)

### The objective and overview

The **main objective** is to get an **alert** when a player **joins** the server.<br>
The secondary one is to have a place where recent *"happening"* on the server
can be seen.

Initially **loki-docker-driver** was used to get logs to Loki, and it was simple
and worked nicely. But during alert stage
I **could not** figure out how to extract string from logs and include it in
an **alert** notification. Specificly to not just say that "a player joined",
but to have there name of the player that joined.<br>
**Switch to promtail** solved this, with the use of its 
[pipeline_stages](https://grafana.com/docs/loki/latest/clients/promtail/pipelines/).
Which was **suprisingly simple** and elegant.

### The Setup

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
          expression: .*:\s(?P<player>.*)\sjoined the game$
      - labels:
          player:
```
</details>

[Here's regex101](https://regex101.com/r/5vkOU2/1) of it,
with some data to show how it works and bit of explanation.<br>
[Here's](https://stackoverflow.com/a/74962269/1383369)
the stackoverflow answer that is the source for that config.

![regex](https://i.imgur.com/bT5XSHn.png)

### In Grafana

* If Loki is not yet added, it needs to be added as a **datasource**, `http://loki:3100`
* In **Explore section**, filter, job = `minecraft_logs`, **Run query** button... 
  this should result in seeing minecraft logs and their volume/time graph.

This Explore view will be **recreated** as a dashboard.

### Dashboard for minecraft logs

![dashboard-minecraft](https://i.imgur.com/M1k0Dn4.png)

* **New dashboard, new panel**
  * Graph type - `Time series`
  * Data source - Loki
  * Switch from `builder` to `code`<br>
  * query - `count_over_time({job="minecraft_logs"} |= `` [1m])`<br>
  * `Query options` - Min interval=1m
  * Transform - Rename by regex
    Match - `(.*)`
    Replace - `Logs`
  * Title - Logs volume
  * Transparent background
  * Legend off
  * Graph styles - bar
  * Fill opacity - 50
  * Color scheme - single color
  * Save
* **Add another panel**
  * Graph type - `Logs`
  * Data source - Loki
  * Switch from `builder` to `code`<br>
    query - `{job="minecraft_logs"} |= ""`<br>
  * Title - *empty*
  * Deduplication - Signature or Exact
  * Save

This should create a similar dashboard to the one in the picture above.<br>

[Performance tips](https://www.youtube.com/watch?v=YED8XIm0YPs)
for grafana loki queries 

## Alerts in Grafana for Loki

![alert-labels](https://i.imgur.com/LuUBZFn.png)

When a **player joins** minecraft server a **log line** appears *"Bastard joined the game"*<br>
An **Alert** will be set to detect string *"joined the game"* and send
a **notification** when it occurs.

Now, might be good time to **brush up on PromQL / LogQL** and the **data types**
they return when a query happens. That **instant vector** and **range vector**
thingie. As grafana will scream when using range vector.

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
  - URL = `https://ntfy.example.com/grafana`<br>
    or if grafana-to-ntfy is already setup then `http://grafana-to-ntfy:8080`<br>
    but also credentials need to be set.
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

For **alerts** one can use 
[ntfy](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/gotify-ntfy-signal)
but on its own alerts from grafana are **just plain text json**.<br>
[Here's](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/gotify-ntfy-signal#grafana-to-ntfy)
how to setup grafana-to-ntfy, to **make alerts look good**.

![ntfy](https://i.imgur.com/gL81jRg.png)

---
---

### Templates

Not really used here, but **they are pain** and there's some info
as it took **embarrassingly** long to find that
`{{ .CommonAnnotations.summary }}` for the title.

* **Testing** should be done in **contact point** when editing,
  useful **Test button** that allows you to send alerts with custom values.
* To [define a template.](https://i.imgur.com/vYPO7yd.png)
* To [call a template.](https://i.imgur.com/w3Sb6fF.png)
* My **big mistake** when playing with this was **missing a dot**.<br>
  In Contact point, in Title/Message input box. 
  * correct one - `{{ template "test" . }}`
  * the one I had - `{{ template "test" }}`<br>
* So yeah, **dot** is important in here. It represents **data and context** 
  passed to a template. It can represent **global context**, or when used inside
  `{{ range }}` it represents **iteration** loop value.
* [This](https://pastebin.com/id3264k6) json structure is what an **alert** looks
  like. Notice `alerts` being an **array** and `commonAnnotations` being **object**.
  For **array** theres need to **loop** over it to get access to the
  values in it. For **objects** one just needs to target **the name**
  from global context.. **using dot** at the beginning.
* To [iterate over alerts array.](https://i.imgur.com/yKmZLLQ.png)
* To just access a value - `{{ .CommonAnnotations.summary }}`
* Then theres **conditional** things one can do in **golang templates**,
  but I am not going to dig that deep... 

Templates resources

* [Overview of Grafana Alerting and Message Templating for Slack](https://faun.pub/overview-of-grafana-alerting-and-message-templating-for-slack-6bb740ec44af)
* [youtube - Unified Alerting Grafana 8 | Prometheus | Victoria | Telegraf | Notifications | Alert Templating](https://youtu.be/UtmmhLraSnE)
* [Dot notation](https://www.practical-go-lessons.com/chap-32-templates#dot-notation)
* [video - Annotations and Alerts tutorial for Grafana with Timescale](https://youtu.be/bmOkirtC65w)

---
---

# Caddy reverse proxy monitoring

What can be seen in this example:

* Use of **Prometheus** to monitor a docker **container** - 
  [caddy](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy).
* How to **import a dashobard** to grafana.
* Use of **Loki** to monitor **logs** of a docker **container**.
* How to set **Promtail** to push only certain values and label logs.
* How to use **geoip** part of **Promtail**.
* How to create **dashboard** in grafana from data in **Loki**.

**Requirements** - grafana, loki, caddy.

![logo-caddy](https://i.imgur.com/rB6sjKQ.png)

**Reverse proxy** is kinda linchpin of a selfhosted setup as it is **in charge**
of all the http/https **traffic** that goes in. So focus on monitoring this
**keystone** makes sense.

**Requirements** - grafana, prometheus, loki, caddy container

## Caddy - Metrics - Prometheus

![logo](https://i.imgur.com/6QdZuVR.png)

**Caddy** has build in **exporter** of metrics for prometheus, so all that is needed
is enabling it, **scrape it** by prometheus, and import a **dashboard**.

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
  Likely **not necessary** if Caddy and Prometheus are on the **same docker network**,
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

* Edit **prometheus.yml** to add caddy **scraping** point

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

* In grafana **import**
  [caddy dashboard](https://grafana.com/grafana/dashboards/14280-caddy-exporter/)<br>
  
But these **metrics** are about **performance** and **load** put on Caddy,
which in selfhosted environment will **likely be minimal** and not interesting.<br>
To get **more intriguing** info of who, when, **from where**, connects
to what **service**,.. well for that monitoring of **access logs** is needed.

---
---

## Caddy - Logs - Loki

![logs_dash](https://i.imgur.com/j9CcJ44.png)

**Loki** itself just **stores** the logs. To get them to Loki a **Promtail** container is used
that has **access** to caddy's **logs**. Its job is to **scrape** them regularly, maybe
**process** them in some way, and then **push** them to Loki.<br>
Once there, a basic grafana **dashboard** can be made.


### The setup

* Have Grafana, Loki, Caddy working
* Edit Caddy **compose**, bind mount `/var/log/caddy`.<br>
  **Add** to the compose also **Promtail container**, that has the same logs bind mount,
  along with bind mount of its **config file**.<br>
  Promtail will scrape logs to which it now has access and **pushes** them **to Loki.**
  
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

* **Promtail** scrapes a logs, **one line** at the time and is able to do **neat
  things** with it before sending it - add labels, ignore some lines,
  only send some values,...<br>
  [Pipelines](https://grafana.com/docs/loki/latest/clients/promtail/pipelines/)
  are used for this.
  Bellow is an example of extracting just a single value - an IP address
  and using it in a tempalte that gets send to Loki and nothing else.
  [Here's](https://zerokspot.com/weblog/2023/01/25/testing-promtail-pipelines/)
  some more to read on this.

  <details>
  <summary>promtail-config.yml customizing fields</summary>

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

      pipeline_stages:
        - json:
            expressions:
              request_remote_ip: request.remote_ip
        - template:
            source: output  # creates empty output variable
            template: '{"remote_ip": {{.request_remote_ip}}}'
        - output:
            source: output

  ```
  </details>

* Edit `Caddyfile` to enable 
  [**access logs**](https://caddyserver.com/docs/caddyfile/directives/log).
  Unfortunately this **can't be globally** enabled, so the easiest way seems to be 
  to create a **logging** [**snippet**](https://caddyserver.com/docs/caddyfile/concepts#snippets)
  called `log_common` and copy paste the **import line** in to every site block.

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
  
* at this points logs should be visible and **explorable in grafana**<br>
  Explore > `{job="caddy_access_log"} |= "" | json`

### Geoip

![geoip_info](https://i.imgur.com/f4P8ydl.png)

**Promtail** got recently a **geoip stage**. One can feed it an **IP address** and an mmdb **geoIP 
database** and it adds geoip **labels** to the log entry.

[The official documentation.](https://github.com/grafana/loki/blob/main/docs/sources/clients/promtail/stages/geoip.md)

* **Register** a free account on [maxmind.com](https://www.maxmind.com/en/geolite2/signup).
* **Download** one of the mmdb format **databases**
  * `GeoLite2 City` - 70MB full geoip info - city, postal code, time zone, latitude/longitude,..
  * `GeoLite2 Country` 6MB, just country and continent
* **Bind mount** whichever database in to **promtail container**.

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
        - ./GeoLite2-City.mmdb:/etc/GeoLite2-City.mmdb:ro
      command:
        - '-config.file=/etc/promtail-config.yml'

  networks:
    default:
      name: $DOCKER_MY_NETWORK
      external: true
  ```

* In **promtail** config, **json stage** is added where IP address is loaded in to
  a **variable** called `remote_ip`, which then is used in **geoip stage**.
  If all else is set correctly, the geoip **labels** are automaticly added to the log entry.

  <details>
  <summary>geoip promtail-config.yml</summary>

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

      pipeline_stages:
        - json:
            expressions:
              remote_ip: request.remote_ip

        - geoip:
            db: "/etc/GeoLite2-City.mmdb"
            source: remote_ip
            db_type: "city"
  ```
  </details>

Can be tested with opera build in VPN, or some online 
[site tester](https://pagespeed.web.dev/).

### Dashboard

![panel1](https://i.imgur.com/hW92sLO.png)

* **new panel**, will be **time series** graph showing **Subdomains hits timeline**

  * Graph type = Time series
  * Data source = Loki
  * switch from builder to code<br>
    `sum(count_over_time({job="caddy_access_log"} |= "" | json [1m])) by (request_host)`
  * Query options > Min interval = 1m
  * Transform > Rename by regex 
    * Match = `\{request_host="(.*)"\}`
    * Replace = `$1`
  * Title = "Subdomains hits timeline"
  * Transparent
  * Tooltip mode = All
  * Tooltip values sort order = Descending
  * Legen Placement = Right
  * Value = Total
  * Graph style = Bars
  * Fill opacity = 50

![panel2](https://i.imgur.com/KYZdotg.png)

* Add **another panel**, will be a **pie chart**, showing **subdomains** divide

  * Graph type = Pie chart
  * Data source = Loki
  * switch from builder to code<br>
    `sum(count_over_time({job="caddy_access_log"} |= "" | json [$__range])) by (request_host)`
  * Query options > Min interval = 1m
  * Transform > Rename by regex
    * Match = `\{request_host="(.*)"\}`
    * Replace = `$1`
  * Title = "Subdomains divide"
  * Transparent
  * Legend Placement = Right
  * Value = Last

![panel3](https://i.imgur.com/MjbLVlJ.png)

* Add **another panel**, will be a **Geomap**, showing location of machine accessing
  Caddy

  * Graph type = Geomap
  * Data source = Loki
  * switch from builder to code<br>
    `{job="caddy_access_log"} |= "" | json`
  * Query options > Min interval = 1m
  * Transform > Extract fields
    * Source = labels
    * Format = JSON
    * 1. Field = `geoip_location_latitude`; Alias = `latitude`
    * 2. Field = `geoip_location_longitude`; Alias = `longitude`
  * Title = "Geomap"
  * Transparent
  * Map view > View > *Drag and zoom around* > Use current map setting

* Add **another panel**, will be a **pie chart**, showing **IPs** that hit the most

  * Graph type = Pie chart
  * Data source = Loki
  * switch from builder to code<br>
    `sum(count_over_time({job="caddy_access_log"} |= "" | json [$__range])) by (request_remote_ip)`
  * Query options > Min interval = 1m
  * Transform > Rename by regex
    * Match = `\{request_remote_ip="(.*)"\}`
    * Replace = `$1`
  * Title = "IPs by number of requests"
  * Transparent
  * Legen Placement = Right
  * Value = Last or Total
  
* Add **another panel**, this will be actual **log view**

  * Graph type - Logs
  * Data source - Loki
  * Switch from builder to code
  * query - `{job="caddy_access_log"} |= "" | json`
  * Title - empty
  * Deduplication - Exact or Signature
  * Save

![panel3](https://i.imgur.com/bzE6JEg.png)


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

* down the containers `docker-compose down`</br>
* delete the entire monitoring directory</br>
* from the backup copy back the monitoring directory</br>
* start the containers `docker-compose up -d`
