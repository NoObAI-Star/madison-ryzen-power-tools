#!/usr/bin/env bash
set -e

echo "Removing Madison Ryzen Power Tools..."

sudo systemctl disable --now ryzenadj-65w.service ryzenadj-75w.service ryzenadj-85w.service 2>/dev/null
sudo rm -f /etc/systemd/system/ryzenadj-*.service
sudo rm -f /etc/sudoers.d/ryzenadj-toggle
sudo rm -f /usr/local/bin/ryzenadj

rm -f ~/.local/share/applications/ryzen-power-toggle.desktop
rm -f ~/Desktop/ryzen-power-toggle.desktop
rm -f ~/bin/ryzen-power-toggle.sh

sudo systemctl daemon-reload
echo "Uninstalled."
