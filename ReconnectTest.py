# TERMUX require python
# pkg install python
# python <(curl -s https://raw.githubusercontent.com/JustLegits/miscscript/refs/heads/main/Reconnect.py)
# Only Delta hihi (●'◡'●)

import time
import os
import subprocess
import json
import sys
import urllib.parse

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
        return data.get("time"), data.get("isDisconnected", False), data.get("teleportFailed", False) # Đọc teleportFailed
    except FileNotFoundError:
        print(f"[PYTHON] File trạng thái không tồn tại: {status_file_path}")
        return None, False, False
    except json.JSONDecodeError as e:
        print(f"[PYTHON] Lỗi giải mã JSON trong file trạng thái: {e}")
        return None, False, False
    except Exception as e:
        print(f"[PYTHON] Lỗi khi đọc file trạng thái: {e}")
        return None, False, False

def force_stop_roblox():
    """Buộc dừng ứng dụng Roblox."""
    print("[PYTHON] Buộc dừng Roblox...")
    try:
        # Thử dùng killall trước
        subprocess.run(["killall", package_name], check=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        time.sleep(2)

        # Sử dụng am force-stop
        subprocess.run(["am", "force-stop", package_name], check=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        time.sleep(2)

        # Kiểm tra tiến trình và kill nếu vẫn còn chạy
        for _ in range(5):  # Tăng số lần thử
            result = subprocess.run(["pidof", package_name], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            if not result.stdout.strip():
                print("[PYTHON] Roblox đã dừng thành công.")
                return
            else:
                pids = result.stdout.strip().split()
                print(f"[PYTHON] Roblox vẫn đang chạy (PIDs: {pids}), thử kill...")
                for pid in pids:
                    subprocess.run(["kill", "-9", pid], check=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                time.sleep(2)
        print("[PYTHON] Không thể dừng Roblox. Tiếp tục...")  # In ra sau 5 lần thử

    except Exception as e:
        print(f"[PYTHON] Lỗi khi dừng ứng dụng: {e}")

def rejoin_roblox(place_id, vip_link):
    """Khởi động lại ứng dụng Roblox và cố gắng join lại bằng deep linking."""
    print("[PYTHON] Tiến hành Rejoin Roblox...")
    try:
        force_stop_roblox()
        time.sleep(5)

        # Xây dựng URL deep linking
        rejoin_url = ""
        if vip_link:
            rejoin_url = vip_link
        elif place_id:
            rejoin_url = f"roblox://placeid={place_id}"

        if rejoin_url:
            am_command = ["am", "start", "-a", "android.intent.action.VIEW", "-d", rejoin_url, "-f", "0x10000000", "-W"]
            result = subprocess.run(
                am_command,
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )
            print(f"[PYTHON] Lệnh am start -d trả về:\n{result.stdout}")
            if result.stderr:
                print(f"[PYTHON] Lỗi từ lệnh am start -d:\n{result.stderr}")
        else:
            result = subprocess.run(
                ["am", "start", "-n", f"{package_name}/{activity_name}", "-W"],
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )
    except subprocess.CalledProcessError as e:
        print(f"[PYTHON] Lỗi khi chạy lệnh am start: {e}")
        print(f"[PYTHON] Lệnh am start trả về (lỗi):\n{e.stderr}")
    except Exception as e:
        print(f"[PYTHON] Lỗi không mong muốn trong rejoin_roblox: {e}")

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
                status_time, is_disconnected, teleport_failed = get_status_time() # Đọc teleport_failed
                if status_time is not None:
                    current_time = time.time()
                    time_difference = current_time - status_time
                    print(f"[PYTHON] Thời gian trôi qua: {time_difference:.2f} giây, Disconnected: {is_disconnected}, Teleport Failed: {teleport_failed}")
                    if teleport_failed: # Ưu tiên teleport fail
                        print("[PYTHON] Teleport Failed: Tiến hành Rejoin.")
                        rejoin_roblox(config.get("place_id"), config.get("vip_link"))
                    elif is_disconnected: # Nếu không phải teleport fail, kiểm tra disconnect
                        print("[PYTHON] Disconnected: Tiến hành Rejoin.")
                        rejoin_roblox(config.get("place_id"), config.get("vip_link"))
                    elif time_difference > config.get("rejoin_threshold", rejoin_threshold): # Cuối cùng là kiểm tra thời gian chờ
                        print("[PYTHON] Quá thời gian chờ: Tiến hành Rejoin.")
                        rejoin_roblox(config.get("place_id"), config.get("vip_link"))
                    else:
                        print("[PYTHON] Chưa cần Rejoin.")
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
