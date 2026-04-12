# cluster-ops

GitOps-managed Kubernetes cluster running on bare metal, powered by [Flux](https://fluxcd.io/) and [Talos Linux](https://www.talos.dev/).

## 🏗️ Architecture

| Component | Details |
|-----------|---------|
| **Hardware** | 5× Dell Optiplex 3090 Micro |
| **OS** | [Talos Linux](https://www.talos.dev/) |
| **Kubernetes** | Talos-managed, 3 control plane + 2 workers |
| **Boot disk** | 128GB 2230 NVMe via M.2 WiFi key adapter |
| **GitOps** | [Flux](https://fluxcd.io/) with SOPS encryption |
| **Networking** | [Cilium](https://cilium.io/) CNI with full network policy enforcement |
| **Ingress** | [HAProxy](https://www.haproxy.org/) Kubernetes Ingress Controller |
| **Storage** | [Rook-Ceph](https://rook.io/) (NVMe + SATA SSD, block + filesystem) |
| **Certificates** | [cert-manager](https://cert-manager.io/) |
| **Secrets** | [SOPS](https://github.com/getsops/sops) with Age encryption |
| **Databases** | [CloudNative-PG](https://cloudnative-pg.io/) for PostgreSQL workloads |
| **Monitoring** | Prometheus + Grafana via [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts) |
| **Backups** | [VolSync](https://volsync.readthedocs.io/) for PVC replication |
| **Updates** | [Renovate](https://docs.renovatebot.com/) with automerge |

## 📁 Repository Structure

```
kubernetes/
├── apps/          # Application deployments
├── clusters/      # Cluster-level Flux Kustomizations
├── core/          # Core infrastructure (Cilium, cert-manager, HAProxy, Flux)
├── monitoring/    # Prometheus stack, alerting rules
├── security/      # Admission policies
└── storage/       # Rook-Ceph cluster configuration
```

## 🤖 Ansible

Ansible playbooks for host provisioning and configuration are in the `ansible/` directory, executed via [AWX](https://github.com/ansible/awx) running in-cluster.

## 🔒 Network Security

Every namespace has a default-deny network policy. Ingress and egress are explicitly allowed per-app using Kubernetes NetworkPolicies and CiliumNetworkPolicies.

## 📦 Applications

### Media & Entertainment

| Service | Purpose |
|---------|---------|
| [Jellyfin](https://jellyfin.org/) | Primary media server |
| [Plex](https://plex.tv/) | Secondary media server |
| [Sonarr](https://sonarr.tv/) / [Radarr](https://radarr.video/) / [Lidarr](https://lidarr.audio/) | Media management & automation |
| [Readarr](https://readarr.com/) / [Speakarr](https://github.com/speakarr/speakarr) | Books & audiobooks |
| [Navidrome](https://navidrome.org/) | Music streaming (Subsonic API) |
| [Audiobookshelf](https://audiobookshelf.org/) | Audiobook & podcast server |
| [qBittorrent](https://qbittorrent.org/) | Download client |
| [Prowlarr](https://prowlarr.com/) | Indexer management |
| [Bazarr](https://bazarr.media/) | Subtitle management |
| [Tdarr](https://tdarr.io/) | Distributed media transcoding |
| [ErsatzTV](https://ersatztv.org/) | Custom IPTV channels |
| [Tautulli](https://tautulli.com/) / [Jellystat](https://github.com/CyferShepard/Jellystat) | Playback analytics |
| [Recyclarr](https://recyclarr.dev/) | Quality profile sync for Sonarr/Radarr |
| [Seerr](https://overseerr.dev/) | Media request management |
| [Pinchflat](https://github.com/kieraneglin/pinchflat) | YouTube archival |
| [MeTube](https://github.com/alexta69/metube) | Video downloads |

### Productivity & Knowledge
| Service | Purpose |
|---------|---------|
| [Nextcloud](https://nextcloud.com/) | Files, calendar, contacts |
| [Paperless-ngx](https://docs.paperless-ngx.com/) | Document management with AI classification |
| [Mealie](https://mealie.io/) | Recipe manager |
| [FreshRSS](https://freshrss.org/) | RSS feed aggregator |
| [Karakeep](https://github.com/karakeep-app/karakeep) | Bookmark manager |
| [Vaultwarden](https://github.com/dani-garcia/vaultwarden) | Bitwarden-compatible password manager |
| [Wallos](https://github.com/ellite/Wallos) | Subscription tracker |

### Development & DevOps
| Service | Purpose |
|---------|---------|
| [Forgejo](https://forgejo.org/) | Self-hosted Git forge |
| [JupyterHub](https://jupyter.org/hub) | Multi-user notebook environment |
| [OpenCode](https://github.com/AnomalyHQ/opencode) | AI coding agent |
| [AWX](https://github.com/ansible/awx) | Ansible automation platform |

### AI & Search
| Service | Purpose |
|---------|---------|
| [LiteLLM](https://litellm.ai/) | OpenAI-compatible LLM proxy (GitHub Copilot gateway) |
| [Ollama](https://ollama.ai/) | Local LLM inference |
| [Open WebUI](https://openwebui.com/) | Chat interface for local models |
| [SearXNG](https://searxng.org/) | Privacy-respecting metasearch engine |
| [OpenClaw](https://openclaw.ai/) | AI assistant platform |

### Home & Infrastructure
| Service | Purpose |
|---------|---------|
| [Home Assistant MCP](https://github.com/homeassistant-ai/ha-mcp) | Smart home AI bridge |
| [AdGuard Home](https://adguard.com/adguard-home.html) | DNS-level ad blocking |
| [Unifi Controller](https://ui.com/) | Network management |
| [Changedetection.io](https://changedetection.io/) | Website change monitoring |
| [Uptime Kuma](https://uptime.kuma.pet/) | Service uptime monitoring |
| [Syncthing](https://syncthing.net/) | File synchronization |
| [OwnTracks](https://owntracks.org/) | Location tracking |

### Gaming
| Service | Purpose |
|---------|---------|
| [Minecraft](https://www.minecraft.net/) | Multiple Java + Bedrock servers |
| [RomM](https://github.com/rommapp/romm) | ROM manager |

## 🔄 Automated Updates

[Renovate](https://docs.renovatebot.com/) with automerge for trusted container digests, patch updates, and Grafana dashboards.

## 📊 Monitoring & Alerting

[kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) with custom alerting rules for Ceph health, node resources, pod restarts, blackbox probes, and VolSync backup status.

## 🏠 Storage

[Rook-Ceph](https://rook.io/) manages all persistent storage across the cluster:

- **Block storage** (RBD) — NVMe-backed, 3-way replication for databases and stateful apps
- **Filesystem** (CephFS) — Shared storage for media libraries, 2-way replication
- **Encryption** — All OSDs use encrypted devices
- Each node contributes NVMe and SATA SSDs to the Ceph cluster

Each Optiplex 3090 Micro has three storage devices:

| Slot | Device | Purpose |
|------|--------|---------|
| M.2 WiFi → NVMe adapter | 128GB 2230 NVMe | Talos OS |
| M.2 NVMe | 1–4TB NVMe (970 EVO Plus, SN850X, SN735) | Ceph OSDs (2 per drive) |
| 2.5" SATA | 4–8TB Samsung 870 QVO | Ceph OSD (1 per drive) |

The WiFi-to-NVMe adapter trick gives each node a dedicated boot drive without sacrificing the main NVMe slot for Ceph.

PVC backups via [VolSync](https://volsync.readthedocs.io/) with Restic snapshots to S3-compatible storage.
