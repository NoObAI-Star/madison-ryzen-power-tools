#!/usr/bin/env bash
set -euo pipefail

APP_TITLE="CPU Power Toggle — Madison Tools"

SVC_65="ryzenadj-65w.service"
SVC_75="ryzenadj-75w.service"
SVC_85="ryzenadj-85w.service"

disable_all() {
  sudo systemctl disable --now "$SVC_65" "$SVC_75" "$SVC_85" >/dev/null 2>&1 || true
}

enable_one() {
  local svc="$1"
  disable_all
  sudo systemctl enable --now "$svc"
}

# Auto-fix if multiple profiles are active before showing UI
count_active=$(systemctl is-active "$SVC_65" "$SVC_75" "$SVC_85" 2>/dev/null | grep -c '^active$' || true)
if [ "${count_active:-0}" -gt 1 ]; then
  zenity --warning --title="$APP_TITLE" --text="More than one profile is active.\n\nFixing now..." || true
  disable_all
fi

choice=$(zenity --list \
  --radiolist \
  --title="$APP_TITLE" \
  --text="Select CPU power profile:" \
  --column="Pick" --column="Profile" \
  TRUE  "75W (Performance)" \
  FALSE "65W (Cool/Quiet)" \
  FALSE "85W (Max)" \
  FALSE "Stock / Normal (Disable caps)" \
  --width=520 --height=300)

[ -z "${choice:-}" ] && exit 0

case "$choice" in
  "65W (Cool/Quiet)")
    enable_one "$SVC_65"
    zenity --info --title="$APP_TITLE" --text="Applied: 65W (Cool/Quiet)" || true
    ;;
  "75W (Performance)")
    enable_one "$SVC_75"
    zenity --info --title="$APP_TITLE" --text="Applied: 75W (Performance)" || true
    ;;
  "85W (Max)")
    enable_one "$SVC_85"
    zenity --info --title="$APP_TITLE" --text="Applied: 85W (Max)" || true
    ;;
  "Stock / Normal (Disable caps)")
    disable_all
    zenity --info --title="$APP_TITLE" --text="Applied: Stock / Normal (caps disabled)" || true
    ;;
  *)
    zenity --error --title="$APP_TITLE" --text="Unknown selection: $choice" || true
    exit 1
    ;;
esac

exit 0
