# Contributing Guidelines

Contributions to **Overleaf Stratum Consumer** are welcomed. To maintain infrastructure stability, security standards, and strict alignment with the **Stratum Ecosystem**, adherence to the following guidelines is required.

---

## 1. Architectural Philosophy

This project strictly adheres to the **Stratum Consumer Architecture Pattern**:
* **Decoupled Persistence:** Never provision database or caching engines within this repository. MongoDB and Redis must always be consumed centrally from the Stratum Data Tier (`stratum-database-nginx`).
* **Zero Host Port Exposure:** Never bind ports to the host interface (`ports: "80:80"` is strictly prohibited). All traffic flows through the shared `stratum_dmz` network.
* **Container Hardening:** Adhere to defensive Docker Compose specifications (`no-new-privileges: true`, resource quotas, health checks, and strict log rotation).

---

## 2. Development & Contribution Workflow

1. **Fork the Repository:** Create a personal fork on GitHub.
2. **Create a Feature Branch:**
   ```bash
   git checkout -b feature/your-improvement-name
   ```
3. **Local Testing:**
   Ensure prerequisites (`stratum_dmz` and `stratum-database-nginx` or a compatible mock) are available in your Docker daemon before testing container spins:
   ```bash
   docker compose config
   docker compose build
   ```
4. **Commit Standards:**
   Follow Conventional Commits with clear, imperative messages:
   - `feat(docker): add texlive package for specialized fonts`
   - `fix(env): update proxy headers for websocket stability`
   - `docs(readme): expand deployment runbook`
5. **Submit a Pull Request:** Open a PR against the `main` branch with a clear description of the modifications and verification results.

---

## 3. Code & Configuration Standards

* **Docker Compose:** Keep configuration clean, DRY, and well-commented. Preserve default health checks and labels.
* **Dockerfile:** Combine package installations into single cached layers where appropriate, cleaning `/var/lib/apt/lists/*` to minimize final image footprint.
* **Environment Variables:** Document any new environment variable in `.env.example` with safe defaults and clear annotations.

---

## 4. Code of Conduct

All contributors and maintainers are expected to maintain professional, respectful, and constructive collaboration.
