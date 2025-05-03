import os
import time
import json

CONFIG_DIR = "/sdcard/roblox_status"
CONFIG_FILE = os.path.join(CONFIG_DIR, "config.json")
STATUS_FILE = os.path.join(CONFIG_DIR, "status.txt")


def ensure_files():
    os.makedirs(CONFIG_DIR, exist_ok=True)
    if not os.path.exists(STATUS_FILE):
        with open(STATUS_FILE, "w") as f:
            f.write("offline")


def load_config():
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, "r") as f:
            return json.load(f)
    return None


def save_config(config):
    with open(CONFIG_FILE, "w") as f:
        json.dump(config, f)


def reset_config():
    if os.path.exists(CONFIG_FILE):
        os.remove(CONFIG_FILE)
        print("[✓] Đã reset cấu hình.")
    else:
        print("[!] Không tìm thấy cấu hình để reset.")


def input_config():
    place_id = input("Nhập Place ID: ")
    vip_server = input("Nhập VIP Server Link: ")
    delay = int(input("Nhập thời gian kiểm tra (giây): "))
    config = {"place_id": place_id, "vip_server": vip_server, "delay": delay}
    save_config(config)
    print("[✓] Đã lưu cấu hình.")
    return config


def main_menu():
    print("===== ROBLOX AUTO REJOIN SETUP =====")
    print("1. Thiết lập cấu hình")
    print("2. Reset cấu hình")
    print("3. Chạy script")
    print("4. Thoát")
    choice = input("Chọn tùy chọn: ")
    return choice


def run_script(config):
    while True:
        try:
            with open(STATUS_FILE, "r") as f:
                status = f.read().strip()
            print(f"[Trạng thái] {status}")
            if status == "offline":
                print("[!] Tự động rejoin đang thực hiện...")
                # Gọi đoạn rejoin game ở đây nếu muốn
                # os.system(...) hoặc lệnh tương ứng
            else:
                print("[✓] Vẫn đang online.")
        except Exception as e:
            print(f"[Lỗi] {e}")
        time.sleep(config["delay"])


if __name__ == "__main__":
    ensure_files()
    while True:
        choice = main_menu()
        if choice == "1":
            input_config()
        elif choice == "2":
            reset_config()
        elif choice == "3":
            config = load_config()
            if not config:
                print("[!] Bạn chưa thiết lập cấu hình.")
                continue
            run_script(config)
        elif choice == "4":
            print("Tạm biệt.")
            break
        else:
            print("[!] Lựa chọn không hợp lệ.")
