import requests
import os
import time
import json

CONFIG_FILE = "config.json"

# Hàm gửi thông báo về Discord Webhook (nếu cần sau này)
def send_to_discord(message):
    print(f"[Log] {message}")  # Hiện tại chỉ in ra, bạn có thể thêm webhook nếu muốn

# Hàm lưu cấu hình
def save_config(config):
    with open(CONFIG_FILE, "w") as f:
        json.dump(config, f)

# Hàm tải cấu hình
def load_config():
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, "r") as f:
            return json.load(f)
    return None

# Hàm rejoin game
def rejoin_game(target):
    try:
        os.system(f'am start -a android.intent.action.VIEW -d "{target}"')
        send_to_discord(f"Đã rejoin game với link: {target}")
        print("[✓] Rejoin thành công")
    except Exception as e:
        send_to_discord(f"[Lỗi] Không thể rejoin game: {e}")
        print(f"[Lỗi] {e}")

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

    if not config.get("url"):
        config["url"] = input("Nhập URL Flash Server (/status.txt): ").strip()
    if not config.get("place_id"):
        config["place_id"] = input("Nhập Place ID hoặc server VIP Roblox: ").strip()
    if not config.get("delay"):
        try:
            config["delay"] = int(input("Nhập thời gian delay giữa các lần kiểm tra (giây): "))
        except ValueError:
            config["delay"] = 60

    save_config(config)
    return config

# Hàm chính
def main():
    config = menu()
    url = config["url"]
    place_id = config["place_id"]
    delay = config["delay"]

    while True:
        print(f"[✓] Đang kiểm tra trạng thái từ {url} mỗi {delay} giây...")
        try:
            res = requests.get(url, timeout=5)
            if res.status_code == 200:
                content = res.text.strip().lower()
                if content == "offline":
                    print("[!] Phát hiện trạng thái offline, đang rejoin...")
                    kill_roblox()
                    time.sleep(5)
                    rejoin_game(place_id)
        except Exception as e:
            print(f"[Lỗi] Không thể kiểm tra: {e}")

        time.sleep(delay)

if __name__ == "__main__":
    main()
