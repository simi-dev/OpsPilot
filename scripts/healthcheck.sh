#!/bin/bash
set -euo pipefail

API_URL="http://localhost:8000/api/health"
LOG_PATH="/var/log/opspilot/healthcheck.log"

# Create log folder
mkdir -p /var/log/opspilot

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_PATH"
}

# Perform health check
log "Healthcheck started at $(date)"

# Check API health
HTTP_STATUS=$(curl -o /dev/null -s -w "%{http_code}" $API_URL || echo "000")
if [ $HTTP_STATUS -eq 200 ]; then
    log "API is healthy. Status code: $HTTP_STATUS"
    exit 0
else
    log "API is down. Status code: $HTTP_STATUS"
    exit 1
fi

#* To schedule this script with cron every 5 minutes, you can add the following line to your crontab file:
#* */5 * * * * /home/opspilot/healthcheck.sh
