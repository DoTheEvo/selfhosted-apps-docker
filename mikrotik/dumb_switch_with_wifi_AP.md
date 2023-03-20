# Dumb switch with wifi AP

## Objective

* every single port bridged, device acting like a switch
* wifi being bridged to the same network
* automatic IP assigned
* no DHCP, no NAT, no nothing, just like a dumb switch with wifi thats all

## Steps

Clear any config 

* System > Reset Configuration > No Default Configuration

---

**Bridge**

* Bridge > add bridge1
* Ports > add > All interfaces to bridge1

*winbox will reconnect*

---

**IP**

*dynamic*

* IP > DHCP client > add > interface bridge, rest defaults

*static*

* IP > Addresses > add > 
* Address - 192.168.88.2/24
* Network - it gets filled out automatically on ok/apply based on subnet mask in address 
* interface - bridge

---

2ghz

* Wireless > open 2ghz interface > Wireless tab > click Advanced Mode > in this tab
* change Mode from station to ap bridge
* change Band to 2Ghz- B/G/N
* Channel Width stay at 20Mhz if lot of wifi around you, go to 40Mhz if not
* Frequency - pick a channel \[1-2412 ; 6-2437; 11-2462\]
* SSID - pick a name
* Radio Name - if you you want to distingush between APs with same SSID?
* Skip DFS channels - all
* Security Profile - just make note of the one set there, should be default
* WPS mode - disable
* Country - pick yours

-------------

5ghz

* Wireless > open 5ghz interface > Wireless tab > click Advanced Mode > in this tab
* change Mode from station to ap bridge
* change Band to 5Ghz- N/AC
* Channel Width 20/40/80Mhz XXXX
* Frequency - auto?
* SSID - pick a name
* Radio Name - if you you want to distingush between APs with same SSID?
* Skip DFS channels - all
* Security Profile - just make note of the one set there, should be default
* WPS mode - disable
* Country - pick yours

---------------

security

* Wireless > Security Profiles > default
* change Mode to dynamic keys
* check WPA PSK and WPA2 PSK
* set passwords in WPA/WPA2 pre-shared key inputs

------------
