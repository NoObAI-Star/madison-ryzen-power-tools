#!/usr/bin/env bash
set -euo pipefail

SERVICES=(ryzenadj-65w.service ryzenadj-75w.service ryzenadj-85w.service)

disable_all() {
  sudo systemctl disable --now "${SERVICES[@]}" 2>/tmp/madison_power_err || true
}

active_now() {
  if systemctl is-active --quiet ryzenadj-65w.service; then echo "65W"; return; fi
  if systemctl is-active --quiet ryzenadj-75w.service; then echo "75W"; return; fi
  if systemctl is-active --quiet ryzenadj-85w.service; then echo "85W"; return; fi
  echo "Stock/Normal"
}

apply_service() {
  local svc="$1"
  disable_all

  # Apply and persist
  if ! sudo systemctl enable --now "$svc" 2>/tmp/madison_power_err; then
    err="$(cat /tmp/madison_power_err 2>/dev/null || true)"
    zenity --error --title="Failed" --text="Command failed while enabling:\n$svc\n\nDetails:\n${err}"
    exit 1
  fi

  # Verify only chosen service is active
  if ! systemctl is-active --quiet "$svc"; then
    err="$(cat /tmp/madison_power_err 2>/dev/null || true)"
    zenity --error --title="Failed" --text="Tried to apply $svc but it did not stay active.\n\nCurrent: $(active_now)\n\nDetails:\n${err}"
    exit 1
  fi

  # Make sure the others are NOT active
  for s in "${SERVICES[@]}"; do
    if [ "$s" != "$svc" ] && systemctl is-active --quiet "$s"; then
      zenity --warning --title="Warning" --text="More than one profile is active.\n\nCurrent: $(active_now)\n\nFixing now."
      disable_all
      sudo systemctl enable --now "$svc" >/dev/null 2>&1 || true
      break
    fi
  done

  zenity --info --title="Applied" --text="Now using: $(active_now)"
}

choice="$(zenity --list \
  --title="CPU Power Toggle — Madison Tools" \
  --text="Select CPU power profile:" \
  --radiolist \
  --column="Pick" --column="Profile" \
  TRUE  "75W (Performance)" \
  FALSE "65W (Cool/Quiet)" \
  FALSE "85W (Max)" \
  FALSE "Stock / Normal (Disable caps)")" || exit 0

case "$choice" in
  "65W (Cool/Quiet)") apply_service ryzenadj-65w.service ;;
  "75W (Performance)") apply_service ryzenadj-75w.service ;;
  "85W (Max)") apply_service ryzenadj-85w.service ;;
  "Stock / Normal (Disable caps)")
    disable_all
    zenity --info --title="Applied" --text="Stock/Normal selected (caps disabled).\n\nReboot recommended to fully return to stock behavior."
    ;;
esac
