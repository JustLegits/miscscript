import os
import json
import time

CONFIG_PATH = "/sdcard/roblox_status/config.json"
STATUS_PATH = "/sdcard/roblox_status/status.txt"

def load_config():
    if not os.path.exists(CONFIG_PATH):
        return None
    with open(CONFIG_PATH, "r") as f:
        return json.load(f)

def save_config(config):
    with open(CONFIG_PATH, "w") as f:
        json.dump(config, f)

def setup_config():
    os.makedirs("/sdcard/roblox_status", exist_ok=True)
    print("[*] Cấu hình ban đầu")
    place_id = input("Nhập Place ID: ").strip()
    vip_server = input("Nhập VIP Server Link (nếu có, Enter nếu không): ").strip()
    delay = int(input("Nhập thời gian kiểm tra (phút): ").strip())
    config = {
        "place_id": place_id,
        "vip_server": vip_server,
        "delay": delay
    }
    save_config(config)
    return config

def reset_config():
    if os.path.exists(CONFIG_PATH):
        os.remove(CONFIG_PATH)
    return setup_config()

def show_menu():
    if not os.path.exists(CONFIG_PATH):
        return setup_config()

    while True:
        print("\n--- Menu ---")
        print("1. Tiếp tục với cấu hình hiện tại")
        print("2. Reset cấu hình")
        print("3. Thoát")
        choice = input("Chọn: ").strip()
        if choice == "1":
            return load_config()
        elif choice == "2":
            return reset_config()
        elif choice == "3":
            exit()
        else:
            print("Lựa chọn không hợp lệ.")

def read_status_time():
    try:
        with open(STATUS_PATH, "r") as f:
            return int(f.read().strip())
    except Exception as e:
        print(f"[!] Lỗi khi đọc file: {e}")
        return None

def launch_roblox(place_id):
    print("[!] Bắt đầu rejoin...")
    os.system("pkill -f com.roblox.client")
    os.system(f"am start -n com.roblox.client/com.roblox.client.ActivityNativeMain -d 'roblox://placeID={place_id}'")

def main():
    config = show_menu()
    print("[*] Bắt đầu theo dõi...")
    while True:
        now = int(time.time())
        last_online = read_status_time()
        if last_online is None or now - last_online > 120:
            launch_roblox(config.get("place_id"))
        time.sleep(config.get("delay", 5) * 60)

if __name__ == "__main__":
    main()
