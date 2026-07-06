#!/bin/bash

# ═══════════════════════════════════════════════════════════
#  MASTER PHONE POPULATOR
#  Downloads pics + generates fake contacts + pushes to ADB
# ═══════════════════════════════════════════════════════════

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

banner() {
  echo -e "\n${CYAN}┌──────────────────────────────────────────────────────────┐${NC}"
  printf "${CYAN}│${NC}  ${BOLD}%-46s${NC} ${CYAN}│${NC}\n" "$1"
  echo -e "${CYAN}└──────────────────────────────────────────────────────────┘${NC}"
}

step() {
  echo -e "\n${GREEN}▸ ${BOLD}$1${NC}"
  echo -e "${DIM}────────────────────────────────────────────────────${NC}"
}

ok()   { echo -e "  ${GREEN}✔${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; }
fail() { echo -e "  ${RED}✘${NC} $1"; exit 1; }
spinner() {
  local pid=$1 msg=$2
  local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r  ${CYAN}%s${NC} %s" "${spin:$i:1}" "$msg"
    i=$(( (i+1) % ${#spin} ))
    sleep 0.1
  done
  printf "\r  ${GREEN}✔${NC} %-60s\n" "$msg"
}

# ── Pre-flight ──────────────────────────────────────────────
check_prereqs() {
  banner "SYSTEM CHECK"
  local missing=0
  for cmd in adb node curl python3; do
    if command -v "$cmd" &>/dev/null; then
      ok "$cmd found"
    else
      fail "$cmd not found — install it first"
      missing=1
    fi
  done

  adb get-state 1>/dev/null 2>&1 || fail "No device connected — run 'adb devices'"
  ok "Device: $(adb devices | awk 'NR==2{print $1}')"

  [ -f "generate.mjs" ] || fail "generate.mjs not found"
  ok "generate.mjs found"

  [ -f "rename_timestamps.py" ] && ok "rename_timestamps.py found" || warn "rename_timestamps.py missing — skipping rename step"

  node -e "require('@faker-js/faker')" 2>/dev/null || fail "@faker-js/faker not installed — run: npm install @faker-js/faker"
  ok "@faker-js/faker ready"
}

read_number() {
  local prompt="$1" default="$2"
  read -p "  ${YELLOW}?${NC} $prompt [${BOLD}$default${NC}]: " n
  echo "${n:-$default}"
}

# ── Download pictures ───────────────────────────────────────
download_pics() {
  local count=$1
  step "DOWNLOADING ${count} PICTURES"

  local existing existing=0
  for f in img_*.jpg; do [ -f "$f" ] && existing=$((existing + 1)); done

  if [ "$existing" -gt 0 ]; then
    warn "$existing images already exist — skipping download"
    echo "  ${DIM}Delete them first if you want fresh ones: rm -f img_*.jpg${NC}"
    return
  fi

  (
    for i in $(seq 1 "$count"); do
      curl -sL --connect-timeout 10 --max-time 30 \
        "https://picsum.photos/1200/800?random=$((RANDOM + i))" \
        -o "img_$(printf "%04d" "$i").jpg" 2>/dev/null &
    done
    wait
  )
  ok "Downloaded $count images"
}

# ── Generate contacts ───────────────────────────────────────
gen_contacts() {
  local count=$1 style=$2 split=$3
  step "GENERATING ${count} FAKE CONTACTS (${style})"
  if [ "$style" = "mixed" ]; then
    echo "  ${DIM}Split: ${split}% Indian / $((100 - split))% Western${NC}"
  fi
  node generate.mjs "$count" "$style" "$split" 2>/dev/null || fail "generate.mjs failed"
  ok "contacts_fake.vcf + fake-users.json generated"
}

# ── Push images to phone ────────────────────────────────────
push_pics() {
  step "PUSHING IMAGES TO DEVICE"

  local folders=(
    "/sdcard/DCIM/Camera/"
    "/sdcard/Pictures/"
    "/sdcard/Download/"
    "/sdcard/Movies/"
    "/sdcard/Music/"
    "/sdcard/Documents/"
    "/sdcard/WhatsApp/Media/WhatsApp Images/"
    "/sdcard/WhatsApp/Media/WhatsApp Images/Sent/"
    "/sdcard/WhatsApp/Media/WhatsApp Video/"
    "/sdcard/Telegram/Telegram Images/"
    "/sdcard/Telegram/Telegram Video/"
  )

  echo "  ${DIM}Creating directories...${NC}"
  for dir in "${folders[@]}"; do
    adb shell "mkdir -p '$dir'" 2>/dev/null
  done
  ok "Directories ready"

  local total pushed=0 failed=0
  total=$(find . -maxdepth 1 -name '*.jpg' | wc -l)
  [ "$total" -eq 0 ] && warn "No images to push" && return

  echo "  ${DIM}Pushing $total images to random folders...${NC}"
  for f in *.jpg; do
    [ -f "$f" ] || continue
    local dir="${folders[$((RANDOM % ${#folders[@]}))]}"
    if adb push "$f" "$dir" >/dev/null 2>&1; then
      pushed=$((pushed + 1))
    else
      failed=$((failed + 1))
    fi
    printf "\r  ${GREEN}◆${NC} %d/%d pushed" "$pushed" "$total"
  done

  echo
  ok "$pushed images pushed to device"
  [ "$failed" -gt 0 ] && warn "$failed failed"
}

# ── Push contacts ───────────────────────────────────────────
push_contacts() {
  step "PUSHING CONTACTS VCF"
  adb push contacts_fake.vcf "/sdcard/Download/" >/dev/null 2>&1 || fail "Failed to push VCF"
  ok "contacts_fake.vcf → /sdcard/Download/"
  warn "Open Contacts app → Import from SD card → contacts_fake.vcf"
}

# ── Rename & timestamp ──────────────────────────────────────
fix_timestamps() {
  if [ ! -f "rename_timestamps.py" ]; then
    warn "rename_timestamps.py not found — skipping rename/timestamp step"
    return
  fi
  step "RENAMING FILES + SETTING TIMESTAMPS"
  echo "  ${DIM}This may take a while depending on file count...${NC}"
  python3 rename_timestamps.py 2>/dev/null || warn "rename_timestamps.py had errors"
  ok "Filenames & timestamps updated"
}

# ── Refresh media store ─────────────────────────────────────
refresh_media() {
  step "REFRESHING MEDIA STORE"
  adb shell content call --method scan_volume --uri content://media --arg external_primary >/dev/null 2>&1
  adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/ >/dev/null 2>&1
  ok "Media store refreshed — images will appear in gallery"
}

# ═════════════════════════════════════════════════════════════
#  MAIN
# ═════════════════════════════════════════════════════════════

clear
echo -e "${CYAN}"
echo '  ╔═══════════════════════════════════════════════╗'
echo '  ║        MASTER PHONE POPULATOR v2              ║'
echo '  ║   pics + contacts + adb push — one shot       ║'
echo '  ╚═══════════════════════════════════════════════╝'
echo -e "${NC}"

check_prereqs

echo -e "\n${BOLD}Configuration${NC}"
echo -e "${DIM}────────────────────────────────────────────────────${NC}"
pic_c=$(read_number "How many pics to download?" 50)
con_c=$(read_number "How many fake contacts?" 100)

echo -e "\n  ${BOLD}Name style${NC}"
echo "    ${DIM}1${NC}) Indian names only"
echo "    ${DIM}2${NC}) Western names only"
echo "    ${DIM}3${NC}) Mixed Indian + Western"
read -p "  ${YELLOW}?${NC} Choice [1-3] [${BOLD}3${NC}]: " style_choice

case "${style_choice:-3}" in
  1) style="indian"; split="" ;;
  2) style="western"; split="" ;;
  *)
    style="mixed"
    split=$(read_number "What % Indian? (0–100)" 50)
    [ "$split" -gt 100 ] && split=100
    [ "$split" -lt 0 ] && split=0
    ;;
esac

# ── Execute pipeline ────────────────────────────────────────
echo -e "\n${BOLD}${CYAN}Starting pipeline...${NC}"
download_pics "$pic_c"
gen_contacts "$con_c" "$style" "$split"
push_pics
push_contacts
fix_timestamps
refresh_media

# ── Done ─────────────────────────────────────────────────────
echo -e "\n${GREEN}${BOLD}  ✔  ALL DONE  ✔${NC}"
echo -e "${DIM}────────────────────────────────────────────────────${NC}"
echo "  Images   → DCIM / Pictures / WhatsApp / Telegram"
echo "  Contacts → Import from /sdcard/Download/contacts_fake.vcf"
echo -e "${DIM}────────────────────────────────────────────────────${NC}"
