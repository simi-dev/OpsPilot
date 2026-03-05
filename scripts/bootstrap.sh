#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/opspilot/bootstrap.log"
NODE_MAJOR="20"

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

section "Node.js installation"

if command_exists node; then
  log "Node.js already installed: $(node -v). Skipping."
else
  log "Installing Node.js $NODE_MAJOR..."
  curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash -
  apt-get install -y nodejs
  log "Node.js installed: $(node -v)"
fi

section "PostgresSql installation"
apt install postgresql postgresql-contrib -y

section "Installation verification"

log "Go:         $(go version 2>/dev/null || echo 'NOT FOUND')"
log "Node.js:    $(node -v 2>/dev/null || echo 'NOT FOUND')"
log "npm:        $(npm -v 2>/dev/null || echo 'NOT FOUND')"
log "PostgreSQL: $(psql --version 2>/dev/null || echo 'NOT FOUND')"
log "PG Status:  $(systemctl is-active postgresql)"

section "Bootstrap complete. Log file: $LOG_FILE"