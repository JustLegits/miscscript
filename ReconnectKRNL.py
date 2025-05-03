import os
import json
import time

CONFIG_PATH = "/sdcard/roblox_config.txt"
STATUS_FILE_PATH = "/data/data/com.roblox.client/files/krnl/workspace/status.txt"

def load_config():
    if not os.path.exists(CONFIG_PATH):
        return {"placeId": "", "svv": "", "username": "", "check_interval": 300, "max_delay": 120}
    with open(CONFIG_PATH, "r") as f:
        return json.load(f)

def save_config(config):
    with open(CONFIG_PATH, "w") as f:
        json.dump(config, f)

def config_menu():
    config = load_config()
    while True:
        os.system("clear")
        print("=== Cấu hình Reconnect ===")
        print(f"1. PlaceId      : {config.get('placeId')}")
        print(f"2. Server VIP   : {config.get('svv')}")
        print(f"3. Username     : {config.get('username')}")
        print(f"4. Thời gian kiểm tra (s): {config.get('check_interval')}")
        print(f"5. Giới hạn lệch thời gian (s): {config.get('max_delay')}")
        print("6. Reset config")
        print("0. Lưu và thoát")
        choice = input("Chọn mục cần chỉnh: ").strip()
        if choice == "1":
            config["placeId"] = input("Nhập placeId: ").strip()
        elif choice == "2":
            config["svv"] = input("Nhập server VIP (nếu có): ").strip()
        elif choice == "3":
            config["username"] = input("Nhập username của bạn trong Roblox: ").strip()
        elif choice == "4":
            config["check_interval"] = int(input("Nhập thời gian kiểm tra (giây): ").strip())
        elif choice == "5":
            config["max_delay"] = int(input("Nhập thời gian lệch tối đa (giây): ").strip())
        elif choice == "6":
            config = {"placeId": "", "svv": "", "username": "", "check_interval": 300, "max_delay": 120}
        elif choice == "0":
            save_config(config)
            print("Đã lưu cấu hình!")
            time.sleep(1)
            break
        else:
            print("Lựa chọn không hợp lệ!")
            time.sleep(1)

def read_status_file():
    try:
        output = os.popen(f"su -c 'cat {STATUS_FILE_PATH}'").read()
        return json.loads(output)
    except Exception as e:
        print(f"[Lỗi] Không thể đọc file status.txt: {e}")
        return None

def kill_roblox():
    os.system("su -c 'pkill -f com.roblox.client'")
    print("[✓] Đã tắt Roblox")

def rejoin_game(placeId, svv=""):
    url = f"roblox://placeId={placeId}"
    if svv:
        url += f"&linkCode={svv}"
    os.system(f"am start -a android.intent.action.VIEW -d "{url}"")
    print(f"[✓] Đang mở lại game với placeId {placeId}")

def main_loop():
    config = load_config()
    while True:
        status = read_status_file()
        if not status:
            time.sleep(config["check_interval"])
            continue

        current_time = int(time.time())
        file_time = int(status.get("time", 0))
        username = status.get("username", "").strip()

        print(f"[Debug] Username trong file: {username}, Time: {file_time}")
        print(f"[Debug] Username cấu hình: {config['username']}")

        if username != config["username"]:
            print("⚠️ Username không trùng khớp.")
        elif abs(current_time - file_time) > config["max_delay"]:
            print("[!] Người chơi offline quá lâu. Bắt đầu rejoin...")
            kill_roblox()
            time.sleep(2)
            rejoin_game(config["placeId"], config["svv"])
        else:
            print("✅ Người chơi vẫn online.")

        time.sleep(config["check_interval"])

if __name__ == "__main__":
    print("Gõ 'config' để chỉnh cấu hình, Enter để tiếp tục:")
    inp = input().strip().lower()
    if inp == "config":
        config_menu()
    main_loop()
