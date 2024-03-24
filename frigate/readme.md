# Frigate

###### guide-by-example

![logo](https://i.imgur.com/cPBDFxi.png)

# Purpose & Overview

![frigate_web_gui](https://i.imgur.com/q1zSyVZ.jpeg)

Managing security cameras - recording, detection, notifications.

* [Official site](https://frigate.video/)
* [Github](https://github.com/blakeblackshear/frigate)

Frigate is a software **NVR** - network video recorder.<br>
Simple, clean web-based interface with possible integration in to home assistant
and its app.

Open source, written in Python and JavaScript.

---

#### Object detection

Frigate offers powerful **AI object detection**, by using OpenCV and Tensorflow.
In contrast to cameras of old which just detected movement,
Frigate can recognize in realtime if object in view moving is a cat, a car, or a human.

[Detectors](https://docs.frigate.video/configuration/object_detectors) - There
are several ways to run the deep learning models for the object detection.

This guide will use cpu at first and then **OpenVINO** intel igpu detector.<br>
But do not have too high expectations. False positives are plenty, especially
when shadows are present. Cutting down on false possitives requires plenty
of playing with the configuration, trials and errors.

---

<details>
<summary><b><font size="+1">Terminology</font></b></summary>

* **NVR** - network video recorder, often a box with disks and build-in poe switch for cameras
* **PoE** - Power over ethernet, camera is powered by the same cat cable that
  carries data. You want POE(802.3af) or POE+(802.3at),
  none of the passive poe by mikrotik or ubiquity.
* **IR** - infrared light for night vision, attracts bugs that see it,
  reflects off walls or shiny surfaces, loss of color information
* **onvif** - It's a forum. It strives to maintain an industry standard
  that allows stuff from different manufacturers to work.
* **rtsp** - a protocol for controling remotely cameras and streaming
* **ptz** - Pan-Tilt-Zoom allows remote movement of a camera
* **IoT** - Internet of Things
* **mqtt** - Messaging protocol widely used in IoT.
  [Youtube playlist about it.](https://www.youtube.com/playlist?list=PLRkdoPznE1EMXLW6XoYLGd4uUaB6wB0wd)

</details>

---
---


### To consider...

Is it worth investing time and hardware?

Modern commercial camera systems offer similar AI aided objects 
detection, while maintaining the configurability. Phone apps are also often
far better.<br>
Meanwhile Frigate lacks even proper ptz control.
One should view it as a few people hobby project on github,
though exceptionally well done.

An NVR, for example Dahua `DHI-NVR2108HS-8P-S3` costs less than 200€,
and it comes with **POE for 8 cameras**.<br>
It might be worth considering to just get an NVR that you lock out of
the internet with VLANs or firewall rules... than buying a separate PC for
Frigate and a separate poe switch to keep the 24/7 cameras traffic away from your
main LAN and Coral TPU... and whatnot.

On the other hand, setting Frigate up provides knowledge and the feeling of
being more in control, with more flexibility, when it does not tie you
to a manufacturer and the hardware used can be repurposed at any time.

# Cameras choice

![cameras_pic](https://i.imgur.com/7BQbmPr.png)


[Frigate got a page for that.](https://docs.frigate.video/frigate/hardware/)

My opinion

* **Dahua** - If you got decent budget, they have good stuff and very rich configuration.
  Going for that 1/1.8" sensor for good low light performance with IR being off,
  though dont expect magic.
* **TP-Link** are the cameras I am actually playing with, cheap 4MP.<br>
  No issues with them. Followed frigates
  [brand specific configuration](https://docs.frigate.video/configuration/camera_specific/#tp-link-vigi-cameras)
  which says to **switch all streams to H264** and **turn off Smart Coding**.

  * [VIGI C440](https://www.tp-link.com/my/business-networking/vigi-network-camera/vigi-c440/)
    \- A fuckup as its an interior camera and I did not notice when ordering.
    It's stil outside as it's not directly on elements, survived one winter so far.
  * [VIGI C240](https://www.tp-link.com/ae/business-networking/vigi-network-camera/vigi-c240/) 
    \- Cheap and outdoor, enough settings to feel fine.
    It actually decently see at night without IR, but you realize its kinda lie
    as if something moves there its a smudge at best or invisible predator at worst.
  * Some random aliexpress camera given to me, it has ptz.

Once I am running frigate and cameras for some real time... more than a year,
I will decide which cameras to get long term.

# Files and directory structure

```
/mnt/
└── 🗁 frigate_hdd/
|   └── 🗁 frigate_media/
|
/home/
└── ~/
    └── docker/
        └── frigate/
            ├── 🗁 frigate_config/
            |    └── 🗋 config.yml
            ├── 🗋 .env
            └── 🗋 docker-compose.yml
```

* `frigate_media/` - storage for frigate recordings and jpg snapshots
* `frigate_config/` - config and database directory
* `config.yml` - main frigate config file
* `.env` - a file containing environment variables for docker compose
* `docker-compose.yml` - a docker compose file, telling docker how to run the containers

You need to create `frigate_config` directory which gets mounted in to the container,
and in to it place `config.yml`.</br>
`frigate_media` directory should be placed on a **HDD** drive. As nonstop writes
would exhaust an ssd lifespan. If a NAS would be used it would be eating
in to your LAN bandwith and NAS I/O with constant 24/7 traffic that cameras generate.<br>
If recording **just detected events** then I guess those other options are viable.

# docker-compose

* [Official compose file documentation.](https://docs.frigate.video/frigate/installation/#docker)

This docker compose is based off the official one except for few changes.<br>
Using **bind mounts** instead of volumes, moved variables to the **`.env` file**.<br>
Increased [shm_size](https://docs.frigate.video/frigate/installation/#calculating-required-shm-size)
which is a preset max **ram** for interprocess communication of the container.<br>
**Privileged** mode is used, which allows access to the
[gpu stats](https://docs.frigate.video/configuration/hardware_acceleration/#configuring-intel-gpu-stats-in-docker)
and avoids issue with access to recordings and having to deal with permissions.

For hwaccel support theres **devices section** with renderD128 mapped in to the container.
Check the `/dev/dri/` path to see what you got there.<br>
The section can be deleted if planning to use just the cpu.
Or [adjusted](https://docs.frigate.video/frigate/installation/#docker) for colar or pcie gpu.

`docker-compose.yml`
```yml
services:

  frigate:
    image: ghcr.io/blakeblackshear/frigate:0.13.2
    container_name: frigate
    hostname: frigate
    restart: unless-stopped
    env_file: .env
    privileged: true
    shm_size: "256mb"
    devices:
      - /dev/dri/renderD128 # for intel hwaccel, needs to be updated for your hardware
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ./frigate_config:/config
      - /mnt/frigate_hdd/frigate_media:/media/frigate
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
FRIGATE_RTSP_USER=admin
FRIGATE_RTSP_PASSWORD=dontlookatmekameras
# FRIGATE_MQTT_USER=
# FRIGATE_MQTT_PASSWORD=
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

To allow traffic **only from LAN** to have access to your Frigate.

`Caddyfile`
```
(LAN_only) {
  @fuck_off_world {
    not remote_ip private_ranges
  }
  respond @fuck_off_world 403
}

cam.{$MY_DOMAIN} {
  import LAN_only
  reverse_proxy frigate:5000
}
```
# Frigate UI overview 

![system_pic](https://i.imgur.com/mm7e8jZ.png)

Simple and clean, but few pointers can help.

* **Cameras** - Managing cameras, see recordings, events.
* **Birdview** - Live view from cameras, maybe set bookmark here.
* **Events** - All past events, from all cameras.
* **Storage** - Great info on storage used and statistics how much is used per hour.
* **System** - Great info on cpu and ram usage, can also do ffprobe per camera.
* **Config** - Can edit config right here, no need to ssh.
* **Logs** - Logs since last restart.

# Configuration

Configuration is done through singular file `config.yml`<br>
Here we be in small steps adding to it, making sure stuff works
before moving to a next thing.
As dumping full `config.yml` is just too much for first time running.

* [Official documentation for config.yml](https://docs.frigate.video/configuration/)
* [Official full reference config](https://docs.frigate.video/configuration/reference)
* [Some youtube video on config adjustment](https://youtu.be/gRCtvRsTHm0)

### Preparation 

Connect a camera to your network.

Find url of your camera streams, either by googling your model, 
or theres a handy windows utility - 
[**onvif-device-manager**](https://sourceforge.net/projects/onvifdm/).
Unfortunately all official urls seem dead,
[this](https://softradar.com/onvif-device-manager/)
worked for me and passed virustotal at the time. There are also comments
with some links at its sourceforge page.<br>
Camera discovery of onvif-device-manager works great. If the camera requires 
credentials, set them in the top left corner.<br>
In live view there should be stream url displayed. Like: "rtsp://10.0.19.41:554/stream1"

Ideally your camera has several streams.
A primary one in full resolution full frame rate for recording,
and then secondary one in much smaller resolution and fps for observing.

![config_pic](https://i.imgur.com/Z7fQjb0.png)

### First config - one camera

Bare config that should show camera stream once frigate is running.<br>
Credentails are contained in the url - `rtsp://username:password@ip:port/url`

Disabled mqtt since no communication with home assistant or anything else.
And a single camera stream that pulls credentials you set in the `.env` file.

`config-1.yml`
```yml
mqtt:
  enabled: false
cameras:
  K1-Gate:
    ffmpeg:
      inputs:
        - path: rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@10.0.19.41:554/stream1
```

---

### Second config - detection, recording, two cameras

<details>
<summary><b><font size="+1">config-2.yml</font></b></summary>

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

record:
  enabled: true
  retain:
    days: 60
    mode: all
  events:
    retain:
      default: 360
      mode: motion

snapshots:
  enabled: true
  bounding_box: true
  crop: true
  retain:
    default: 360

birdseye:
  mode: continuous

cameras:
  K1-Gate:
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
    motion:
      mask:
        - 640,480,640,0,0,0,0,480,316,480,308,439,179,422,162,121,302,114,497,480

  K2-Pergola:
    ffmpeg:
      inputs:
        - path: rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@10.0.19.42:554/stream1
          roles:
            - record
        - path: rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@10.0.19.42:554/stream2
          roles:
            - detect
    detect:
      width: 640
      height: 480
      fps: 5
    motion:
      mask:
        - 640,78,640,0,0,0,0,480,316,480,452,171
```

</details>

---
---

If a camera is runnig and stream can be viewed, it's time to move to 
core NVR functions like recording and basic detection.

Settings in root of the config file, **global** - applicable for all cameras:

* `detectors` - Could be omitted as the default is the cpu,
  but its good to have this explicitly stated and  ready
  as most people will be switching to non-cpu detection.
* `objects` - What the detector will be looking for.
  Later on this config can grow as more specific parameters are added.
* `record` - Globally enabled record and set retention time on all cameras.
* `snapshots` - If jpg pictures of detect events should be made and some of its options.
* `birdseye` - Webgui section where one can see current view of all cameras.
  It's enabled by default, but the default mode being `objects` means
  it only shows cameras that detected something in the last 30s.
  So it is switched to `continuous` mode.

In **per camera** section:

* `roles` - Added lower resolution stream and roles define which to record
  and which to use for detection.
* `detect` - Section defines resolution and fps for detect job, you want it to match
  what camera is sending. This can be often [set directly on a camera](https://i.imgur.com/ifis9zH.png).
  You can then check if its respected with `onvif-device-manager` in its
  [profile section](https://i.imgur.com/1H6RZiO.png),
  or in Frigate > System > [FFPROBE](https://i.imgur.com/IBhlKNt.png)
* `Motion mask` - Defines which parts of the view to ignore. Watch the [youtube 
  video](https://youtu.be/gRCtvRsTHm0?t=705).

You might wanna run the 2nd config for a day or two to see how it behaves.

---

### Third config - intel openvino and hardware acceleration

<details>
<summary><b><font size="+1">config-3.yml</font></b></summary>

```yml
mqtt:
  enabled: false

detectors:
  ov:
    type: openvino
    device: AUTO
    model:
      path: /openvino-model/ssdlite_mobilenet_v2.xml

model:
  width: 300
  height: 300
  input_tensor: nhwc
  input_pixel_format: bgr
  labelmap_path: /openvino-model/coco_91cl_bkgr.txt

ffmpeg:
  hwaccel_args: preset-vaapi

detect:
  max_disappeared: 2500

objects:
  track:
    - person
    - cat
    - dog

record:
  enabled: true
  retain:
    days: 60
    mode: all
  events:
    retain:
      default: 360
      mode: motion

snapshots:
  enabled: true
  bounding_box: true
  crop: true
  retain:
    default: 360

birdseye:
  mode: continuous

cameras:
  K1-Gate:
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
    motion:
      mask:
        - 640,480,640,0,0,0,0,480,316,480,308,439,179,422,162,121,302,114,497,480

  K2-Pergola:
    ffmpeg:
      inputs:
        - path: rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@10.0.19.42:554/stream1
          roles:
            - record
        - path: rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@10.0.19.42:554/stream2
          roles:
            - detect
    detect:
      width: 640
      height: 480
      fps: 5
    motion:
      mask:
        - 640,78,640,0,0,0,0,480,316,480,452,171
```

</details>

---
---

Only two changes in the 3rd config.

* Detector is switched from the cpu to intel igpu using openvino.<br>
  Just copy/paste from [the official documentation.](https://docs.frigate.video/configuration/object_detectors/#openvino-detector)
* [Hardware acceleration](https://docs.frigate.video/configuration/hardware_acceleration/)
  is enabled for ffmpeg, using vaapi.<br>
  It's globaly set for all streams by just two lines in the config.

The first time I switched to hwaccl and igpu openvino detection I had daily freezes.
I was ready to tackle it based on some
[github disscussion,](https://github.com/blakeblackshear/frigate/issues/8470#issuecomment-1823556062)
but once I started from scratch with latest version I had no more freezes.

---

### Fourth config - notifications with mqtt and ntfy

![mqtt_pic](https://i.imgur.com/TyhAaCH.png)

Time for push **notifications** about events happenig in front of cameras.<br>
I use **ntfy** and the first result when googling for "frigate ntfy" is
[this guide.](https://beneaththeradar.blog/frigate-portainer-and-notifications-using-ntfy/)
It works so that is what will be used.<br>

The idea is:

* An event worthy of notification happens.
* Frigate sends mqtt to the mqtt broker - EMQX.
* EMQX receives it and has a [webhook](https://www.emqx.io/docs/en/latest/dashboard/bridge.html)
  set for your ntfy instance.
* ntfy receives it and sends push notification to your phone/browser with snapshot of detection.

EMQX had a major interface changes since version used in the guide,
but as I was unable to make it work...
the *"older"* version will be used, which was relased Nov 30, 2023.

#### 1. Have ntfy working

[ntfy guide here.](https://github.com/DoTheEvo/selfhosted-apps-docker/tree/master/gotify-ntfy-signal)<br>
I run without authentification on ntfy.

#### 2. Edit the compose, adding emqx container

EMQX default login is `admin` / `public` and its webgui is  on port `18083` <br>
For some reason EMQX needs to be run as root or it does not have
access to its own folder set to be bindmounted.

<details>
<summary>docker-compose.yml</summary>

```yml
services:

  frigate:
    image: ghcr.io/blakeblackshear/frigate:0.13.2
    container_name: frigate
    hostname: frigate
    restart: unless-stopped
    env_file: .env
    privileged: true
    shm_size: "256mb"
    devices:
      - /dev/dri/renderD128 # for intel hwaccel, needs to be updated for your hardware
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ./frigate_config:/config
      - /mnt/frigate_hdd/frigate_media:/media/frigate
      - type: tmpfs # 1GB of memory
        target: /tmp/cache
        tmpfs:
          size: 1000000000
    ports:
      - "5000:5000" # Web GUI
      - "8554:8554" # RTSP feeds
      - "8555:8555/tcp" # WebRTC over tcp
      - "8555:8555/udp" # WebRTC over udp

  emqx:
    image: emqx/emqx:5.3.2
    container_name: emqx
    hostname: frigate
    restart: unless-stopped
    env_file: .env
    user: root
    volumes:
      - ./emqx_data:/opt/emqx/data
    ports:
      - 1883:1883
      - 8083:8083
      - 8084:8084
      - 8883:8883
      - 18083:18083 # Web GUI

networks:
  default:
    name: $DOCKER_MY_NETWORK
    external: true

```
</details>

#### 3. Edit the Frigate's config.yml

All that is done in this **fourth config** version is enabling mqtt.
Set IP address and port of the mqtt broker.
If your broker has authentification, set `FRIGATE_MQTT_USER` and
`FRIGATE_MQTT_PASSWORD` in the `.env` file.

<details>
<summary><b><font size="+1">config-4.yml</font></b></summary>

```yml
mqtt:
  enabled: true
  host: 10.0.19.40
  port: 1883

detectors:
  ov:
    type: openvino
    device: AUTO
    model:
      path: /openvino-model/ssdlite_mobilenet_v2.xml

model:
  width: 300
  height: 300
  input_tensor: nhwc
  input_pixel_format: bgr
  labelmap_path: /openvino-model/coco_91cl_bkgr.txt

ffmpeg:
  hwaccel_args: preset-vaapi

detect:
  max_disappeared: 2500

objects:
  track:
    - person
    - cat
    - dog

record:
  enabled: true
  retain:
    days: 60
    mode: all
  events:
    retain:
      default: 360
      mode: motion

snapshots:
  enabled: true
  bounding_box: true
  crop: true
  retain:
    default: 360

birdseye:
  mode: continuous

cameras:
  K1-Gate:
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
    motion:
      mask:
        - 640,480,640,0,0,0,0,480,316,480,308,439,179,422,162,121,302,114,497,480

  K2-Pergola:
    ffmpeg:
      inputs:
        - path: rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@10.0.19.42:554/stream1
          roles:
            - record
        - path: rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@10.0.19.42:554/stream2
          roles:
            - detect
    detect:
      width: 640
      height: 480
      fps: 5
    motion:
      mask:
        - 640,78,640,0,0,0,0,480,316,480,452,171
```

</details>

#### 4. Follow emqx -> ntfy guide

[The guide](https://beneaththeradar.blog/frigate-portainer-and-notifications-using-ntfy/)

* Login to emqx at the \<ip\>:18083
* Integration > Data Bridges > Create > HTTP Server
* Name - `frigate-ntfy`
* Method - `POST`
* URL - `https://ntfy.example.com/frigate`
* Key
  * `content-type` - `application/json`
  * `Actions` - `view, Picture, https://cam.example.com/api/events/${id}/snapshot.jpg, clear=true;view, Video, https://cam.example.com/api/events/${id}/clip.mp4, clear=true;`
  * `Attach` - `https://cam.example.com/api/events/${id}/thumbnail.jpg?format=android`
  * `Tags` - `camera_flash`
  * `Title` - `Motion Detected`
* Body - `${message}`

Obviously change all the instances of the `cam.example.com` and `ntfy.example.com`
to whatever you got going.

[Picture](https://i.imgur.com/SbohgYI.png) from the guide, this setup skips
Authentification.<br>
Test conectivity, it should be successful, then Create.
A question pops up Would you like to create a rule using this data bridge?
You do so - create.

```
SELECT
  payload.after.id as id, payload.after.label + ' detected on ' + payload.after.camera as message
FROM
  "frigate/events"
WHERE
  payload.type='new' and payload.after.has_snapshot = true and payload.after.has_clip = true
```

---
 
# My current config

<details>
<summary><b><font size="+1">current_config.yml</font></b></summary>

```
mqtt:
  enabled: true
  host: 10.0.19.40
  port: 1883

detectors:
  ov:
    type: openvino
    device: AUTO
    model:
      path: /openvino-model/ssdlite_mobilenet_v2.xml

model:
  width: 300
  height: 300
  input_tensor: nhwc
  input_pixel_format: bgr
  labelmap_path: /openvino-model/coco_91cl_bkgr.txt

ffmpeg:
  hwaccel_args: preset-vaapi

detect:
  max_disappeared: 2500

objects:
  track:
    - person
    - cat
    - dog
    - sheep
  filters:
    person:
      min_area: 1000
      threshold: 0.82

record:
  enabled: true
  retain:
    days: 60
    mode: all
  events:
    retain:
      default: 360
      mode: motion

snapshots:
  enabled: true
  bounding_box: true
  crop: true
  retain:
    default: 360

birdseye:
  mode: continuous

cameras:
  K1-Gate:
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
    motion:
      mask:
        - 640,480,640,0,0,0,0,480,316,480,308,439,179,422,162,121,302,114,497,480

  K2-Pergola:
    ffmpeg:
      inputs:
        - path: rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@10.0.19.42:554/stream1
          roles:
            - record
        - path: rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@10.0.19.42:554/stream2
          roles:
            - detect
    detect:
      width: 640
      height: 480
      fps: 5
    objects:
      filters:
        cat:
          min_score: 0.3
          threshold: 0.5
    motion:
      mask:
        - 640,78,640,0,0,0,0,480,316,480,452,171

  K3-Dvor:
    birdseye:
      order: 3
    ffmpeg:
      inputs:
        - path: rtsp://10.0.19.43:554/0/av1
          roles:
            - record
        - path: rtsp://10.0.19.43:554/0/av1
          roles:
            - detect
    detect:
      width: 640
      height: 352
      fps: 8
    motion:
        mask:
          - 0,37,179,30,174,0,0,0
          - 591,108,570,0,640,0,640,352,344,352
```

</details>

---
---

Not much different from the 4th config at this moment.<br>

* person detection threshold increased globaly
* cat detection treshold and [min_score](https://github.com/blakeblackshear/frigate/issues/6795#issuecomment-1591076029)
  decreased for the 2nd camera, testing phase
* 3rd crappy ptz camera is present

# Update

Manual image update:

- `docker-compose pull`</br>
- `docker-compose up -d`</br>
- `docker image prune`
