# Frigate

###### guide-by-example

![logo](https://i.imgur.com/40qhwix.png)

WORK IN PROGRESS<br>
WORK IN PROGRESS<br>
WORK IN PROGRESS<br>

# Purpose & Overview


Managing security cameras - recording, detection, notifications.

* [Official site](https://frigate.video/)
* [Github](https://github.com/blakeblackshear/frigate)

Frigate is a software NVR - network video recorder.<br>
Simple, clean web-based interface with possible integration in to home assistant
and its app.

Frigate offers powerful **AI object detection**, by using OpenCV and Tensorflow.
In contrast to cameras of old time which just detect movement,
Frigate can recognize if object in view is a cat, a car or a human.

This detection is cpu heavy and to ease the load,
[Google Coral TPU](https://docs.frigate.video/frigate/hardware#google-coral-tpu)
is recommended if planning to run multiple cameras with detection.<br>
Recently 
[OpenVINO](https://docs.frigate.video/configuration/detectors/#openvino-detector)
has been integrated, which should allow use of igpu of intel 6th+ gen cpus
as a detector.

Open source, written in Python and JavaScript.

# Files and directory structure

```
/home/
└── ~/
    └── docker/
        └── frigate/
            ├── 🗁 frigate_storage/
            ├── 🗋 .env
            ├── 🗋 config.yml
            └── 🗋 docker-compose.yml
```

* `frigate_storage/` - storage for frigate database, and video recordings
* `config.yml` - main frigate config file
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the containers

You only need to provide the three files.</br>
The directory is created by docker compose on the first run.

# docker-compose

* [Official compose file documentation.](https://docs.frigate.video/frigate/installation/#docker)

This docker compose is based off the official one except few changes.<br>
Using bind mounts instead of volumes, moved variables to the `.env` file,
commented out privileged mode, increased shm_size,...

Of note is use of `tmpfs` for ram temp storage
and [shm_size](https://docs.frigate.video/frigate/installation/#calculating-required-shm-size).

`docker-compose.yml`
```yml
services:

  frigate:
    image: ghcr.io/blakeblackshear/frigate:stable
    container_name: frigate
    hostname: frigate
    restart: unless-stopped
    env_file: .env
    # privileged: true
    shm_size: "256mb"
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ./config.yml:/config/config.yml
      - ./frigate_storage:/media/frigate
      - type: tmpfs # 1GB of memory
        target: /tmp/cache
        tmpfs:
          size: 1000000000
    ports:
      - "5000:5000" # Web GUI
      - "8554:8554" # RTSP feeds
      - "8555:8555/tcp" # WebRTC over tcp
      - "8555:8555/udp" # WebRTC over udp

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

# FRIGATE
FRIGATE_RTSP_USER: "admin"
FRIGATE_RTSP_PASSWORD: "dontlookatmekameras"
```

**All containers must be on the same network**.</br>
Which is named in the `.env` file.</br>
If one does not exist yet: `docker network create caddy_net`

# Reverse proxy

Caddy is used, details
[here](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/caddy_v2).</br>

`Caddyfile`
```
cam.{$MY_DOMAIN} {
    reverse_proxy frigate:5000
}
```

# Configuration - config.yml

<summary><h3>Terminology</h3></summary>

* PoE - power over ethernet, camera is powered by the same cat cable that
  carries data. You want POE(802.3af) or POE+(802.3at),
  none of the passive poe by mikrotik or ubiquity.
* onvif - attempt at industry standard for security cameras, nvr,.. regardless of manufacturer
* rtsp - a protocol for streams
* ptz - Pan-Tilt-Zoom allows remote movement of a camera
* mqtt - messaging protocol to communicate with home assistant

### Preparation 

Connect camera to your network.

Find url of your camera streams, either by googling your model, 
or theres a handy windows utility - 
[onvif-device-manager](https://sourceforge.net/projects/onvifdm/).
Unfortunately all official urls seem dead,
[this](https://softradar.com/onvif-device-manager/)
worked for me and passed virustotal at the time. There are also comments
with some links at its sourceforge page.<br>
Camera discovery of onvif-device-manager is almost instant, if the camera requires 
credentials, set them in the top left corner.<br>
In live view there should be stream url displayed. Like: "rtsp://10.0.19.171:554/stream1"

Ideally your camera has several streams
A primary one in full resolution full frame rate for recording,
and then secondary one in much smaller resolution and fps for observing.

### First basic config

* [Official documentation for config.yml](https://docs.frigate.video/configuration/)
* [Some youtube video on config adjustment](https://youtu.be/gRCtvRsTHm0)

Example bare config that should shows camera stream once frigate is running.<br>
This one has credentails contained in the url - `rtsp://username:password@ip:port/url`


```yml
mqtt:
  enabled: false
cameras:
  C1-Whatever:
    ffmpeg:
      inputs:
        - path: rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@10.0.19.171:554/stream1
```

All that is there is disabled mqtt since no home assistant yet
and just single camera stream that pulls credentails from the `.env` file.

---

Now to also record main stream and detect on substream.


```yml
mqtt:
  enabled: false
detectors:
  default_detector_for_all:
    type: cpu
objects:
  track:
    - person
    - cat
    - dog
cameras:
  K1-Brana:
    ffmpeg:
      inputs:
        - path: rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@10.0.19.171:554/stream1
          roles:
            - record
        - path: rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@10.0.19.171:554/stream2
          roles:
            - detect
    detect:
      width: 640
      height: 480
      fps: 5
    snapshots:
      enabled: True
      bounding_box: True
    record:
      enabled: True
      retain:
        days: 1
    motion:
        mask:
          - 0,480,186,480,174,226,173,0,0,0
```

### Current full config

Got a tplink camara C440 and some rando aliexpress ptz camera

```
mqtt:
  enabled: false
detectors:
  default_detector_for_all:
    type: cpu
objects:
  track:
    - person
    - cat
    - dog
  filters:
    cat:
      min_area: 200
      threshold: 0.5
cameras:
  K1-Brana:
    ffmpeg:
      inputs:
        - path: rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@10.0.19.41:554/stream1
          roles:
            - record
        - path: rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@10.0.19.41:554/stream2
          roles:
            - detect
    detect:
      width: 640
      height: 480
      fps: 5
    snapshots:
      enabled: True
      bounding_box: True
    record:
      enabled: True
      retain:
        days: 1
    motion:
        mask:
          - 0,480,186,480,174,226,173,0,0,0

  K2-Pergola:
    ffmpeg:
      inputs:
        - path: rtsp://10.0.19.42:554/0/av1
          roles:
            - record
        - path: rtsp://10.0.19.42:554/0/av1
          roles:
            - detect
    detect:
      width: 640
      height: 352
      fps: 8
    snapshots:
      enabled: True
      bounding_box: True
    record:
      enabled: True
      retain:
        days: 1

# Include all cameras by default in Birdseye view
birdseye:
  enabled: True
  mode: continuous
```

# First run




# Specifics of my setup



# Troubleshooting




# Update

Manual image update:

- `docker-compose pull`</br>
- `docker-compose up -d`</br>
- `docker image prune`

# Backup and restore

#### Backup

#### Restore

