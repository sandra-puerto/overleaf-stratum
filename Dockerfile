# ============================================================================
# OVERLEAF-STRATUM — Production TeX Live Environment
# Stratum Consumer Pattern
# ============================================================================
#
# Component ......... overleaf
# Base Image ........ sharelatex/sharelatex:latest
# Architecture ...... Stratum Consumer (LaTeX Platform)
# ============================================================================

FROM sharelatex/sharelatex:latest

LABEL org.opencontainers.image.title="Overleaf Community Edition — Stratum Consumer" \
      org.opencontainers.image.description="Hardened, full-featured Overleaf Community Edition with complete TeX Live scheme" \
      org.opencontainers.image.licenses="MIT" \
      com.stratum.pattern="stratum-consumer"

# Update TeX Live manager and install complete scheme + essential system typography
RUN tlmgr update --self --all && \
    tlmgr install scheme-full && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        fonts-noto \
        fonts-liberation \
        fonts-dejavu \
        ghostscript \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*