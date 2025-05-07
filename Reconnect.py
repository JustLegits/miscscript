import time
import os
import subprocess
import json
import sys

# Định nghĩa tên file trạng thái và đường dẫn
status_file_name = "status.json"
status_file_path = "/sdcard/Android/data/com.roblox.client/files/gloop/external/Workspace/" + status_file_name
rejoin_threshold = 300
package_name = "com.roblox.client"
activity_name = "com.roblox.client.MainActivity"
config_file = "config.json"
global running

def get_status_time():
    """Đọc thời gian và trạng thái ngắt kết nối từ file status.json."""
    try:
        with open(status_file_path, "r") as f:
            data = json.load(f)
        return data.get("time"), data.get("isDisconnected", False)
    except FileNotFoundError:
        print(f"[PYTHON] File trạng thái không tồn tại: {status_file_path}")
        return None, False
    except json.JSONDecodeError as e:
        print(f"[PYTHON] Lỗi giải mã JSON trong file trạng thái: {e}")
        return None, False
    except Exception as e:
        print(f"[PYTHON] Lỗi khi đọc file trạng thái: {e}")
        return None, False

def force_stop_roblox_root():
    """Buộc dừng ứng dụng Roblox bằng quyền root."""
    print("[PYTHON] Buộc dừng Roblox (root)...")
    try:
        subprocess.run(["su", "-c", f"pm force-stop {package_name}"], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        time.sleep(2)
        print("[PYTHON] Roblox đã dừng.")
    except subprocess.CalledProcessError as e:
        print(f"[PYTHON] Lỗi khi dừng ứng dụng (root): {e}")
        print(f"[PYTHON] Lệnh trả về (lỗi):\n{e.stderr}")
    except Exception as e:
        print(f"[PYTHON] Lỗi không mong muốn khi dừng ứng dụng (root): {e}")

def start_roblox_root(place_id, vip_link):
    """Khởi động lại ứng dụng Roblox bằng quyền root."""
    print("[PYTHON] Khởi động lại Roblox (root)...")
    try:
        rejoin_url = ""
        if vip_link:
            rejoin_url = vip_link
        elif place_id:
            rejoin_url = f"roblox://placeid={place_id}"

        if rejoin_url:
            am_command = f"am start -a android.intent.action.VIEW -d '{rejoin_url}' -f 0x10008000"
            result = subprocess.run(["su", "-c", am_command], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            print(f"[PYTHON] Lệnh am start -d (root) trả về:\n{result.stdout}")
            if result.stderr:
                print(f"[PYTHON] Lỗi từ lệnh am start -d (root):\n{result.stderr}")
        else:
            am_command = f"am start -n {package_name}/{activity_name}"
            result = subprocess.run(["su", "-c", am_command], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            print(f"[PYTHON] Lệnh am start (root) trả về:\n{result.stdout}")
            if result.stderr:
                print(f"[PYTHON] Lỗi từ lệnh am start (root):\n{result.stderr}")
        time.sleep(10) # Đợi Roblox khởi động
    except subprocess.CalledProcessError as e:
        print(f"[PYTHON] Lỗi khi chạy lệnh am start (root): {e}")
        print(f"[PYTHON] Lệnh trả về (lỗi):\n{e.stderr}")
    except Exception as e:
        print(f"[PYTHON] Lỗi không mong muốn khi khởi động Roblox (root): {e}")

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
    except Exception as e:
        print(f"[PYTHON] Lỗi khi tải file cấu hình: {e}")
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
    while True:
        try:
            rejoin_threshold_input = input("Nhập thời gian chờ (giây): ")
            if not rejoin_threshold_input:
                print("[PYTHON] Không nhập thời gian chờ, sử dụng mặc định 300s.")
                config["rejoin_threshold"] = 300
                break
            config["rejoin_threshold"] = int(rejoin_threshold_input)
            if config["rejoin_threshold"] <= 0:
                print("[PYTHON] Thời gian chờ phải lớn hơn 0.")
            else:
                break
        except ValueError:
            print("[PYTHON] Giá trị thời gian chờ không hợp lệ, vui lòng nhập lại.")
    return config

def display_menu(config, config_set):
    """Hiển thị menu và xử lý lựa chọn của người dùng."""
    print("\n--- Auto Rejoin Roblox (Root) ---")
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
    config_set = bool(config and config.get("place_id") and config.get("vip_link"))

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
                status_time, is_disconnected = get_status_time()
                if status_time is not None:
                    current_time = time.time()
                    time_difference = current_time - status_time
                    print(f"[PYTHON] Thời gian trôi qua: {time_difference:.2f} giây, Disconnected: {is_disconnected}")
                    if is_disconnected or time_difference > config.get("rejoin_threshold", rejoin_threshold):
                        print("[PYTHON] Phát hiện Disconnect hoặc quá thời gian chờ. Tiến hành Rejoin...")
                        force_stop_roblox_root()
                        start_roblox_root(config.get("place_id"), config.get("vip_link"))
                else:
                    print("[PYTHON] Không thể đọc được thời gian từ file trạng thái.")
                time.sleep(80)
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
