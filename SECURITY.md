# Security Policy

## 1. Supported Versions

Security updates and patches are actively applied to the following versions of **Overleaf Stratum Consumer**:

| Version | Supported          |
| :------ | :----------------- |
| 1.0.x   | :white_check_mark: |
| < 1.0.0 | :x:                |

---

## 2. Reporting a Vulnerability

Security is a foundational pillar of this infrastructure component. If you identify a potential security vulnerability, misconfiguration, or privilege issue, please report it responsibly:

* **Direct Contact:** Send an email detailing the issue to the maintainer at **contacto@sandrapuerto.com**.
* **Details to Include:**
  * Description of the vulnerability or misconfiguration.
  * Steps or proof-of-concept (PoC) to reproduce the behavior.
  * Affected file(s), environment variables, or Docker configurations.
  * Potential impact assessment.

Public GitHub issues for sensitive security vulnerabilities must not be opened until they have been reviewed and remediated.

---

## 3. Container & Consumer Hardening Baseline

This repository implements the following baseline hardening controls under the **Stratum Consumer Specification**:
* **Non-Exposed Host Ports:** Containers bind zero ports directly to the physical host. All ingress is routed via Nginx Proxy Manager on `stratum_dmz`.
* **Privilege Escalation Block:** Enforced `no-new-privileges: true` across all executing containers.
* **Network Isolation:** Direct access to storage backends (MongoDB, Redis) is strictly mediated by Stratum's Layer 4 Boundary TCP Proxy (`stratum-database-nginx`), preventing unauthorized lateral movement.
* **Resource Governance:** Strict limits on CPU and RAM allocations to prevent resource exhaustion attacks.
* **Structured Log Rotation:** Capped JSON logs (`max-size: 10m`, `max-file: 3`) to ensure disk stability.
