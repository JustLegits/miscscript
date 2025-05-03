import os
import time
from pathlib import Path

# ======== CẤU HÌNH ========
CONFIG_FILE = "/sdcard/roblox_status/config.txt"
STATUS_FILE = "/sdcard/roblox_status/status.txt"
CHECK_INTERVAL = 300  # 5 phút
MAX_OFFLINE_GAP = 120  # 2 phút

def setup():
    if not os.path.exists("/sdcard/roblox_status"):
        os.makedirs("/sdcard/roblox_status", exist_ok=True)

    if not os.path.exists(CONFIG_FILE):
        print("[!] Chưa có cấu hình, tiến hành nhập mới.")
        place_id = input("Nhập Place ID: ").strip()
        vip_server = input("Nhập VIP server (bỏ trống nếu không có): ").strip()
        with open(CONFIG_FILE, "w") as f:
            f.write(place_id + "\n" + vip_server)
    else:
        with open(CONFIG_FILE, "r") as f:
            lines = f.readlines()
        place_id = lines[0].strip()
        vip_server = lines[1].strip() if len(lines) > 1 else ""

    return place_id, vip_server

def read_status_time():
    try:
        with open(STATUS_FILE, "r") as f:
            timestamp = int(f.read().strip())
        return timestamp
    except Exception as e:
        print(f"[!] Lỗi khi đọc file trạng thái: {e}")
        return 0

def rejoin(place_id, vip_server):
    print("[!] Bắt đầu rejoin...")
    os.system("pkill -f com.roblox.client")
    time.sleep(2)
    os.system("monkey -p com.roblox.client -c android.intent.category.LAUNCHER 1")
    time.sleep(2)

    if vip_server:
        join_link = f"roblox://placeID={place_id}&linkCode={vip_server}"
    else:
        join_link = f"roblox://placeID={place_id}"

    os.system(f"am start -a android.intent.action.VIEW -d \"{join_link}\"")

def main():
    place_id, vip_server = setup()
    print(f"[✔] Đã cấu hình. Bắt đầu theo dõi file trạng thái mỗi {CHECK_INTERVAL // 60} phút...\n")

    while True:
        last_online = read_status_time()
        now = int(time.time())
        if now - last_online > MAX_OFFLINE_GAP:
            rejoin(place_id, vip_server)
        else:
            print("[✓] Vẫn đang online.")
        time.sleep(CHECK_INTERVAL)

if __name__ == "__main__":
    main()
