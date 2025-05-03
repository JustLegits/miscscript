import os
import time
import json
from datetime import datetime

CONFIG_PATH = "/data/data/com.termux/files/home/.roblox_config.json"
STATUS_FILE_PATH = "/sdcard/roblox_status/status.txt"

def save_config(place_id, vip_server):
    config = {
        "place_id": place_id,
        "vip_server": vip_server
    }
    with open(CONFIG_PATH, "w") as f:
        json.dump(config, f)

def load_config():
    if os.path.exists(CONFIG_PATH):
        with open(CONFIG_PATH, "r") as f:
            return json.load(f)
    return None

def reset_config():
    if os.path.exists(CONFIG_PATH):
        os.remove(CONFIG_PATH)
        print("[*] Đã reset cấu hình.")

def ensure_status_file():
    os.makedirs(os.path.dirname(STATUS_FILE_PATH), exist_ok=True)
    if not os.path.exists(STATUS_FILE_PATH):
        with open(STATUS_FILE_PATH, "w") as f:
            f.write(str(time.time()))

def get_last_timestamp():
    try:
        with open(STATUS_FILE_PATH, "r") as f:
            content = f.read().strip()
            return datetime.fromtimestamp(float(content))
    except Exception as e:
        print(f"[!] Lỗi khi đọc file: {e}")
        return None

def run_menu():
    print("===== CẤU HÌNH ROBLOX =====")
    print("1. Nhập Place ID và VIP Server")
    print("2. Reset cấu hình")
    print("3. Tiếp tục")
    choice = input("Chọn: ").strip()

    if choice == "1":
        place_id = input("Nhập Place ID: ").strip()
        vip_server = input("Nhập VIP Server ID (nếu có, enter nếu không): ").strip()
        save_config(place_id, vip_server)
        print("[*] Đã lưu cấu hình.")
    elif choice == "2":
        reset_config()
    elif choice == "3":
        pass
    else:
        print("[!] Lựa chọn không hợp lệ.")

def rejoin_game(place_id, vip_server):
    print("[!] Bắt đầu rejoin...")
    try:
        os.system("pkill -f com.roblox.client")
        time.sleep(1)
        if vip_server:
            os.system(f"monkey -p com.roblox.client -c android.intent.category.LAUNCHER 1")
        else:
            os.system(f"monkey -p com.roblox.client -c android.intent.category.LAUNCHER 1")
    except Exception as e:
        print(f"[!] Lỗi khi khởi chạy Roblox: {e}")

def main():
    run_menu()
    ensure_status_file()
    config = load_config()
    if not config:
        print("[!] Chưa có cấu hình. Vui lòng chạy lại script.")
        return

    place_id = config["place_id"]
    vip_server = config["vip_server"]

    print("[*] Bắt đầu theo dõi trạng thái Roblox mỗi 5 phút...")

    while True:
        last_time = get_last_timestamp()
        if last_time:
            now = datetime.now()
            diff = (now - last_time).total_seconds()

            if diff > 120:
                print(f"[!] Không thấy tín hiệu online trong {int(diff)} giây.")
                rejoin_game(place_id, vip_server)
            else:
                print(f"[OK] Roblox vẫn online. (cách {int(diff)} giây)")
        else:
            print("[!] Không đọc được thời gian. Bỏ qua vòng này.")

        time.sleep(300)  # 5 phút

if __name__ == "__main__":
    main()
