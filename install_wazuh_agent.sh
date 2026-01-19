#!/usr/bin/env bash
set -euo pipefail

# --------- USER SETTINGS ----------
MANAGER_IP="${MANAGER_IP:-192.168.10.100}"
ENROLL_PASS="${ENROLL_PASS:-ChangeMe_StrongPassword123!}"
AGENT_NAME="${AGENT_NAME:-$(hostname -s)}"
AGENT_GROUP="${AGENT_GROUP:-default}"
WAZUH_VERSION="${WAZUH_VERSION:-4.14}"   # repo major/minor line
# ----------------------------------

log() { echo -e "[+] $*"; }
err() { echo -e "[!] $*" >&2; }

if [[ $EUID -ne 0 ]]; then
  err "Run as root: sudo -E $0"
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

log "Installing wazuh-agent..."
apt-get install -y wazuh-agent

log "Configuring agent to talk to manager ${MANAGER_IP}..."
OSSEC_CONF="/var/ossec/etc/ossec.conf"
if [[ ! -f "$OSSEC_CONF" ]]; then
  err "Missing $OSSEC_CONF (agent install failed?)"
  exit 1
fi

# Replace existing manager address if present
sed -i "s|<address>.*</address>|<address>${MANAGER_IP}</address>|" "$OSSEC_CONF"

log "Enrolling agent '${AGENT_NAME}' (group: '${AGENT_GROUP}') with manager ${MANAGER_IP}:1515 ..."
systemctl stop wazuh-agent || true
rm -f /var/ossec/etc/client.keys || true

/var/ossec/bin/agent-auth -m "${MANAGER_IP}" -p 1515 -P "${ENROLL_PASS}" -A "${AGENT_NAME}" -G "${AGENT_GROUP}"

log "Starting wazuh-agent..."
systemctl enable wazuh-agent >/dev/null
systemctl restart wazuh-agent

log "Checking status..."
systemctl --no-pager --full status wazuh-agent | sed -n '1,12p'

log "Done. If it shows as disconnected, check manager ports 1514/1515 and enrollment password."
