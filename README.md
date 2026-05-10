# set_ttl
macOS Network TTL & MTU Configurator
A bash script for macOS that changes TTL and MTU network parameters and saves them permanently via Launch Daemon (survives reboots).
Features

Sets TTL for IPv4 (net.inet.ip.ttl) and IPv6 (net.inet6.ip6.hlim)
Sets MTU for Wi-Fi (en0) and Ethernet (en1)
Creates a Launch Daemon so settings persist after reboot
Works on Apple Silicon (M1/M2) and Intel Macs

Requirements

macOS 12 or later
Terminal with sudo access

Usage
bashchmod +x set_ttl.sh
sudo bash set_ttl.sh
The script will prompt for:

TTL value (default: 65)
MTU value (default: 1500)

Common TTL values
ValueUse case64macOS/Linux default65Tethering bypass128Windows default
Notes

Settings are applied immediately without reboot
Launch Daemon is saved to /Library/LaunchDaemons/set-ttl.plist
To remove: sudo launchctl unload /Library/LaunchDaemons/set-ttl.plist && sudo rm /Library/LaunchDaemons/set-ttl.plist
