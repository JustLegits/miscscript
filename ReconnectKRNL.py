import os
import json
import time

# Chỉ đọc status.txt ở đây
STATUS_FILE = "/data/data/com.roblox.client/files/krnl/workspace/status.txt"

# Lưu config ở nơi Termux có quyền
CONFIG_PATH = "/data/data/com.termux/files/home/reconnect_config.txt"

DEFAULT_CONFIG = {
    "place_id": "",
    "vip_server_link": "",
    "check_interval": 300  # giây
}

def load_config():
    if not os.path.exists(CONFIG_PATH):
        save_config(DEFAULT_CONFIG)
        return DEFAULT_CONFIG
    with open(CONFIG_PATH, "r") as f:
        return json.load(f)

def save_config(config):
    with open(CONFIG_PATH, "w") as f:
        json.dump(config, f)

def kill_roblox():
    os.system("su -c 'pkill -f \"com.roblox.client\"'")
    print("✅ Đã tắt Roblox")

def rejoin_game(place_id):
    os.system(f'am start -a android.intent.action.VIEW -d "roblox://placeId={place_id}"')
    print(f"✅ Đã mở lại Roblox (PlaceID: {place_id})")

def should_rejoin(last_ts, current_ts, threshold=120):
    return (current_ts - last_ts) > threshold

def read_status_timestamp():
    try:
        with open(STATUS_FILE, "r") as f:
            return int(f.read().strip())
    except:
        return 0

def config_menu():
    config = load_config()
    print("\n=== Chỉnh cấu hình ===")
    config["place_id"] = input(f"PlaceID [{config['place_id']}]: ") or config["place_id"]
    config["vip_server_link"] = input(f"VIP Server Link (nếu có) [{config['vip_server_link']}]: ") or config["vip_server_link"]
    try:
        interval = int(input(f"Thời gian kiểm tra (giây) [{config['check_interval']}]: ") or config["check_interval"])
        config["check_interval"] = interval
    except:
        pass
    save_config(config)
    print("Đã lưu cấu hình.")

def main_loop():
    config = load_config()
    print("Đang chạy tự động kiểm tra...")
    while True:
        last = read_status_timestamp()
        now = int(time.time())
        if should_rejoin(last, now):
            print("[!] Mất kết nối - rejoin...")
            kill_roblox()
            time.sleep(3)
            rejoin_game(config["place_id"])
        else:
            print("[+] Online bình thường.")
        time.sleep(config["check_interval"])

if __name__ == "__main__":
    print("1. Cấu hình")
    print("2. Chạy")
    try:
        choice = input("Chọn: ").strip()
    except:
        choice = "2"
    if choice == "1":
        config_menu()
    else:
        main_loop()
