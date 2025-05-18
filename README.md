# Nibiru
Nibiru Chain (NIBI) is a Layer 1 blockchain and smart contract ecosystem designed to provide high-performance and high-security blockchain services.

# 🌟 Nibiru Setup & Upgrade Scripts

A collection of automated scripts for setting up and upgrading Nibiru nodes on **Mainnet (`cataclysm-1`)**.

---

### ⚙️ Validator Node Setup  
Install a Nibiru validator node with custom ports, snapshot download, and systemd service configuration.

~~~bash
source <(curl -s https://raw.githubusercontent.com/validexisinfra/Nibiru/main/installmain.sh)
~~~
---

### 🔄 Validator Node Upgrade 
Upgrade your Nibiru node binary and safely restart the systemd service.

~~~bash
source <(curl -s https://raw.githubusercontent.com/validexisinfra/Nibiru/main/upgrademain.sh)
~~~

---

### 🧰 Useful Commands

| Task            | Command                                 |
|-----------------|------------------------------------------|
| View logs       | `journalctl -u nibid -f -o cat`        |
| Check status    | `systemctl status nibid`              |
| Restart service | `systemctl restart nibid`             |
