import os
import time
import json
from datetime import datetime

CONFIG_PATH = "/sdcard/roblox_status/config.json"
STATUS_PATH = "/sdcard/roblox_status/status.txt"

def ensure_paths():
    os.makedirs("/sdcard/roblox_status", exist_ok=True)
    if not os.path.exists(CONFIG_PATH):
        setup_config()

def setup_config():
    print("==== CẤU HÌNH KHỞI TẠO ====")
    place_id = input("Nhập Place ID: ").strip()
    vip_server = input("Nhập VIP Server ID (Enter nếu không có): ").strip()
    delay = int(input("Nhập thời gian kiểm tra (phút): ").strip())
    config = {
        "place_id": place_id,
        "vip_server": vip_server,
        "delay": delay
    }
    with open(CONFIG_PATH, "w") as f:
        json.dump(config, f)
    print("Đã lưu cấu hình.")

def load_config():
    with open(CONFIG_PATH, "r") as f:
        return json.load(f)

def check_status():
    if not os.path.exists(STATUS_PATH):
        print("[!] Không tìm thấy file trạng thái, sẽ thực hiện rejoin.")
        return False
    try:
        with open(STATUS_PATH, "r") as f:
            timestamp = f.read().strip()
        last_time = datetime.strptime(timestamp, "%Y-%m-%d %H:%M:%S")
        now = datetime.now()
        diff = (now - last_time).total_seconds()
        print(f"[✓] Lệch thời gian: {int(diff)} giây.")
        return diff <= 120  # lệch dưới 2 phút
    except Exception as e:
        print("[!] Lỗi khi đọc file:", e)
        return False

def do_rejoin(config):
    print("[!] Bắt đầu rejoin...")
    os.system("pkill com.roblox.client")  # yêu cầu quyền root
    time.sleep(2)
    intent = f"com.roblox.client/com.roblox.client.ActivityNativeMain -d roblox://placeID={config['place_id']}"
    if config['vip_server']:
        intent += f"&linkCode={config['vip_server']}"
    os.system(f"monkey -p com.roblox.client -c android.intent.category.LAUNCHER 1")
    os.system(f"am start -n {intent}")
    print("[✓] Đã thực hiện rejoin.")

def main():
    ensure_paths()
    while True:
        config = load_config()
        print("\n==== MENU ====")
        print("1. Bắt đầu kiểm tra")
        print("2. Reset cấu hình")
        print("3. Thoát")
        choice = input("Chọn: ").strip()
        if choice == "1":
            while True:
                online = check_status()
                if not online:
                    do_rejoin(config)
                print(f"Chờ {config['delay']} phút...")
                time.sleep(config['delay'] * 60)
        elif choice == "2":
            os.remove(CONFIG_PATH)
            print("[✓] Đã xóa cấu hình.")
            setup_config()
        elif choice == "3":
            break
        else:
            print("Lựa chọn không hợp lệ.")

if __name__ == "__main__":
    main()
