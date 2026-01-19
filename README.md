# wazuh-agent-onboarding

Wazuh Agent Onboarding Script (Linux)

This repository provides a clean, automated script to install, enroll, and activate the Wazuh agent on Linux systems using Wazuh’s official deployment variables method.

The script is designed for:

🧪 Home labs

🛡️ SOC / Blue Team practice

🔁 Repeatable VM onboarding

🌐 GitHub-hosted, pull-and-run deployments

✨ What This Script Does

When executed on a Linux VM, the script will:

Install required system dependencies

Add the official Wazuh APT repository and GPG key

Install the Wazuh agent package

Enroll the agent automatically with the Wazuh Manager

Enable and start the agent service

Perform a basic health check

✅ No manual key exchange or post-install configuration is required.

🧱 Requirements
Supported Systems

Ubuntu 20.04 / 22.04 (tested)

Debian-based systems (should work)

Network Requirements

The target VM must be able to reach the Wazuh Manager on the following ports:

Port	Protocol	Purpose
1515	TCP	Agent enrollment
1514	TCP	Agent communication

If you are using pfSense or another firewall, ensure these ports are allowed between the agent and the manager.

🔐 About the Enrollment Password (IMPORTANT)

The script requires an agent enrollment password.

👉 This is NOT the Wazuh Dashboard (UI) password.

It is configured on the Wazuh Manager for agent enrollment

Used only once during agent registration

After enrollment, the agent authenticates using cryptographic keys

Think of it as a join token, not an admin credential.

🚀 Quick Install (Recommended)

Run the following command on a new Linux VM:

sudo -E MANAGER_IP=192.168.10.100 ENROLL_PASS='YourEnrollPassword' \
bash -c "$(curl -fsSL https://raw.githubusercontent.com/<YOUR_GITHUB_USERNAME>/wazuh-agent-onboarding/main/install_wazuh_agent.sh)"

🔧 Environment Variables
Variable	Description
MANAGER_IP	IP address of the Wazuh Manager
ENROLL_PASS	Agent enrollment password
AGENT_NAME	(Optional) Agent name (defaults to hostname)
AGENT_GROUP	(Optional) Wazuh agent group (default: default)
WAZUH_VERSION	(Optional) Wazuh repo version (default: 4.14)
Example: Custom Agent Name and Group
sudo -E MANAGER_IP=192.168.10.100 \
ENROLL_PASS='YourEnrollPassword' \
AGENT_NAME='web-server-01' \
AGENT_GROUP='linux-servers' \
bash -c "$(curl -fsSL https://raw.githubusercontent.com/<YOUR_GITHUB_USERNAME>/wazuh-agent-onboarding/main/install_wazuh_agent.sh)"

✅ Verifying Successful Enrollment
On the Agent
sudo tail -n 50 /var/ossec/logs/ossec.log


You should see:

Connected to the server (192.168.10.100):1514

On the Wazuh Manager
sudo /var/ossec/bin/agent_control -lc


The agent should appear as Active.

In the Wazuh Dashboard

Navigate to Endpoints → Agents

Confirm:

Status: Active

Last keep alive: Current

🛠 Troubleshooting
Agent installs but shows “Disconnected”

Check that:

The manager is reachable on ports 1514 and 1515

The enrollment password is correct

There are no duplicate agents from reused VM snapshots

Reusing VM Snapshots

The script removes any existing agent keys before enrollment to avoid duplicate or stale registrations.

🧠 Design Notes

Uses Wazuh’s official deployment variables (cleaner and recommended)

Avoids manual editing of ossec.conf

Avoids interactive key management

Suitable for GitHub-hosted, one-line installs

📚 References

Wazuh Agent Installation (Linux):
https://documentation.wazuh.com/current/installation-guide/wazuh-agent/wazuh-agent-package-linux.html

👤 Author

Created for lab automation, SOC practice, and repeatable infrastructure builds.
