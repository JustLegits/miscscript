import os
import json
import time

CONFIG_FILE = "/sdcard/roblox_config.txt"
STATUS_FILE = "/data/data/com.roblox.client/files/krnl/workspace/status.txt"

def load_config():
    if not os.path.exists(CONFIG_FILE):
        return {
            "placeId": "",
            "svv": "",
            "delay": 300,
            "username": ""
        }
    with open(CONFIG_FILE, "r") as f:
        return json.load(f)

def save_config(config):
    with open(CONFIG_FILE, "w") as f:
        json.dump(config, f, indent=4)

def config_menu():
    config = load_config()
    print("=== Cấu hình Roblox Rejoin ===")
    config["placeId"] = input(f"Nhập placeId [{config.get('placeId', '')}]: ") or config.get("placeId", "")
    config["svv"] = input(f"Nhập server VIP (bỏ trống nếu không dùng) [{config.get('svv', '')}]: ") or config.get("svv", "")
    delay_input = input(f"Nhập thời gian kiểm tra (giây) [{config.get('delay', 300)}]: ")
    if delay_input.isdigit():
        config["delay"] = int(delay_input)
    config["username"] = input(f"Nhập username Roblox của bạn [{config.get('username', '')}]: ") or config.get("username", "")
    save_config(config)
    print("✅ Đã lưu cấu hình.")

def kill_roblox():
    os.system("su -c 'pkill -f com.roblox.client'")
    print("✅ Đã đóng Roblox.")

def rejoin_game(config):
    link = f"roblox://placeId={config['placeId']}"
    if config["svv"]:
        link += f"&linkCode={config['svv']}"
    os.system(f'am start -a android.intent.action.VIEW -d "{link}"')
    print("✅ Đã rejoin game:", link)

def read_status_file():
    try:
        with open(STATUS_FILE, "r") as f:
            data = json.load(f)
            return data.get("username", ""), int(data.get("time", 0))
    except Exception as e:
        print(f"[Lỗi] Không thể đọc file status.txt: {e}")
        return "", 0

def main():
    config = load_config()
    while True:
        username, timestamp = read_status_file()
        now = int(time.time())
        if username == config["username"]:
            time_diff = now - timestamp
            print(f"[i] Thời gian từ lần online cuối: {time_diff} giây")
            if time_diff > 120:
                print("[⚠️] Phát hiện offline hoặc lag quá lâu. Đang rejoin...")
                kill_roblox()
                time.sleep(3)
                rejoin_game(config)
            else:
                print("✅ Vẫn đang online.")
        else:
            print("⚠️ Username không trùng khớp.")
        time.sleep(config["delay"])

if __name__ == "__main__":
    if not os.path.exists(CONFIG_FILE):
        config_menu()
    else:
        print("Gõ 'config' để chỉnh cấu hình, Enter để tiếp tục:")
        cmd = input().strip().lower()
        if cmd == "config":
            config_menu()
        main()
