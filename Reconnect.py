import os
import time
import json
import requests

WEBHOOK_URL = "https://discord.com/api/webhooks/1368230361754243163/DL25j9slj-cbkWXysiMKopqEf-_YkT9DZUGk6m7wUq4RVXo7Q7Ex7ApBvxHRBqFdqZj6"
CONFIG_FILE = "config.json"
DEFAULT_DELAY = 360  # 6 phút

def send_to_discord(message):
    payload = {"content": message}
    try:
        requests.post(WEBHOOK_URL, json=payload)
    except Exception as e:
        print(f"[Webhook Error] {e}")

def save_config(data):
    with open(CONFIG_FILE, "w") as f:
        json.dump(data, f)

def load_config():
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, "r") as f:
            return json.load(f)
    return None

def reset_config():
    if os.path.exists(CONFIG_FILE):
        os.remove(CONFIG_FILE)
        print("[✓] Đã reset cấu hình.")

def menu():
    print("=== Roblox Auto Rejoin Tool ===")
    if os.path.exists(CONFIG_FILE):
        print("1. Tiếp tục với cấu hình cũ")
        print("2. Nhập lại và reset cấu hình")
        choice = input("Chọn: ")
        if choice == "1":
            return load_config()
        elif choice == "2":
            reset_config()
    
    place = input("Nhập Place ID hoặc VIP link: ")
    try:
        delay = int(input(f"Nhập delay kiểm tra (giây, mặc định {DEFAULT_DELAY}): ") or DEFAULT_DELAY)
    except ValueError:
        delay = DEFAULT_DELAY
    username = input("Nhập username Roblox: ").strip().lower()

    data = {
        "place": place,
        "delay": delay,
        "username": username
    }
    save_config(data)
    return data

def kill_roblox():
    os.system("su -c 'pkill -f \"com.roblox.client\"'")
    print("[✓] Đã đóng Roblox")

def rejoin_game(link):
    os.system(f'am start -a android.intent.action.VIEW -d "{link}"')
    send_to_discord(f"🔁 Rejoined game: {link}")
    print("[✓] Đã mở lại Roblox")

def main():
    cfg = menu()
    print(f"[✓] Bắt đầu kiểm tra mỗi {cfg['delay']} giây...")

    while True:
        try:
            res = requests.get(WEBHOOK_URL)
            if res.status_code == 200:
                messages = res.json()
                contents = [msg.get("content", "").lower() for msg in messages]
                if not any(f"online|{cfg['username']}".lower() in msg for msg in contents):
                    print(f"[!] Không thấy tín hiệu online từ {cfg['username']}, đang rejoin...")
                    kill_roblox()
                    time.sleep(5)
                    rejoin_game(cfg["place"])
            else:
                print("[!] Không lấy được webhook.")
        except Exception as e:
            print(f"[Lỗi] {e}")
        time.sleep(cfg["delay"])

if __name__ == "__main__":
    main()
