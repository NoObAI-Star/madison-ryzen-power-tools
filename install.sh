#!/usr/bin/env bash
set -euo pipefail

echo "Madison Ryzen Power Tools Installer"
echo "----------------------------------"

if [ "$EUID" -ne 0 ]; then
  echo "Please run with: sudo ./install.sh"
  exit 1
fi

USER_NAME="${SUDO_USER:-$(logname 2>/dev/null || echo $USER)}"
HOME_DIR="$(getent passwd "$USER_NAME" | cut -d: -f6)"
BIN_DIR="$HOME_DIR/bin"
APP_DIR="$HOME_DIR/.local/share/applications"
DESKTOP_DIR="$HOME_DIR/Desktop"

CPU_VENDOR="$(lscpu | awk -F: '/Vendor ID/ {gsub(/ /,"",$2); print $2}')"

if [[ "$CPU_VENDOR" != "AuthenticAMD" ]]; then
  echo "ERROR: AMD Ryzen CPU required."
  exit 1
fi

echo "[1/6] Installing dependencies..."
apt-get update
apt-get install -y git build-essential cmake pkg-config libpci-dev zenity

echo "[2/6] Building RyzenAdj..."
cd "$HOME_DIR"
rm -rf RyzenAdj
git clone https://github.com/FlyGoat/RyzenAdj.git
cd RyzenAdj
mkdir -p build
cd build
cmake ..
cmake --build . -j
install -m 0755 ryzenadj /usr/local/bin/ryzenadj

echo "[3/6] Creating power profiles (65W / 75W / 85W)..."

create_service () {
cat >/etc/systemd/system/$1 <<EOF
[Unit]
Description=RyzenAdj CPU Power Limit ($2)
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/ryzenadj --stapm-limit=$3 --fast-limit=$3 --slow-limit=$3
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
}

create_service ryzenadj-65w.service "65W" 65000
create_service ryzenadj-75w.service "75W" 75000
create_service ryzenadj-85w.service "85W" 85000

systemctl daemon-reload

echo "[4/6] Allowing passwordless profile switching..."
cat >/etc/sudoers.d/ryzenadj-toggle <<EOF
${USER_NAME} ALL=(root) NOPASSWD: /bin/systemctl enable --now ryzenadj-65w.service
${USER_NAME} ALL=(root) NOPASSWD: /bin/systemctl enable --now ryzenadj-75w.service
${USER_NAME} ALL=(root) NOPASSWD: /bin/systemctl enable --now ryzenadj-85w.service
${USER_NAME} ALL=(root) NOPASSWD: /bin/systemctl disable --now ryzenadj-65w.service
${USER_NAME} ALL=(root) NOPASSWD: /bin/systemctl disable --now ryzenadj-75w.service
${USER_NAME} ALL=(root) NOPASSWD: /bin/systemctl disable --now ryzenadj-85w.service
EOF
chmod 0440 /etc/sudoers.d/ryzenadj-toggle

echo
