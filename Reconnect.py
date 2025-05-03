import os
import time
import json

CONFIG_PATH = "/sdcard/roblox_status/config.json"
STATUS_PATH = "/sdcard/roblox_status/status.txt"
DEFAULT_CONFIG = {
    "place_id": "",
    "vip_server": "",
    "check_delay": 300  # 5 phút mặc định
}
TIMEOUT_SECONDS = 120

def ensure_setup():
    folder = os.path.dirname(STATUS_PATH)
    if not os.path.exists(folder):
        os.makedirs(folder)
    if not os.path.exists(STATUS_PATH):
        with open(STATUS_PATH, "w") as f:
            f.write(str(int(time.time())))
    if not os.path.exists(CONFIG_PATH):
        with open(CONFIG_PATH, "w") as f:
            json.dump(DEFAULT_CONFIG, f, indent=2)

def load_config():
    with open(CONFIG_PATH, "r") as f:
        return json.load(f)

def save_config(config):
    with open(CONFIG_PATH, "w") as f:
        json.dump(config, f, indent=2)

def reset_config():
    save_config(DEFAULT_CONFIG)
    print("Đã reset cấu hình về mặc định.")

def config_menu():
    while True:
        print("\n==== CẤU HÌNH ====")
        print("1. Đặt Place ID")
        print("2. Đặt VIP Server Link")
        print("3. Đặt thời gian kiểm tra (giây)")
        print("4. Reset cấu hình")
        print("5. Bắt đầu theo dõi")
        choice = input("Chọn: ").strip()

        config = load_config()

        if choice == "1":
            config["place_id"] = input("Nhập Place ID: ")
        elif choice == "2":
            config["vip_server"] = input("Nhập link server VIP: ")
        elif choice == "3":
            delay = input("Nhập thời gian kiểm tra (giây): ")
            if delay.isdigit():
                config["check_delay"] = int(delay)
        elif choice == "4":
            reset_config()
            continue
        elif choice == "5":
            save_config(config)
            return config
        else:
            print("Lựa chọn không hợp lệ.")
            continue

        save_config(config)
        print("Đã lưu cấu hình.")

def read_timestamp():
    try:
        with open(STATUS_PATH, "r") as f:
            return int(f.read().strip())
    except:
        return 0

def rejoin():
    print("[!] Mất kết nối - Thực hiện rejoin...")
    # Gọi lệnh rejoin thực tế ở đây
    os.system("echo 'REJOIN GAME'")

# === Main ===
ensure_setup()
config = config_menu()

while True:
    timestamp = read_timestamp()
    now = int(time.time())
    delay = now - timestamp

    if delay > TIMEOUT_SECONDS:
        rejoin()
    else:
        print(f"[✓] Đang online, lệch thời gian: {delay}s")

    time.sleep(config["check_delay"])
