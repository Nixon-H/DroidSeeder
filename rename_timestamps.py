import subprocess
import random
from datetime import datetime, timedelta

# Target directories on your device
folders = [
    "/sdcard/DCIM/Camera/",
    "/sdcard/Pictures/",
    "/sdcard/Download/",
    "/sdcard/Movies/",
    "/sdcard/Music/",
    "/sdcard/Documents/",
    "/sdcard/WhatsApp/Media/WhatsApp Images/",
    "/sdcard/WhatsApp/Media/WhatsApp Images/Sent/",
    "/sdcard/WhatsApp/Media/WhatsApp Video/",
    "/sdcard/Telegram/Telegram Images/",
    "/sdcard/Telegram/Telegram Video/"
]

print("🚀 Starting true file conversion and timeline synchronization...")

for folder in folders:
    print(f"Fixing folder: {folder}")
    
    # Grab the current file list from the emulator
    cmd = f"adb shell \"ls -1 '{folder}' 2>/dev/null\""
    proc = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    
    if proc.returncode != 0 or not proc.stdout.strip():
        continue
        
    filenames = [line.strip() for line in proc.stdout.split('\n') if line.strip()]
    
    for filename in filenames:
        # Ignore files that are already renamed properly
        if "IMG_" in filename or "Screenshot_" in filename or "photo_" in filename or "WA" in filename:
            continue
            
        # 1. Generate a completely random date within the last 365 days
        random_days = random.randint(1, 365)
        random_date = datetime.now() - timedelta(days=random_days)
        
        file_date = random_date.strftime("%Y%m%d")
        file_time = random_date.strftime("%H%M%S")
        touch_timestamp = random_date.strftime("%Y%m%d%H%M.%S")
        
        # 2. Pick a realistic name template based on the destination directory location
        if "DCIM/Camera" in folder:
            new_name = f"IMG_{file_date}_{file_time}.jpg"
        elif "Pictures" in folder:
            new_name = f"Screenshot_{file_date}-{file_time}_System.jpg"
        elif "WhatsApp" in folder:
            # Generate a random 4-digit ID for WhatsApp structure uniformity
            wa_id = random.randint(1000, 9999)
            new_name = f"IMG-{file_date}-WA{wa_id}.jpg"
        elif "Telegram" in folder:
            new_name = f"photo_{file_date}_{file_time}.jpg"
        else:
            new_name = f"download_{file_date}_{random.randint(100,999)}.jpg"
            
        old_path = f"{folder}{filename}"
        new_path = f"{folder}{new_name}"
        
        # 3. Execute rename (mv) and system date touch over ADB execution channels
        mv_cmd = f"adb shell \"mv '{old_path}' '{new_path}' 2>/dev/null\""
        subprocess.run(mv_cmd, shell=True, capture_output=True)
        
        touch_cmd = f"adb shell \"touch -m -t {touch_timestamp} '{new_path}' 2>/dev/null\""
        subprocess.run(touch_cmd, shell=True, capture_output=True)
        
        print(f"  🔄 Renamed & Timestamps Set: {filename} ➔ {new_name}")

print("\n♻️ Re-indexing Android storage registry maps...")
subprocess.run("adb shell content call --method scan_volume --uri content://media --arg external_primary", shell=True, capture_output=True)
subprocess.run("adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/", shell=True, capture_output=True)

print("🎉 Complete! Your emulator files are renamed realistically and spread across the timeline.")
