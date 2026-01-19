#!/usr/bin/env bash
set -euo pipefail

# --------- USER SETTINGS (override via env vars) ----------
MANAGER_IP="${MANAGER_IP:-192.168.10.100}"
ENROLL_PASS="${ENROLL_PASS:-}"
AGENT_NAME="${AGENT_NAME:-$(hostname -s)}"
AGENT_GROUP="${AGENT_GROUP:-default}"
WAZUH_VERSION="${WAZUH_VERSION:-4.14}"   # repo major/minor line
# ----------------------------------------------------------

log() { echo -e "[+] $*"; }
err() { echo -e "[!] $*" >&2; }

if [[ $EUID -ne 0 ]]; then
  err "Run as root: sudo -E $0"
  exit 1
fi

if [[ -z "${ENROLL_PASS}" ]]; then
  err "ENROLL_PASS is required (this is the agent enrollment password, not the dashboard password)."
  err "Example: sudo -E MANAGER_IP=192.168.10.100 ENROLL_PASS='YourEnrollPassword' $0"
  exit 1
fi

log "Installing prerequisites..."
apt-get update -y
apt-get install -y curl gnupg apt-transport-https lsb-release ca-certificates

log "Adding Wazuh repository and key..."
curl -fsSL https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmor -o /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/${WAZUH_VERSION}/apt/ stable main" \
  > /etc/apt/sources.list.d/wazuh.list

apt-get update -y

log "Installing + enrolling wazuh-agent (doc-style deployment variables)..."
# Clean any previous key to avoid duplicates if a VM snapshot was reused
rm -f /var/ossec/etc/client.keys 2>/dev/null || true

export WAZUH_MANAGER="${MANAGER_IP}"
export WAZUH_AGENT_NAME="${AGENT_NAME}"
export WAZUH_AGENT_GROUP="${AGENT_GROUP}"
export WAZUH_REGISTRATION_PASSWORD="${ENROLL_PASS}"

DEBIAN_FRONTEND=noninteractive apt-get install -y wazuh-agent

log "Enabling and starting wazuh-agent..."
systemctl enable --now wazuh-agent

log "Quick health check (last 30 log lines):"
tail -n 30 /var/ossec/logs/ossec.log || true

log "Service status:"
systemctl --no-pager --full status wazuh-agent | sed -n '1,14p'

log "Done. If it shows disconnected, verify manager ports 1514/tcp and 1515/tcp are reachable and the enrollment password is correct."

