# Service Inventory

This is a quick reference for services, ports, data locations, and dependencies.

| Service | Ports | Data Path(s) | Depends On | Criticality |
| --- | --- | --- | --- | --- |
| open-webui | 8080 | `${DOCKER_CONFIG_ROOT}/open-webui` | searxng (optional) | Medium |
| wyoming-whisper | 10300 | `${DOCKER_CONFIG_ROOT}/wyoming-whisper` | - | Low |
| wyoming-piper | 10200 | `${DOCKER_CONFIG_ROOT}/wyoming-piper` | - | Low |
| wyoming-openwakeword | 10400 | `${DOCKER_CONFIG_ROOT}/wyoming-openwakeword` | - | Low |
| n8n | 5678 | `${DOCKER_CONFIG_ROOT}/n8n` | alpine-utility (for SSH scripts) | High |
| searxng | 8081 | `${DOCKER_CONFIG_ROOT}/searxng` | - | Medium |
| metube | 8082 | `${DOCKER_CONFIG_ROOT}/metube`, `${DOCKER_DOWNLOADS_ROOT}` | - | Low |
| karakeep | 3000 | `${DOCKER_CONFIG_ROOT}/karakeep/data` | karakeep-meilisearch, karakeep-chrome | High |
| karakeep-meilisearch | 7700 (internal) | `${DOCKER_CONFIG_ROOT}/karakeep/meili_data` | - | High |
| karakeep-chrome | 9222 (internal) | none | - | Medium |
| budget-dashboard | 8501 | `${DOCKER_CONFIG_ROOT}/budget-dashboard/app-data` | - | Medium |
| budget-dashboard-gf | 8504 | `${DOCKER_CONFIG_ROOT}/budget-dashboard-gf/app-data` | - | Medium |
| gitea | 3002, 2222 | `${DOCKER_CONFIG_ROOT}/gitea` | - | High |
| learning-dashboard | 8502 | `${DOCKER_CONFIG_ROOT}/learning-dashboard/app-data` | - | Low |
| audiobookshelf | 13378 | `${DOCKER_CONFIG_ROOT}/audiobookshelf/*` | - | High |
| youtube-transcripts-api | 5001 | none | - | Medium |
| open-notebook | 8503, 5055 | `${DOCKER_CONFIG_ROOT}/open-notebook/*` | ollama (host) | Medium |
| openedai-speech | 8000 | `${DOCKER_CONFIG_ROOT}/openedai-speech/*` | - | Medium |
| tailscale | host network | `${DOCKER_CONFIG_ROOT}/tailscale/state` | - | Medium |
| alpine-utility | 2223 | `${DOCKER_CONFIG_ROOT}/alpine-utility` | docker socket | High |
| victoria-logs | 9428 | `${DOCKER_CONFIG_ROOT}/victoria-logs` | - | Medium |
