#!/usr/bin/env bash
set -euo pipefail

APP_TITLE="CPU Power Toggle — Madison Tools"

SVC_65="ryzenadj-65w.service"
SVC_75="ryzenadj-75w.service"
SVC_85="ryzenadj-85w.service"

# ---------------- helpers ----------------

disable_all() {
  sudo systemctl disable --now "$SVC_65" >/dev/null 2>&1 || true
  sudo systemctl disable --now "$SVC_75" >/dev/null 2>&1 || true
  sudo systemctl disable --now "$SVC_85" >/dev/null 2>&1 || true
}

count_active() {
  systemctl show -p ActiveState "$SVC_65" "$SVC_75" "$SVC_85" \
    | grep -c 'ActiveState=active' || true
}

confirm() {
  zenity --info --title="$APP_TITLE" --text="$1" || true
}

warn_fixing() {
  zenity --warning --title="$APP_TITLE" --text="More than one profile was active.\n\nFixing now…" || true
}

# ---------------- safety check ----------------

ACTIVE_COUNT="$(count_active)"

if [ "$ACTIVE_COUNT" -gt 1 ]; then
  warn_fixing
  disable_all
fi

# ---------------- menu ----------------

CHOICE=$(zenity --list \
  --title="$APP_TITLE" \
  --text="Select CPU power profile:" \
  --column="Profile" \
  "Stock (Disable limits)" \
  "65W (Quiet / Efficient)" \
  "75W (Balanced)" \
  "85W (Max Performance)" \
  --height=300 \
  --width=400) || exit 0

# ---------------- action ----------------

case "$CHOICE" in
  "Stock (Disable limits)")
    disable_all
    confirm "CPU power limits disabled.\n\nSystem returned to stock behavior."
    ;;

  "65W (Quiet / Efficient)")
    disable_all
    sudo systemctl enable --now "$SVC_65"
    confirm "65W profile enabled."
    ;;

  "75W (Balanced)")
    disable_all
    sudo systemctl enable --now "$SVC_75"
    confirm "75W profile enabled."
    ;;

  "85W (Max Performance)")
    disable_all
    sudo systemctl enable --now "$SVC_85"
    confirm "85W profile enabled."
    ;;

  *)
    exit 0
    ;;
esac

# ---------------- final verification ----------------

FINAL_ACTIVE="$(count_active)"

if [ "$FINAL_ACTIVE" -gt 1 ]; then
  zenity --error --title="$APP_TITLE" \
    --text="Unexpected state detected.\n\nMultiple profiles active.\nPlease report this." || true
fi
