#!/usr/bin/env bash
set -e

choice="$(zenity --list \
  --title="CPU Power Toggle — Madison Tools" \
  --text="Select CPU power profile:" \
  --radiolist \
  --column="Pick" --column="Profile" \
  TRUE  "75W (Performance)" \
  FALSE "65W (Cool/Quiet)" \
  FALSE "85W (Max)" \
  FALSE "Stock / Normal (Disable caps)")" || exit 0

disable_all() {
  sudo systemctl disable --now ryzenadj-65w.service ryzenadj-75w.service ryzenadj-85w.service 2>/dev/null || true
  zenity --info --title="Stock/Normal" --text="Power caps disabled.\n\nReboot recommended to fully return to stock behavior."
}

apply_service() {
  sudo systemctl disable --now ryzenadj-65w.service ryzenadj-75w.service ryzenadj-85w.service 2>/dev/null || true
  sudo systemctl enable --now "$1"
}

case "$choice" in
  "65W (Cool/Quiet)") apply_service ryzenadj-65w.service ;;
  "75W (Performance)") apply_service ryzenadj-75w.service ;;
  "85W (Max)") apply_service ryzenadj-85w.service ;;
  "Stock / Normal (Disable caps)") disable_all ;;
esac
