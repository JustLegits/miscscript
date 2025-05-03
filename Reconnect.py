import os
import time
import json
from datetime import datetime

CONFIG_PATH = "/sdcard/roblox_status/config.json"
STATUS_PATH = "/sdcard/roblox_status/status.txt"

def ensure_dirs():
    os.makedirs("/sdcard/roblox_status", exist_ok=True)
    if not os.path.exists(STATUS_PATH):
        with open(STATUS_PATH, "w") as f:
            f.write("")

def load_config():
    if os.path.exists(CONFIG_PATH):
        with open(CONFIG_PATH, "r") as f:
            return json.load(f)
    return None

def save_config(config):
    with open(CONFIG_PATH, "w") as f:
        json.dump(config, f)

def reset_config():
    if os.path.exists(CONFIG_PATH):
        os.remove(CONFIG_PATH)

def menu():
    config = load_config()
    if config:
        print(f"[✓] Đã tìm thấy config:\nPlace ID: {config['placeid']}\nVIP: {config['vip']}")
        choice = input("Bạn có muốn reset config? (y/n): ").strip().lower()
        if choice == "y":
            reset_config()
            return menu()
        else:
            return config
    else:
        placeid = input("Nhập Place ID: ").strip()
        vip = input("Nhập VIP Server ID (để trống nếu không có): ").strip()
        config = {"placeid": placeid, "vip": vip}
        save_config(config)
        return config

def open_roblox(placeid, vip):
    if vip:
        url = f"roblox://placeId={placeid}&linkCode={vip}"
    else:
        url = f"roblox://placeId={placeid}"
    os.system("am force-stop com.roblox.client")
    os.system(f"am start -a android.intent.action.VIEW -d '{url}'")

def check_status():
    try:
        with open(STATUS_PATH, "r") as f:
            timestamp_str = f.read().strip()
        if not timestamp_str:
            return False
        last = datetime.strptime(timestamp_str, "%Y-%m-%d %H:%M:%S")
        now = datetime.now()
        delta = (now - last).total_seconds()
        return delta <= 120
    except:
        return False

def main():
    ensure_dirs()
    config = menu()
    print("[✓] Bắt đầu theo dõi trạng thái...")
    while True:
        if not check_status():
            print("[!] Không nhận tín hiệu, đang rejoin...")
            open_roblox(config["placeid"], config["vip"])
        else:
            print("[✓] Tín hiệu OK.")
        time.sleep(300)

if __name__ == "__main__":
    main()
