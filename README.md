# Firewall Rules (Surge v5 + Generated Scripts)

This repo keeps Surge v5 firewall modules as the source of truth and generates
Linux/Windows scripts to apply equivalent allowlists.

## Structure
- `ios/` contains the Surge v5 modules.
- `linux/apply-firewall.sh` is generated from the iOS modules.
- `windows/apply-firewall-ps6.ps1` and `windows/apply-firewall-ps7.ps1` are generated
  PowerShell scripts for Windows Firewall.
- `generate_linux_firewall.py` rebuilds the Linux and Windows scripts.

## Usage (iOS)
1. Add the modules in `ios/` as local modules in Surge.
2. Place them after other rule modules so the allowlists are applied as intended.

## Usage (Linux)
Regenerate and apply the firewall:
```bash
python generate_linux_firewall.py
sudo ./linux/apply-firewall.sh
```

## Usage (Windows)
Run as Administrator:
```powershell
.\windows\apply-firewall-ps7.ps1
```
Or use the PS6 script if you are running PowerShell 6.

## Notes
- These scripts set outbound firewall rules to only allow the listed domains and
  suffixes; `Enforce` blocks other outbound traffic.
- `DOMAIN-SUFFIX` rules on Linux require the `--dnsmasq` mode so DNS resolution
  populates ipset for suffix matches.

## Requirements
- Python 3.8+ to run the generator.
- Linux: `iptables`, `ipset`, and `getent` (from `glibc`/`libc` utilities). For
  suffix matching, install `dnsmasq` and run `./linux/apply-firewall.sh --dnsmasq`.
- Windows: PowerShell 6 or 7 as indicated by the script name; run as Administrator.
  The scripts use `New-NetFirewallRule -RemoteFqdn`.

## Reverting
- Linux: remove the chain and ipsets or switch to allow-all:
  ```bash
  sudo iptables -D OUTPUT -j FIREWALL_ALLOW
  sudo iptables -F FIREWALL_ALLOW
  sudo iptables -X FIREWALL_ALLOW
  sudo ipset destroy firewall_allow_v4
  sudo ipset destroy firewall_allow_v6
  ```
- Windows: remove rules and restore outbound default:
  ```powershell
  Get-NetFirewallRule -Group SurgeFirewall | Remove-NetFirewallRule
  Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultOutboundAction Allow
  ```
