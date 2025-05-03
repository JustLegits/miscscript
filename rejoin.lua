# rejoin.py
import requests, os, time, json

CONFIG_FILE = "config.json"
WEBHOOK_URL = "https://discord.com/api/webhooks/1368230361754243163/DL25j9slj-cbkWXysiMKopqEf-_YkT9DZUGk6m7wUq4RVXo7Q7Ex7ApBvxHRBqFdqZj6"

def save_config(config):
    with open(CONFIG_FILE, "w") as f:
        json.dump(config, f)

def load_config():
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, "r") as f:
            return json.load(f)
    return None

def reset_config():
    if os.path.exists(CONFIG_FILE):
        os.remove(CONFIG_FILE)
        print("[✓] Đã reset cấu hình.")
        time.sleep(1)

def menu():
    print("=== Cấu hình rejoin ===")
    username = input("Nhập tên tài khoản Roblox: ")
    place_id = input("Nhập link place ID hoặc server VIP: ")
    delay = int(input("Nhập thời gian delay kiểm tra (phút): "))
    config = {"username": username, "place": place_id, "delay": delay}
    save_config(config)
    return config

def get_latest_messages():
    try:
        res = requests.get(WEBHOOK_URL)
        return res.json()
    except:
        return []

def kill_roblox():
    os.system("su -c 'pkill -f \"com.roblox.client\"'")

def rejoin(place):
    os.system(f'am start -a android.intent.action.VIEW -d "{place}"')

def main():
    if os.path.exists(CONFIG_FILE):
        choice = input("Đã có cấu hình. Gõ 'reset' để cấu hình lại, hoặc nhấn Enter để dùng lại: ")
        if choice.lower() == "reset":
            reset_config()

    config = load_config()
    if not config:
        config = menu()

    print(f"[✓] Đang theo dõi '{config['username']}' mỗi {config['delay']} phút.")
    while True:
        msgs = get_latest_messages()
        recent = [m["content"] for m in msgs if f"online|{config['username']}" in m["content"]]

        if not recent:
            print("[!] Không thấy tín hiệu online. Đang rejoin...")
            kill_roblox()
            time.sleep(3)
            rejoin(config['place'])
        else:
            print("[✓] Tín hiệu online hoạt động.")

        time.sleep(config["delay"] * 60)

if __name__ == "__main__":
    main()
