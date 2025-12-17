# Synology NAS Docker Configuration

**Purpose:** Documentation for Docker containers running on Synology NAS
**Note:** Synology does not support docker-compose.yml files in the UI, so this documents the manual configuration via Container Manager.

---

## Overview

The Synology NAS runs several media server and automation containers configured through the Container Manager UI. This document serves as infrastructure-as-code documentation for recreating the setup if needed.

---

## Container Configurations

### Sonarr (TV Show Management)

**Image:** `linuxserver/sonarr:latest`

**File Mounts:**
| File/Folder | Mount Path |
| ----------- | ---------- |
| `docker/container_configs/sonarr` | `/config` |
| `docker/extracted` | `/extracted` |
| `docker/tv` | `/tv` |
| `docker/watch` | `/watch` |
| `docker/complete` | `/complete` |

**Ports:**
| Local Port | Container Port | Description |
| ---------- | -------------- | ----------- |
| 32700 | 8989 | Non-SSL Port |

**Access:** `http://synology-nas:32700`

---

### Radarr (Movie Management)

**Image:** `linuxserver/radarr:latest`

**File Mounts:**
| File/Folder | Mount Path |
| ----------- | ---------- |
| `docker/container_configs/radarr` | `/config` |
| `docker/extracted` | `/extracted` |
| `docker/movies` | `/movies` |
| `docker/watch` | `/watch` |
| `docker/complete` | `/complete` |

**Ports:**
| Local Port | Container Port | Description |
| ---------- | -------------- | ----------- |
| 32710 | 7878 | Non-SSL Port |

**Access:** `http://synology-nas:32710`

---

### Jackett (Torrent Indexer Proxy)

**Image:** `linuxserver/jackett:latest`

**File Mounts:**
| File/Folder | Mount Path |
| ----------- | ---------- |
| `docker/container_configs/jackett` | `/config` |

**Ports:**
| Local Port | Container Port | Description |
| ---------- | -------------- | ----------- |
| 32720 | 9117 | Non-SSL Port |

**Access:** `http://synology-nas:32720`

---

### Syncthing (File Synchronization)

**Image:** `linuxserver/syncthing:latest`

**File Mounts:**
| File/Folder | Mount Path |
| ----------- | ---------- |
| `docker/watch` | `/watch` |
| `docker/complete` | `/complete` |
| `docker/container_configs/sync_thing` | `/config` |

**Ports:**
| Local Port | Container Port | Description |
| ---------- | -------------- | ----------- |
| 32730 | 8384 | Non-SSL Port |

**Access:** `http://synology-nas:32730`

---

### Bazarr (Subtitle Management)

**Image:** `linuxserver/bazarr:latest`

**File Mounts:**
| File/Folder | Mount Path |
| ----------- | ---------- |
| `docker/container_configs/bazarr` | `/config` |
| `docker/movies` | `/movies` |
| `docker/tv` | `/tv` |

**Ports:**
| Local Port | Container Port | Description |
| ---------- | -------------- | ----------- |
| 32740 | 6767 | Non-SSL Port |

**Access:** `http://synology-nas:32740`

---

### Overseerr (Media Request Management)

**Image:** `linuxserver/overseerr:latest`

**Ports:**
| Local Port | Container Port | Description |
| ---------- | -------------- | ----------- |
| 32750 | 5055 | Non-SSL Port |

**Access:** `http://synology-nas:32750`

---

### FlareSolverr (Cloudflare Bypass)

**Image:** `flaresolverr/flaresolverr:latest`

**Ports:**
| Local Port | Container Port | Description |
| ---------- | -------------- | ----------- |
| 32760 | 8191 | API Port |

**Note:** Used by Jackett to bypass Cloudflare protection on torrent indexers.

---

### Lidarr (Music Management)

**Image:** `linuxserver/lidarr:latest`

**File Mounts:**
| File/Folder | Mount Path |
| ----------- | ---------- |
| `docker/container_configs/lidarr` | `/config` |
| `docker/music` | `/music` |
| `docker/complete` | `/complete` |

**Ports:**
| Local Port | Container Port | Description |
| ---------- | -------------- | ----------- |
| 32770 | 8686 | Non-SSL Port |

**Access:** `http://synology-nas:32770`

---

### Navidrome (Music Streaming Server)

**Image:** `deluan/navidrome:latest`

**File Mounts:**
| File/Folder | Mount Path |
| ----------- | ---------- |
| `docker/container_configs/navidrome` | `/data` |
| `docker/music` | `/music` |

**Ports:**
| Local Port | Container Port | Description |
| ---------- | -------------- | ----------- |
| 32780 | 4533 | Web Interface |

**Access:** `http://synology-nas:32780`

---

## Deluge (Torrent Client)

**Image:** `linuxserver/deluge:latest`

### Preferences Configuration

**Download Settings:**
- **Download to:** `/home13/chappys4life/downloads`
- **Move completed to:** `/home13/chappys4life/complete`
- **Copy of .torrent files to:** `/home13/chappys4life/downloads/torrents`

### Plugins

**Extractor Plugin:**
- **Extract to:** `/home13/chappys4life/complete`
- Automatically extracts compressed files after download completes

**AutoAdd Plugin:**
- **Watch folder:** `/home13/chappys4life/watch/deluge`
- **Enable watch folder:** ✓ Yes
- **Copy of .torrent files to:** `/home13/chappys4life/downloads/torrents`
- **Delete copy of torrent file on remove:** ✓ Yes

**Purpose:** Automatically adds .torrent files dropped in watch folder and cleans up after completion.

---

## Port Mapping Summary

| Service | Local Port | Container Port | Purpose |
| ------- | ---------- | -------------- | ------- |
| Sonarr | 32700 | 8989 | TV show management |
| Radarr | 32710 | 7878 | Movie management |
| Jackett | 32720 | 9117 | Torrent indexer |
| Syncthing | 32730 | 8384 | File sync |
| Bazarr | 32740 | 6767 | Subtitle management |
| Overseerr | 32750 | 5055 | Media requests |
| FlareSolverr | 32760 | 8191 | Cloudflare bypass |
| Lidarr | 32770 | 8686 | Music management |
| Navidrome | 32780 | 4533 | Music streaming |

**Note:** All services use ports in the 32700-32799 range to avoid conflicts with Synology system services.

---

**Last Updated:** December 16, 2025
**Status:** Active - Synology NAS
**Maintained By:** Bud
**Related:** [Mac Mini Homelab](../README.md)
