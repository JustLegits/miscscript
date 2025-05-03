import os
import time
import json
from datetime import datetime

STATUS_FILE = "/sdcard/roblox_status/status.txt"
CONFIG_PATH = "/sdcard/roblox_status/config.json"
TIME_THRESHOLD_SECONDS = 120  # Nếu lệch hơn 2 phút thì rejoin

def ensure_dir():
    os.makedirs("/sdcard/roblox_status", exist_ok=True)

def save_config(data):
    with open(CONFIG_PATH, "w") as f:
        json.dump(data, f)

def load_config():
    with open(CONFIG_PATH, "r") as f:
        return json.load(f)

def setup_config():
    print("⚙️ Cấu hình lần đầu:")
    place_id = input("Nhập Place ID Roblox: ").strip()
    delay = int(input("Delay kiểm tra (giây, ví dụ 300): ").strip())
    config = {
        "place_id": place_id,
        "delay": delay
    }
    save_config(config)
    print("✅ Đã lưu cấu hình.")
    return config

def kill_roblox():
    os.system("su -c 'pkill -f com.roblox.client'")
    print("✅ Đã kill Roblox")

def rejoin_game(place_id):
    print("[!] Bắt đầu rejoin...")
    os.system(f'am start -a android.intent.action.VIEW -d "roblox://placeId={place_id}"')
    print(f"✅ Đã rejoin game với Place ID: {place_id}")

def read_timestamp():
    try:
        with open(STATUS_FILE, "r") as f:
            timestamp_str = f.read().strip()
            if not timestamp_str.isdigit():
                raise ValueError("Nội dung không phải timestamp số")
            return int(timestamp_str)
    except Exception as e:
        print(f"[Lỗi] Khi đọc file: {e}")
        return None

def check_and_rejoin_if_needed(config):
    timestamp = read_timestamp()
    if timestamp is None:
        print("⚠️ Không thể đọc thời gian từ file.")
        return

    now = int(time.time())
    diff = now - timestamp
    if diff > TIME_THRESHOLD_SECONDS:
        print(f"[⚠️] Không thấy trạng thái online trong {diff} giây -> Rejoin")
        kill_roblox()
        time.sleep(2)
        rejoin_game(config["place_id"])
    else:
        print(f"✅ Online ({diff}s trước)")

def menu():
    ensure_dir()
    config = None
    if os.path.exists(CONFIG_PATH):
        config = load_config()
    else:
        config = setup_config()

    print("\n▶️ Bắt đầu kiểm tra trạng thái mỗi", config["delay"], "giây...\n")
    while True:
        check_and_rejoin_if_needed(config)
        time.sleep(config["delay"])

if __name__ == "__main__":
    print("===== ROBLOX AUTO REJOIN (LOCAL FILE MODE) =====")
    print("1. Chạy script")
    print("2. Reset cấu hình")
    choice = input("Chọn (1/2): ").strip()
    if choice == "2":
        if os.path.exists(CONFIG_PATH):
            os.remove(CONFIG_PATH)
            print("✅ Đã reset cấu hình.")
        else:
            print("⚠️ Chưa có cấu hình để reset.")
    menu()
