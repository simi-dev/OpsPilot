#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/opspilot/bootstrap.log"

# Log function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

section() {
  log "------------------------------------------------------------"
  log " $*"
  log "------------------------------------------------------------"
}

section "Starting OpsPilot bootstrap"

log "Updating package index..."
apt-get update -y

section "Go installation"
apt install golang -y

section "NodeJS installation"
apt install nodejs -y
apt install npm -y

section "PostgresSql installation"
apt install postgresql postgresql-contrib -y

section "Installation verification"

log "Go:         $(go version 2>/dev/null || echo 'NOT FOUND')"
log "Node.js:    $(node -v 2>/dev/null || echo 'NOT FOUND')"
log "npm:        $(npm -v 2>/dev/null || echo 'NOT FOUND')"
log "PostgreSQL: $(psql --version 2>/dev/null || echo 'NOT FOUND')"
log "PG Status:  $(systemctl is-active postgresql)"

section "Bootstrap complete. Log file: $LOG_FILE"
