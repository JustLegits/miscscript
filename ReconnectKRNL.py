import os
import time

STATUS_FILE = "/data/data/com.roblox.client/files/krnl/workspace/status.txt"
CONFIG_FILE = "/data/data/com.roblox.client/files/krnl/workspace/config.txt"

def load_config():
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, "r") as f:
            lines = f.readlines()
        config = {}
        for line in lines:
            if "=" in line:
                k, v = line.strip().split("=", 1)
                config[k] = v
        return config
    else:
        return {}

def save_config(config):
    with open(CONFIG_FILE, "w") as f:
        for k, v in config.items():
            f.write(f"{k}={v}\n")

def kill_roblox():
    os.system("su -c 'pkill -f com.roblox.client'")
    print("✅ Đã tắt Roblox")

def rejoin_game(place_id, vip_server=""):
    time.sleep(2)
    url = f"roblox://placeId={place_id}"
    if vip_server:
        url += f"&linkCode={vip_server}"
    os.system(f'am start -a android.intent.action.VIEW -d "{url}"')
    print(f"✅ Đã rejoin game: {url}")

def check_status():
    if not os.path.exists(STATUS_FILE):
        print("⚠️ Không tìm thấy file status.txt")
        return False

    try:
        with open(STATUS_FILE, "r") as f:
            timestamp = int(f.read().strip())

        now = int(time.time())
        delta = now - timestamp

        print(f"[ℹ️] Đã đọc timestamp: {timestamp}, hiện tại: {now}, lệch {delta} giây")
        return delta > 120

    except Exception as e:
        print(f"[Lỗi] Khi đọc file: {e}")
        return False

def config_menu():
    config = load_config()
    print("===== Cài đặt =====")
    config["placeId"] = input(f"Nhập Place ID [{config.get('placeId', '')}]: ") or config.get("placeId", "")
    config["svv"] = input(f"Nhập VIP Server linkCode (nếu có) [{config.get('svv', '')}]: ") or config.get("svv", "")
    save_config(config)
    print("✅ Đã lưu cấu hình.")

def main():
    config = load_config()
    if not config.get("placeId"):
        config_menu()
        config = load_config()

    while True:
        if check_status():
            print("[⚠️] Trạng thái offline! Rejoining...")
            kill_roblox()
            rejoin_game(config["placeId"], config.get("svv", ""))
        else:
            print("✅ Trạng thái ổn định.")
        time.sleep(300)

if __name__ == "__main__":
    print("=== Roblox Reconnect Script ===")
    print("1. Bắt đầu chạy")
    print("2. Cấu hình")
    print("0. Thoát")
    choice = input("Chọn: ")
    if choice == "1":
        main()
    elif choice == "2":
        config_menu()
    else:
        print("Thoát.")
