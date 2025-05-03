import requests
import os
import time
import json

CONFIG_FILE = "config.json"

def save_config(target, delay, status_url):
    with open(CONFIG_FILE, "w") as f:
        json.dump({"target": target, "delay": delay, "status_url": status_url}, f)

def load_config():
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, "r") as f:
            return json.load(f)
    return None

def menu():
    print("=== Roblox Auto Rejoin Tool ===")

    config = load_config()
    if config:
        print("🔧 Đã phát hiện cấu hình trước đó:")
        print(f" - Place ID / VIP Link: {config['target']}")
        print(f" - Delay: {config['delay']} giây")
        print(f" - Flask URL: {config['status_url']}")
        reset = input("Bạn có muốn reset cấu hình? (y/N): ").strip().lower()
        if reset != 'y':
            return config['target'], config['delay'], config['status_url']

    # Nếu không có hoặc người dùng chọn reset
    target = input("🔗 Nhập Place ID hoặc Server VIP link (roblox://placeID=...): ").strip()
    try:
        delay = int(input("⏱️ Nhập thời gian delay (giây) giữa các lần kiểm tra (mặc định 60): "))
    except ValueError:
        delay = 60
    status_url = input("🌐 Nhập URL Flask server (/status): ").strip()

    save_config(target, delay, status_url)
    return target, delay, status_url

def rejoin_game(target):
    try:
        os.system(f'am start -a android.intent.action.VIEW -d "{target}"')
        print(f"[✓] Đã rejoin game thành công với link: {target}")
    except Exception as e:
        print(f"[Lỗi] Không thể rejoin: {e}")

def kill_roblox():
    try:
        os.system("su -c 'pkill -f \"com.roblox.client\"'")
        print("[✓] Đã đóng Roblox")
    except Exception as e:
        print(f"[Lỗi] Không thể đóng Roblox: {e}")

def main():
    target, delay, status_url = menu()

    while True:
        try:
            res = requests.get(status_url, timeout=5)
            if res.status_code == 200:
                status = res.text.strip().lower()
                if status == "offline":
                    print("[!] Phát hiện trạng thái 'offline' → Rejoin ngay")
                    kill_roblox()
                    time.sleep(5)
                    rejoin_game(target)
            else:
                print(f"[!] Không đọc được trạng thái: {res.status_code}")
        except Exception as e:
            print(f"[Lỗi] Không kết nối tới server: {e}")

        time.sleep(delay)

if __name__ == "__main__":
    main()
