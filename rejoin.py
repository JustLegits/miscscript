import requests
import os
import time
import json

CONFIG_FILE = "config.json"
STATUS_URL = "https://11379483-ebd2-4a76-8731-f9587cf0e2d5-00-23nrfojwtk70i.pike.replit.dev/status.txt"

# Hàm gửi log (có thể gắn webhook nếu cần)
def send_to_discord(message):
    print(f"[Log] {message}")

# Lưu config
def save_config(config):
    with open(CONFIG_FILE, "w") as f:
        json.dump(config, f)

# Tải config
def load_config():
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, "r") as f:
            return json.load(f)
    return None

# Mở Roblox
def rejoin_game(target):
    try:
        os.system(f'am start -a android.intent.action.VIEW -d "{target}"')
        print("[✓] Rejoin thành công")
        send_to_discord(f"Đã rejoin game với link: {target}")
    except Exception as e:
        print(f"[Lỗi] {e}")
        send_to_discord(f"[Lỗi] Không thể rejoin: {e}")

# Kill Roblox (yêu cầu root)
def kill_roblox():
    try:
        os.system("su -c 'pkill -f \"com.roblox.client\"'")
        print("[✓] Đã đóng Roblox")
    except Exception as e:
        print(f"[Lỗi] Không thể đóng Roblox: {e}")

# Menu cấu hình
def menu():
    print("=== Roblox Auto Rejoin Tool ===")
    reset = input("Bạn có muốn reset cấu hình? (y/n): ").lower()
    config = {} if reset == "y" else load_config() or {}

    if not config.get("place_id"):
        config["place_id"] = input("Nhập Place ID hoặc link server VIP Roblox: ").strip()
    if not config.get("delay"):
        try:
            config["delay"] = int(input("Nhập thời gian delay giữa các lần kiểm tra (giây): "))
        except ValueError:
            config["delay"] = 60

    save_config(config)
    return config

# Chạy chính
def main():
    config = menu()
    target = config["place_id"]
    delay = config["delay"]

    while True:
        print(f"[✓] Kiểm tra trạng thái từ server mỗi {delay} giây...")
        try:
            res = requests.get(STATUS_URL, timeout=5)
            if res.status_code == 200:
                if res.text.strip().lower() == "offline":
                    print("[!] Phát hiện trạng thái offline, đang rejoin...")
                    kill_roblox()
                    time.sleep(5)
                    rejoin_game(target)
        except Exception as e:
            print(f"[Lỗi] Không thể kết nối: {e}")
        time.sleep(delay)

if __name__ == "__main__":
    main()
