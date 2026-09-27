# Overleaf Community Edition — Stratum Consumer Architecture

> *"Enterprise collaborative LaTeX platform deployed under zero-trust island isolation and transversal persistence."*

[![Platform](https://img.shields.io/badge/Platform-Overleaf%20CE%20v5.x-4f46e5?style=for-the-badge&logo=overleaf&logoColor=white)](https://github.com/overleaf/overleaf)
[![TeX Live](https://img.shields.io/badge/TeX%20Live-Scheme--Full%202026-009639?style=for-the-badge&logo=latex&logoColor=white)](https://www.tug.org/texlive/)
[![Architecture](https://img.shields.io/badge/Architecture-Stratum%20Consumer-0284c7?style=for-the-badge&logo=docker&logoColor=white)](#1-architectural-motivation--executive-summary)
[![Security](https://img.shields.io/badge/Security-Zero--Exposed--Ports%20%7C%20L4%20Boundary-emerald?style=for-the-badge)](SECURITY.md)
[![License](https://img.shields.io/badge/License-MIT%20Custom-yellow.svg?style=for-the-badge)](LICENSE)

**Overleaf-Stratum** is an enterprise-grade, cloud-agnostic deployment pattern for **Overleaf Community Edition (ShareLaTeX)** built as a turnkey **Stratum Consumer**.

This project provides any team or enterprise with an production-ready, hardened LaTeX environment that decouples the heavy compilation engine from database management, consuming MongoDB and Redis centrally via the **Stratum Data Layer Boundary Proxy** while eliminating open host ports.

---

## 1. Architectural Motivation & Executive Summary

Standard self-hosted Overleaf deployments suffer from common structural bottlenecks:
1. **Redundant Persistence Footprint:** Bundling dedicated MongoDB and Redis instances per application duplicates memory overhead, database maintenance, and backup routines.
2. **Exposed Host Ports:** Exposing host ports (`80`, `443`, `27017`) increases attack surface and causes port allocation conflicts across multiple workloads.
3. **Privilege Escalation Risks:** Compiling arbitrary LaTeX code presents security challenges if containers run with unconstrained privileges.

**Overleaf-Stratum** addresses these challenges by implementing the **Stratum Consumer Pattern**:
* **Transversal Persistence:** Replaces fragmented database containers by connecting to centralized, air-gapped MongoDB and Redis engines via the **Stratum L4 Boundary TCP Proxy** (`stratum-database-nginx`).
* **100% Ingress Cloaking:** Zero open host ports. Ingress traffic enters strictly through outbound Cloudflare Zero-Trust Tunnels and is routed internally by Nginx Proxy Manager on the `stratum_dmz` network.
* **Full TeX Live Environment:** Pre-packaged with `scheme-full` and essential typography (`Noto`, `Liberation`, `DejaVu`), eliminating runtime package download delays.
* **Strict Container Hardening:** Enforces `no-new-privileges: true`, structured log rotation, CPU/RAM quotas, and isolated network boundaries.
* **Architecture Pinning:** Hardcoded to Overleaf `6.2.2` to bypass critical Node 22 + MongoDB Legacy Driver upstream crashes in `6.3.0+`.

---

## 2. High-Level System Architecture

```mermaid
graph TB
    subgraph WAN ["🌐 Public Internet & Cloudflare Edge"]
        User["Client Browser / TeX Editor"] --> Cloudflare["Cloudflare Zero-Trust Edge"]
    end

    subgraph Host ["🖥️ Virtual Private Server (Host Level - Zero Open Ports)"]
        subgraph GatewayIsland ["🚪 Layer 1: Stratum Gateway Tier"]
            CF_Tunnel["cloudflared<br/>(Outbound Tunnel Engine)"]
            NPM["Nginx Proxy Manager<br/>(SSL & Internal Routing)"]
            CF_Tunnel -->|HTTP Forward| NPM
        end

        subgraph SharedDMZ ["🛡️ Layer 2: Stratum DMZ (stratum_dmz)"]
            DMZ_Net(("stratum_dmz Bridge"))
        end

        subgraph ConsumerTier ["📦 Layer 3: Overleaf Stratum Consumer (This Repo)"]
            ShareLaTeX["overleaf-sharelatex<br/>(Node.js / TeX Live Scheme-Full)"]
            TeXEngines["PDFLaTeX / XeLaTeX / LuaLaTeX / BibTeX"]
            ShareLaTeX --- TeXEngines
        end

        subgraph DatabaseIsland ["🗄️ Layer 4: Stratum Persistence Tier (stratum-database)"]
            DB_Proxy["stratum-database-nginx<br/>(Boundary TCP Stream Proxy)"]
            DB_Net(("stratum_database_internal<br/>(Air-Gapped: internal=true)"))
            
            MongoDB[("MongoDB 7.0<br/>Document Store")]
            Redis[("Redis Engine<br/>Cache & Pub/Sub")]

            DB_Proxy --> DB_Net
            DB_Net --> MongoDB
            DB_Net --> Redis
        end
    end

    Cloudflare -.->|Encrypted Outbound Tunnel| CF_Tunnel
    NPM -->|Route by Hostname| DMZ_Net
    DMZ_Net -->|HTTP / Websocket :80| ShareLaTeX
    ShareLaTeX -->|TCP Stream :27017 & :6379| DB_Proxy

    classDef edge fill:#f59e0b,stroke:#b45309,stroke-width:2px,color:#000;
    classDef gateway fill:#1e293b,stroke:#38bdf8,stroke-width:2px,color:#fff;
    classDef dmz fill:#0f172a,stroke:#f59e0b,stroke-width:2px,color:#fff;
    classDef consumer fill:#1e293b,stroke:#10b981,stroke-width:2px,color:#fff;
    classDef database fill:#1e293b,stroke:#ec4899,stroke-width:2px,color:#fff;

    class User,Cloudflare edge;
    class CF_Tunnel,NPM gateway;
    class DMZ_Net dmz;
    class ShareLaTeX,TeXEngines consumer;
    class DB_Proxy,MongoDB,Redis database;
```

---

## 3. Ingress & Real-Time Data Flow

```mermaid
sequenceDiagram
    autonumber
    actor User as Researcher / Student / Developer
    participant CF as Cloudflare Zero-Trust Edge
    participant Tunnel as cloudflared (Tunnel Engine)
    participant NPM as Nginx Proxy Manager
    participant App as overleaf-sharelatex (DMZ)
    participant Proxy as stratum-database-nginx (Boundary)
    participant Mongo as MongoDB (Air-Gapped)
    participant Redis as Redis (Air-Gapped)

    User->>CF: HTTPS / WSS (latex.yourdomain.com)
    CF->>Tunnel: Encrypted Stream via Outbound Tunnel
    Tunnel->>NPM: Forward HTTP/WS on stratum_gateway_internal
    NPM->>App: Proxy to overleaf-sharelatex:80 on stratum_dmz
    App->>Proxy: Read/Write Project Metadata (:27017)
    Proxy->>Mongo: TCP Stream on stratum_database_internal
    Mongo-->>Proxy: Document Response
    Proxy-->>App: Return Project Model
    App->>Proxy: Realtime Sync & Pub/Sub (:6379)
    Proxy->>Redis: Redis Stream / Hash Updates
    App-->>NPM: Real-time Collaboration WebSocket Frames
    NPM-->>Tunnel: Encrypted Response
    Tunnel-->>CF: Output Stream
    CF-->>User: Instant Collaborative TeX UI
```

---

## 4. Repository Structure

```
overleaf/
├── .env.example          # Environment template with generic placeholders
├── .gitignore            # Git exclusion rules (secrets, volumes, caches)
├── docker-compose.yml    # Hardened Overleaf consumer deployment (official image)
├── LICENSE               # MIT License with Security Disclosure Clause
├── README.md             # Master Architecture & Technical Specification
├── SECURITY.md           # Responsible Vulnerability Disclosure Protocol
└── CONTRIBUTING.md       # Engineering Contribution Guidelines
```

---

## 5. Security & Hardening Matrix

| Security Layer | Implementation | Defensive Objective |
| :--- | :--- | :--- |
| **Ingress Boundary** | Cloudflare Tunnel + NPM | Eliminates open host ports; hides host IP behind Cloudflare edge. |
| **Persistence Boundary** | L4 Proxy (`stratum-database-nginx`) | Air-gaps databases; consumer cannot query storage networks directly. |
| **Privilege Escalation** | `no-new-privileges: true` + `cap_drop: ALL` | Drops Linux capabilities; blocks child process privilege elevation. |
| **Volatile Compilation RAM**| `tmpfs` mounts (`/tmp` 384MB RAM) | Compiles intermediate TeX files in RAM; avoids disk I/O and host tampering. |
| **Resource Governance** | Capped CPU (`1.5`), RAM (`2.5GB`), PIDs (`150`) | Calibrated specifically for a 2 vCPU / 4GB VPS host to prevent OOM panics. |
| **Session Hardening** | `OVERLEAF_SESSION_SECRET` | Prevents session invalidation across container restarts. |
| **Log Management** | JSON log rotation (`10m` x 3) | Prevents denial-of-service via disk exhaustion from compilation logs. |

---

## 6. Deployment & Operations Runbook

### 6.1 Prerequisites

Before deploying Overleaf, the foundational **Stratum** tiers must be running:
1. `stratum/dmz` (Network `stratum_dmz` provisioned).
2. `stratum/gateway` (Cloudflare Tunnel & Nginx Proxy Manager active).
3. `stratum/database` (MongoDB & Redis running behind `stratum-database-nginx`).

### 6.2 Database Provisioning in Stratum

Ensure the Overleaf database and user are initialized in Stratum's MongoDB:

```javascript
// Connect to MongoDB via Stratum database container:
// docker exec -it stratum-database-mongodb mongosh -u <ROOT_USER> -p <ROOT_PASS> admin

use sharelatex;
db.createUser({
  user: "overleaf_app",
  pwd: "your_alphanumeric_url_safe_password",
  roles: [ { role: "readWrite", db: "sharelatex" } ]
});
```

*Note: The MongoDB backend MUST be configured as a Replica Set (`rs0`), even if it is a single-node cluster, because modern Overleaf heavily utilizes MongoDB multi-document transactions.*

### 6.3 Deployment Commands

```bash
# 1. Clone or navigate to the overleaf directory
cd overleaf/

# 2. Configure environment variables
cp .env.example .env
chmod 600 .env

# 3. Edit .env with your specific parameters:
# - Set MONGO_APP_PASSWORD and REDIS_PASSWORD matching Stratum
# - Generate OVERLEAF_SESSION_SECRET: openssl rand -base64 32
# - Generate OVERLEAF_INVITE_TOKEN_SECRET: openssl rand -base64 32
# - Set OVERLEAF_SITE_URL to your public domain (e.g. https://latex.yourdomain.com)

# 4. Build the TeX Live Scheme-Full image and launch the container
docker compose build
docker compose up -d

# 5. Verify service health
docker compose ps
docker compose logs -f sharelatex
```

### 6.4 Nginx Proxy Manager (NPM) Route Configuration

In the Nginx Proxy Manager web dashboard:
* **Domain Names:** `latex.yourdomain.com`
* **Scheme:** `http`
* **Forward Hostname / IP:** `overleaf-sharelatex`
* **Forward Port:** `80`
* **Websockets Support:** `Enabled` *(Required for collaborative editing)*
* **Block Common Exploits:** `Enabled`
* **SSL:** Request Let's Encrypt Certificate, enable `Force SSL` and `HTTP/2 Support`.

### 6.5 Admin User Creation

Once the container is healthy:
```bash
docker exec -it overleaf-sharelatex /bin/bash -c "bin/grunt user:create-admin --email=admin@yourdomain.com"
```
Follow the generated URL in your browser to finalize password setup.

---

## 7. Configuration Reference (`.env`)

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `STRATUM_DMZ_NETWORK` | `stratum_dmz` | Name of the shared external DMZ Docker network. |
| `STRATUM_DB_HOST` | `stratum-database-nginx` | Hostname of the Stratum L4 boundary proxy on `stratum_dmz`. |
| `MONGO_APP_USER` | `overleaf_app` | MongoDB user assigned to the `sharelatex` database. |
| `MONGO_APP_PASSWORD` | *(Required)* | MongoDB password (Must be URL-safe / Alphanumeric to prevent connection parser crashes). |
| `MONGO_DB_NAME` | `sharelatex` | Primary MongoDB database name. |
| `MONGO_EXTRA_PARAMS` | `&replicaSet=rs0&directConnection=true` | Required parameters for single-node replica set behind Stratum Proxy. |
| `REDIS_PASSWORD` | *(Required)* | Redis authentication password configured in Stratum. |
| `OVERLEAF_SITE_URL` | `https://latex.example.com` | Canonical public HTTPS URL for the platform. |
| `OVERLEAF_SESSION_SECRET` | *(Required)* | 32-byte Base64 secret key for encrypting user sessions across restarts. |
| `OVERLEAF_INVITE_TOKEN_SECRET` | *(Required)* | 32-byte Base64 secret key for securing invitation tokens. |
| `OVERLEAF_ALLOW_PUBLIC_ACCESS` | `false` | When `false`, prevents open registrations (requires admin invite). |
| `CPU_LIMIT` | `1.5` | Maximum CPU cores allocated to LaTeX compilation (preserves 0.5 vCPU for host). |
| `MEM_LIMIT` | `2.5G` | Maximum RAM ceiling allocated to the container (preserves 1.5GB for host & DBs). |
| `NODE_OPTIONS` | `--max-old-space-size=1536` | Node.js memory ceiling parameter to prevent heap bloat. |

---

## 8. Author & Architectural Provenance

**Stratum-Core & Overleaf Consumer Pattern** were conceived, architected, and documented by **Sandra Gabriela Puerto Torres**.

* **Role:** Backend Developer & Technical Infrastructure Director
* **Core Philosophy:** *Systems must be financially viable, structurally isolated, and resilient to operational turbulence without requiring oversized cloud budgets.*
* **Specialization:** PHP/Laravel, Linux Systems, Network Topology, Proxmox VE, Cloudflare Edge Architecture, Container Hardening.
* **Website:** [https://sandrapuerto.com](https://sandrapuerto.com)
* **Contact:** [contacto@sandrapuerto.com](mailto:contacto@sandrapuerto.com)

---

## 9. License

This project is licensed under the enhanced MIT License with a mandatory private security vulnerability disclosure condition. See [LICENSE](LICENSE) for full legal text.
