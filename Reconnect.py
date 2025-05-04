import time
import os
import subprocess
import json
import sys

# Định nghĩa tên file trạng thái và đường dẫn
status_file_name = "status.txt"
status_file_path = "/sdcard/Android/data/com.roblox.client/files/gloop/external/Workspace/" + status_file_name
rejoin_threshold = 300  # 5 phút
package_name = "com.roblox.client"
activity_name = "com.roblox.client.MainActivity"
config_file = "config.json"
global running

# Hàm giả lập HttpService:JSONDecode
def HttpService_JSONDecode(data):
    """Giả lập HttpService:JSONDecode của Roblox Lua bằng thư viện json của Python."""
    try:
        return json.loads(data)
    except json.JSONDecodeError as e:
        print(f"[PYTHON] Lỗi giải mã JSON: {e}")
        return None

def get_status_time():
    """Đọc thời gian từ file trạng thái. Trả về None nếu có lỗi."""
    try:
        with open(status_file_path, "r") as f:
            encoded_data = f.read()
        data = HttpService_JSONDecode(encoded_data)
        return data.get("time")
    except Exception as e:
        print(f"[PYTHON] Lỗi khi đọc file trạng thái: {e}")
        return None

def rejoin_roblox():
    """Khởi động lại ứng dụng Roblox."""
    print("[PYTHON] Tiến hành Rejoin Roblox...")
    try:
        # Sử dụng subprocess.run để chạy lệnh am
        result = subprocess.run(
            ["am", "start", "-n", f"{package_name}/{activity_name}"],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )
        print(f"[PYTHON] Lệnh am trả về:\n{result.stdout}")
        if result.stderr:
            print(f"[PYTHON] Lỗi từ lệnh am:\n{result.stderr}")

    except subprocess.CalledProcessError as e:
        print(f"[PYTHON] Lỗi khi chạy lệnh am: {e}")
        print(f"[PYTHON] Lệnh am trả về (lỗi):\n{e.stderr}")

def load_config():
    """Tải cấu hình từ file config.json. Trả về một dictionary."""
    try:
        with open(config_file, "r") as f:
            return json.load(f)
    except FileNotFoundError:
        print("[PYTHON] Không tìm thấy file cấu hình.")
        return {}
    except json.JSONDecodeError as e:
        print(f"[PYTHON] Lỗi giải mã JSON trong file cấu hình: {e}")
        return {}

def save_config(config):
    """Lưu cấu hình vào file config.json."""
    try:
        with open(config_file, "w") as f:
            json.dump(config, f, indent=4)
        print("[PYTHON] Cấu hình đã được lưu.")
    except Exception as e:
        print(f"[PYTHON] Lỗi khi lưu file cấu hình: {e}")

def get_config_input():
    """Yêu cầu người dùng nhập Place ID và VIP Link."""
    config = {}
    config["place_id"] = input("Nhập Place ID: ")
    config["vip_link"] = input("Nhập Server VIP Link: ")
    try:
        config["rejoin_threshold"] = int(input("Nhập thời gian chờ (giây): "))
    except ValueError:
        print("[PYTHON] Giá trị thời gian chờ không hợp lệ, sử dụng mặc định 300s.")
        config["rejoin_threshold"] = 300
    return config

def display_menu(config, config_set):
    """Hiển thị menu và xử lý lựa chọn của người dùng."""
    print("\n--- Auto Rejoin Roblox ---")
    if not config_set:
        print("Vui lòng thiết lập cấu hình trước khi tiếp tục.")
    else:
        print(f"1.  Đặt lại cấu hình (Place ID, Server VIP Link, Thời gian chờ)")
        print(f"2.  Bắt đầu chạy")
        print("3.  Dừng (Ctrl+C)")
        print("4.  Thoát")
        print("Nhập lựa chọn của bạn:")

def main():
    """Hàm chính để chạy script."""
    global running
    running = False
    config = load_config()
    config_set = bool(config and config.get("place_id") and config.get("vip_link")) # Kiểm tra xem config đã được thiết lập chưa

    if not config_set:
        print("[PYTHON] Chào mừng bạn mới! Vui lòng thiết lập cấu hình.")
        config = get_config_input()
        save_config(config)
        config_set = True

    while True:
        display_menu(config, config_set)
        choice = input()

        if choice == "1":
            print("[PYTHON] Đặt lại cấu hình...")
            config = get_config_input()
            save_config(config)
        elif choice == "2" and config_set:
            print("[PYTHON] Bắt đầu chạy...")
            running = True
            while running:
                status_time = get_status_time()
                if status_time:
                    current_time = time.time()
                    time_difference = current_time - status_time
                    print(f"[PYTHON] Thời gian trôi qua: {time_difference:.2f} giây")

                    if time_difference > config.get("rejoin_threshold", rejoin_threshold):
                        rejoin_roblox()
                else:
                    print("[PYTHON] Không thể đọc được thời gian từ file trạng thái.")
                time.sleep(60)
            print("[PYTHON] Đã dừng.")
        elif choice == "3":
            print("[PYTHON] Dừng chương trình...")
            running = False
        elif choice == "4":
            print("[PYTHON] Thoát chương trình...")
            sys.exit()
        elif choice == "2" and not config_set:
            print("[PYTHON] Vui lòng thiết lập cấu hình trước khi chạy.")
        else:
            print("[PYTHON] Lựa chọn không hợp lệ. Vui lòng thử lại.")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n[PYTHON] Chương trình bị dừng bởi người dùng (Ctrl+C).")
    except Exception as e:
        print(f"[PYTHON] Đã xảy ra lỗi không mong muốn: {e}")
