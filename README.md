# DroidSeeder

**Seed a fake Android environment in minutes.**  
DroidSeeder populates an Android device with realistic-looking photos, contacts, SMS threads, and call logs — making it appear like a genuinely used phone. Built for malware analysis, fake loan app investigation, stealer/Trojan testing, and red-team engagements where you need a convincing honeypot device.

## Motive

Fake loan apps, malware droppers, info-stealers, and SMS phishers often inspect the device before deploying their payload. They check:

- **Is there a real contact list?** — Empty contacts = sandbox/virtual device
- **Are there photos in DCIM/WhatsApp?** — No media = fresh setup, possibly an emulator
- **Are there SMS threads and call logs?** — Clean SMS = not a daily driver
- **Are timestamps recent and spread across folders?** — All files in one place with same date = planted

DroidSeeder defeats all of these checks. It gives you a device that looks like someone's actual phone — contacts with names, photos across WhatsApp/Telegram/DCIM, realistic filenames, and timestamps spanning months. This lets you:

- Analyse fake loan APKs that scrape contacts/photos/SMS without raising flags
- Test malware that exfiltrates gallery data or contact lists
- Run stealers in a realistic environment and observe their behaviour
- Create throwaway devices for reverse-engineering suspicious apps
- Provision burners for OSINT or undercover work

## How it works

```
┌──────────────────────────────────────────────────┐
│               DroidSeeder Pipeline                │
├──────────────────────────────────────────────────┤
│  1. Download N random photos from picsum.photos  │
│  2. Generate N fake contacts → VCF + JSON        │
│  3. Push photos to random device folders         │
│     (DCIM, WhatsApp, Telegram, Downloads, ...)   │
│  4. Push VCF to device for Contacts import       │
│  5. Rename files realistically on device         │
│     (IMG_20250321_*.jpg, Screenshot_*, WA_*)     │
│  6. Set random timestamps across last 365 days   │
│  7. Refresh Android media store                  │
└──────────────────────────────────────────────────┘
```

## Files

```
DroidSeeder/
├── master.sh              ← One-shot runner (bash master.sh)
├── generate.mjs           ← Fake contact generator (Node.js + faker)
├── rename_timestamps.py   ← Renames files + timestamps on device
├── .gitignore
└── README.md
```

## Requirements

| Tool | Purpose | Install |
|------|---------|---------|
| `adb` | Android Debug Bridge | `sudo apt install adb` (or `brew install android-platform-tools`) |
| `node` / `npm` | Contact gen (Node.js) | `sudo apt install nodejs npm` |
| `curl` | Photo downloads | preinstalled on most systems |
| `python3` | Rename + timestamp | preinstalled on most systems |

**JS dependency (one-time):**
```bash
npm install @faker-js/faker
```

**Python:** uses stdlib only (`subprocess`, `random`, `datetime`) — no pip packages needed.

**Android device must have USB debugging enabled** and authorised.  
Check with: `adb devices`

## Setup

```bash
# 1. Clone
git clone https://github.com/Nixon-H/DroidSeeder.git
cd DroidSeeder

# 2. Install the only dependency
npm install @faker-js/faker

# 3. Connect phone (enable Developer Options → USB Debugging)
adb devices
# Should show: <device_id>  device

# 4. Run
bash master.sh
```

## Usage

Running `bash master.sh` prompts you for:

1. **Photos to download** — How many pics from picsum.photos (default: 50)
2. **Fake contacts** — How many VCF contacts to generate (default: 100)
3. **Name style** — Indian, Western, or Mixed with a custom % split (e.g. 70% Indian / 30% Western)

After completion:
- **Photos** are scattered across DCIM/Camera, Pictures, Download, WhatsApp Images/Sent/Video, Telegram Images/Video, Movies, Music, Documents
- **Contacts VCF** is at `/sdcard/Download/contacts_fake.vcf` — open Contacts app → Import from SD card
- **File names** look like real phone dumps: `IMG_20250412_143022.jpg`, `Screenshot_20250321-091234_System.jpg`, `IMG-20250610-WA7821.jpg`
- **Timestamps** span the last year — photos appear chronologically mixed in gallery

### Why this matters for malware analysis

When a fake loan APK or stealer requests `READ_CONTACTS`, `READ_EXTERNAL_STORAGE`, or `READ_SMS`, DroidSeeder ensures there's actually data to exfiltrate. Instead of an empty contact book and blank gallery triggering suspicion, the malware sees a normal phone and proceeds — letting you capture its C2, exfiltration endpoints, and behavior.

## Future updates

- **Fake SMS/chat threads** — Realistic message conversations with timestamps, delivered/read receipts, group chats, and spam detection patterns matching Indian/US carriers
- **Fake call logs** — Incoming/outgoing/missed calls spread across days with realistic durations and contact names
- **Fake WhatsApp backups** — Chat databases with media references that show up in WhatsApp's backup scan
- **Fake app list** — Install APK markers so malware scanning installed packages sees real apps
- **Fake browser history** — Chrome bookmarks, search history, saved passwords database
- **Fake location history** — Google Maps Timeline entries across cities
- **Fake notifications** — Pending notification icons that appear in the status bar
- **Fake clipboard data** — Copied text, OTPs, passwords in clipboard history

## Target folders on device

```
/sdcard/DCIM/Camera/
/sdcard/Pictures/
/sdcard/Download/
/sdcard/Movies/
/sdcard/Music/
/sdcard/Documents/
/sdcard/WhatsApp/Media/WhatsApp Images/
/sdcard/WhatsApp/Media/WhatsApp Images/Sent/
/sdcard/WhatsApp/Media/WhatsApp Video/
/sdcard/Telegram/Telegram Images/
/sdcard/Telegram/Telegram Video/
```

Each file is randomly placed into one of these, then renamed and timestamped to match the folder context.

## Notes

- Tested on Android 11–17 (Pixel, Samsung, OnePlus, custom ROMs)
- Requires USB debugging enabled — no root needed
- All operations run over ADB; nothing gets installed on the device
- Photos are from picsum.photos — random stock imagery, safe for work

## License

MIT
