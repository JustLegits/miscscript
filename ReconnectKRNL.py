import os
import json
import time

CONFIG_PATH = "/sdcard/roblox_rejoin_config.json"
STATUS_PATH = "/data/data/com.roblox.client/files/krnl/workspace/status.txt"

DEFAULT_CONFIG = {
    "placeId": "72829404259339",
    "vipServer": "",
    "checkInterval": 300  # 5 phút (theo giây)
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

def config_menu():
    config = load_config()
    while True:
        os.system("clear")
        print("===== CẤU HÌNH REJOIN =====")
        print(f"1. placeId hiện tại     : {config['placeId']}")
        print(f"2. VIP server link      : {config['vipServer'] or '(trống)'}")
        print(f"3. Thời gian kiểm tra   : {config['checkInterval']} giây")
        print("4. Reset cấu hình")
        print("5. Thoát")
        choice = input("Chọn: ")
        if choice == "1":
            config["placeId"] = input("Nhập placeId mới: ").strip()
        elif choice == "2":
            config["vipServer"] = input("Nhập link VIP server (để trống nếu không có): ").strip()
        elif choice == "3":
            try:
                config["checkInterval"] = int(input("Nhập thời gian (giây): ").strip())
            except ValueError:
                print("⛔ Nhập sai định dạng số.")
                time.sleep(1)
        elif choice == "4":
            config = DEFAULT_CONFIG.copy()
        elif choice == "5":
            break
        save_config(config)

def read_status():
    try:
        with open(STATUS_PATH, "r") as f:
            data = json.load(f)
            return int(data.get("time", 0))
    except Exception as e:
        print(f"[!] Không thể đọc status.txt: {e}")
        return 0

def kill_roblox():
    os.system("su -c 'pkill -f com.roblox.client'")
    print("[✓] Đã đóng Roblox")

def rejoin_game(config):
    link = config['vipServer'] if config['vipServer'] else f"roblox://placeId={config['placeId']}"
    print(f"[⏩] Đang mở lại Roblox tại: {link}")
    os.system(f"am start -a android.intent.action.VIEW -d \"{link}\"")

def main():
    config = load_config()
    while True:
        print("\n[📂] Kiểm tra trạng thái...")
        last_time = read_status()
        now = int(time.time())
        time_diff = now - last_time
        print(f"[⌛] Lần ghi file cách đây {time_diff} giây")

        if time_diff > 300:
            print("[⚠️] Quá thời gian cho phép. Bắt đầu rejoin...")
            kill_roblox()
            time.sleep(3)
            rejoin_game(config)
        else:
            print("[✅] Trạng thái bình thường.")

        time.sleep(config['checkInterval'])

if __name__ == "__main__":
    os.makedirs("/sdcard", exist_ok=True)
    if not os.path.exists(CONFIG_PATH):
        save_config(DEFAULT_CONFIG)

    inp = input("Gõ 'config' để chỉnh cấu hình, Enter để tiếp tục:\n> ").strip().lower()
    if inp == "config":
        config_menu()
    else:
        main()
