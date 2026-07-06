# DroidSeeder

**ADB phone populator** — seeds fake photos and contacts onto Android devices to make them look lived-in. Useful for testing, OSINT research, or device provisioning.

## What it does

| Step | Action |
|------|--------|
| 1 | Downloads N random photos from picsum.photos |
| 2 | Generates N fake contacts (Indian / Western / Mixed) with realistic names, phones, emails, addresses |
| 3 | Pushes photos to random folders on device — DCIM, WhatsApp, Telegram, Downloads, etc. |
| 4 | Pushes contacts as VCF for easy import |
| 5 | Renames files with real-looking names (`IMG_20250321_*.jpg`, `Screenshot_*`, `WA_*`) |
| 6 | Sets random timestamps across the last 365 days |
| 7 | Refreshes Android media store so content appears in gallery |

## Files

```
DroidSeeder/
├── master.sh              ← One-shot runner (bash master.sh)
├── generate.mjs           ← Fake contact generator (Node.js)
├── rename_timestamps.py   ← Renames files + sets timestamps on device
└── .archive/              ← Old scripts / previous downloads (ignored)
```

## Requirements

- `adb` — Android Debug Bridge (device must be connected)
- `node` — for contact generation
- `curl` — for photo downloads
- `python3` — for rename/timestamp step
- `@faker-js/faker` — `npm install @faker-js/faker` in the repo dir

## Usage

```bash
cd DroidSeeder
bash master.sh
```

You'll be prompted for:
- Number of photos to download
- Number of fake contacts
- Name style (Indian / Western / Mixed with % split)

After push, open **Contacts → Import from SD card** on the phone to load the VCF.

## License

MIT
