# Data Sources Used by HamClock-ng

This document inventories all the external data (APIs, backends, files) that
HamClock or its modules fetch or depend on.

Where possible, include:
- URL or protocol
- What it is used for
- Whether it is currently functional
- Notes on replacement alternatives

---

## 1. Core Backend / Versioning

| Source | Endpoint / Path | Used for | Status | Notes |
|--------|-----------------|----------|--------|-------|
| Original Backend Host | `clearskyinstitute.com` | version check, OTA updates, change logs | offline | Hardcoded in wifi/Ota modules, must replace |
| Version script | `/version.pl` | Reports current version | offline | Used by OTA code |

---

## 2. OTA / Firmware Updates

| Source | Endpoint | Purpose | Status | Notes |
|--------|----------|---------|--------|-------|
| Firmware ZIP | `clearskyinstitute.com/ham/HamClock/ESPHamClock.zip` | OTA bundle for ESP | offline | Hard dependency in OTA code |
| Version list | `version.pl` | Compare remote version | offline | |

---

## 3. Maps & Graphics

| Source | Endpoint | Purpose | Status | Notes |
|--------|----------|---------|--------|-------|
| Map tile downloads | (server requests inside mapmanage.cpp) | World maps (continents, countries) | often failing | originally served from clearskyinstitute.com |
| Solar / Kp images | NOAA or similar | Space weather visuals | unreliable | dependent on external services |

---

## 4. Propagation & Spot Data

| Data Source | Endpoint / Protocol | Purpose | Notes |
|-------------|----------------------|---------|------|
| DX Cluster | Telnet cluster servers | Spots & live propagation | |
| RBN | via web API | Spots count | |
| PSK Reporter | HTTP API | Spots / activity | |

*Note: These are not all on clearskyinstitute.com, many are fetched directly by the code.*

---

## 5. Weather / Space Weather Services

| Service | API / URL | Purpose | Notes |
|---------|------------|---------|------|
| NOAA Space Weather | Various NOAA APIs | Solar indices, Kp, etc | Might need new base URLs |

---

## 6. Time Sources

| Source | Protocol | Purpose |
|--------|----------|---------|
| NTP servers | NTP | Time sync |

---

## 7. Dependencies in Code

Referenced in code modules:

| Module | Role |
|--------|------|
| wifi.cpp / OTAupdate.cpp | Backend host usage |
| spacewx.cpp | Solar & space weather |
| mapmanage.cpp | Map tiles |
| dxcluster.cpp | DX cluster connections |
| grayline.cpp | Grayline propagation |
| webserver & liveweb | HTML UI and client API |

---

## 8. Replacement Directions (Work in progress)

Area | Possible Replacement | Notes
-----|---------------------|------
Version/OTA backend | GitHub Releases or custom server | avoid clearskyinstitute.com
Map tiles | OpenStreetMap / other tile servers | needs config
Solar/NOAA | NOAA APIs with updated endpoints | replace hardcoded calls
Spots/Propagation | DX cluster + PSK reporter maintained services | integration shift
