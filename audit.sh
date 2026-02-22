#!/bin/bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

OUTPUT_FORMAT="pretty"

HOSTNAME_VAL=""
OS_VAL=""
KERNEL_VAL=""
UPTIME_VAL=""
CPU_LOAD=""
CPUS_NO=0
MEM_PCT=0
DISK_PCT=0
FAILED_SSH=0
IP=""
GATEWAY=""

# Parse flags
while [[ $# -gt 0 ]]; do
    case $1 in
        --json) OUTPUT_FORMAT="json"; shift ;;
        --remote) REMOTE_HOST="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

audit_system_info() {
    HOSTNAME_VAL=$(hostname)
    OS_VAL=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
    KERNEL_VAL=$(uname -r)
    UPTIME_VAL=$(uptime -p)

    if [ "$OUTPUT_FORMAT" = "pretty" ]; then
        echo -e "${GREEN}=== System Info ===${NC}"
        echo "  Hostname : $HOSTNAME_VAL"
        echo "  OS       : $OS_VAL"
        echo "  Kernel   : $KERNEL_VAL"
        echo "  Uptime   : $UPTIME_VAL"
    fi

}

audit_resources() {
    # CPU load
    CPU_LOAD=$(awk '{print $1}' /proc/loadavg)
    CPUS_NO=$(nproc)

    # Memory
    local mem_total=$(free -m | awk '/Mem:/ {print $2}')
    local mem_used=$(free -m | awk '/Mem:/ {print $3}')

    MEM_PCT=$((mem_used * 100 / mem_total))
    DISK_PCT=$(df / | awk 'NR==2 {gsub(/%/,""); print $5}')

    if [ "$OUTPUT_FORMAT" = "pretty" ]; then
        echo -e "${GREEN}=== Resources ===${NC}"
        echo "  CPU Load : $CPU_LOAD (cores: $CPUS_NO)"
        if [ "$MEM_PCT" -gt 80 ]; then
                echo -e "  Memory   : ${RED}${mem_used}MB / ${mem_total}MB (${MEM_PCT}%)${NC}"
        else
                echo -e "  Memory   : ${GREEN}${mem_used}MB / ${mem_total}MB (${MEM_PCT}%)${NC}"
        fi

        # Disk    
        if [ "$DISK_PCT" -gt 80 ]; then
            echo -e "  Disk /   : ${RED}${DISK_PCT}% used${NC}"
        else
            echo -e "  Disk /   : ${GREEN}${DISK_PCT}% used${NC}"
        fi
    fi

    
}

audit_network() {
    IP=$(ip route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}')
    GATEWAY=$(ip route show default | awk '{print $3}')

    if [ "$OUTPUT_FORMAT" = "pretty" ]; then
            echo -e "${GREEN}=== Network ===${NC}"
            echo "  IP : $IP"
            echo "  Gateway : $GATEWAY"

            echo "  Listening ports:"
            sudo ss -tulnp | awk 'NR>1 {print "    "$1" "$5" "$7}'
    fi
}

audit_security() {
    # Sudoers
    local sudoers=$(getent group sudo | cut -d: -f4)    

    # Failed SSH attempts
    FAILED_SSH=0
    if [ -r /var/log/auth.log ]; then
        FAILED_SSH=$(grep -c "Failed password" /var/log/auth.log 2>/dev/null || echo "0")
    fi

    if [ "$OUTPUT_FORMAT" = "pretty" ]; then
        echo -e "${GREEN}=== Security ===${NC}"

        echo "  Sudo users    : $sudoers"

        if [ "$FAILED_SSH" -gt 10 ]; then
            echo -e "  Failed SSH    : ${RED}${FAILED_SSH} attempts${NC}"
        else
            echo -e "  Failed SSH    : ${GREEN}${FAILED_SSH} attempts${NC}"
        fi

        # Firewall
        if command -v ufw &>/dev/null; then
            local fw_status=$(sudo ufw status | head -1)
            echo "  Firewall      : $fw_status"
        else
            echo -e "  Firewall      : ${YELLOW}UFW not installed${NC}"
        fi
    fi
}

# Remote execution
if [ -n "${REMOTE_HOST:-}" ]; then
    # Copy the script to the remote, run it there, get output back
    scp "$0" "${REMOTE_HOST}:/tmp/opspilot-audit.sh"
    ssh -o StrictHostKeyChecking=accept-new "${REMOTE_HOST}" \
        "bash /tmp/opspilot-audit.sh ${OUTPUT_FORMAT:+--json}"
    exit 0
fi

# Main
main() {
    audit_system_info
    audit_resources
    audit_network
    audit_security
}

# Call main function
main

if [ "$OUTPUT_FORMAT" = "json" ]; then
    cat <<EOF
{
  "hostname": "$HOSTNAME_VAL",
  "os": "$OS_VAL",
  "kernel": "$KERNEL_VAL",
  "uptime": "$UPTIME_VAL",
  "mem_pct": "$MEM_PCT",
  "disk_pct": "$DISK_PCT",
  "failed_ssh": "$FAILED_SSH",
  "ip": "$IP",
  "gateway": "$GATEWAY"
}
EOF
fi

