# Windows Package Managers

###### guide-by-example

# Purpose & Overview

Install and manage software on windows through command line.

* winget
* chocolatey
* scoop


# Winget

`winget search irfanview`
`winget install irfanview`

\+ Comes preinstalled with windows 10+<br>
\- Feels like unmanaged afterthought

# Scoop

### User

* non-admin powershell terminal
* `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`
* `irm get.scoop.sh | iex`
* `scoop install git sudo`
* `scoop bucket add extras`
* `scoop bucket add sysinternals`
* `scoop bucket add nonportable`

### Machine-wide

* admin powershell terminal
* `Set-ExecutionPolicy Bypass`
* `iex "& {$(irm get.scoop.sh)} -RunAsAdmin"`
* `scoop install git sudo --global`
* `scoop bucket add extras`
* `scoop bucket add sysinternals`
* `scoop bucket add nonportable`

### Useful

* search - `scoop search mpv`
* `scoop install mpv --global`
* search for avaialble pacakges - [scoop.sh](https://scoop.sh/)

# Choco

`Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))`


