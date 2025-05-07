import time
import os
import subprocess
import json
import sys
import urllib.parse
from PIL import Image
from io import BytesIO

# --- Configuration ---
PACKAGE_NAME = "com.roblox.client"
ACTIVITY_NAME = "com.roblox.client.MainActivity"
CONFIG_FILE = "config.json"
CHECK_INTERVAL = 80  # Kiểm tra logo sau mỗi X giây
NORMAL_LOGO_THRESHOLD = 0.95
LOGO_REGION = (32, 26, 70, 63)  # Tọa độ vùng logo (cần điều chỉnh nếu khác)
NORMAL_LOGO_IMAGE_PATH = "/sdcard/Download/normal_logo.png"
TEMP_IMAGE_PATH = "/sdcard/Download/temp_logo.png"

global running

# --- Helper Functions ---
def get_region_screenshot():
    """Chụp ảnh vùng màn hình chứa logo Roblox."""
    try:
        result = subprocess.run(
            ["su", "-c", "screencap -p"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True
        )
        screen_bytes = result.stdout
        img = Image.open(BytesIO(screen_bytes)).convert("RGB")
        logo_image = img.crop(LOGO_REGION)
        return logo_image
    except subprocess.CalledProcessError as e:
        print(f"[PYTHON] Lỗi khi chụp màn hình (root): {e}")
        return None
    except Exception as e:
        print(f"[PYTHON] Lỗi không mong muốn khi chụp ảnh logo: {e}")
        return None

def compare_images(img1, img2):
    """So sánh hai ảnh và trả về độ tương đồng (0 đến 1)."""
    if img1 is None or img2 is None or img1.size != img2.size:
        return 0
    total_pixels = img1.width * img1.height
    diff_pixels = 0
    for x in range(img1.width):
        for y in range(img1.height):
            if img1.getpixel((x, y)) != img2.getpixel((x, y)):
                diff_pixels += 1
    return 1 - (diff_pixels / total_pixels)

def force_stop_roblox():
    """Buộc dừng ứng dụng Roblox (root)."""
    print("[PYTHON] Buộc dừng Roblox (root)...")
    try:
        subprocess.run(["su", "-c", f"pm force-stop {PACKAGE_NAME}"], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        time.sleep(2)
        print("[PYTHON] Roblox đã dừng.")
    except subprocess.CalledProcessError as e:
        print(f"[PYTHON] Lỗi khi dừng Roblox (root): {e}")
        print(f"[PYTHON] Lệnh trả về (lỗi):\n{e.stderr}")
    except Exception as e:
        print(f"[PYTHON] Lỗi không mong muốn khi dừng Roblox (root): {e}")

def kill_roblox():
    """Kill tất cả tiến trình liên quan đến Roblox (root)."""
    print("[PYTHON] Kill tiến trình Roblox (root)...")
    try:
        subprocess.run(["su", "-c", f"pkill -f '{PACKAGE_NAME}'"], check=False, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        time.sleep(3)
        print("[PYTHON] Tiến trình Roblox đã bị kill.")
    except Exception as e:
        print(f"[PYTHON] Lỗi khi kill tiến trình Roblox (root): {e}")

def rejoin_roblox(place_id, vip_link):
    """Khởi động lại Roblox và cố gắng join lại (root)."""
    print("[PYTHON] Tiến hành Rejoin (root)...")
    try:
        kill_roblox()
        time.sleep(5)
        force_stop_roblox()
        time.sleep(5)

        rejoin_url = ""
        if vip_link:
            rejoin_url = vip_link
        elif place_id:
            rejoin_url = f"roblox://placeid={place_id}"

        if rejoin_url:
            am_command = f"am start -a android.intent.action.VIEW -d '{rejoin_url}' -f 0x10008000 -W"
            result = subprocess.run(["su", "-c", am_command], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            print(f"[PYTHON] Lệnh am start -d (root) trả về:\n{result.stdout}")
            if result.stderr:
                print(f"[PYTHON] Lỗi từ lệnh am start -d (root):\n{result.stderr}")
        else:
            am_command = f"am start -n {PACKAGE_NAME}/{ACTIVITY_NAME} -W"
            result = subprocess.run(["su", "-c", am_command], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            print(f"[PYTHON] Lệnh am start -n (root) trả về:\n{result.stdout}")
            if result.stderr:
                print(f"[PYTHON] Lỗi từ lệnh am start -n (root):\n{result.stderr}")
        time.sleep(15)
        print("[PYTHON] Rejoin hoàn tất.")
    except subprocess.CalledProcessError as e:
        print(f"[PYTHON] Lỗi trong quá trình rejoin (root): {e}")
        print(f"[PYTHON] Lệnh trả về (lỗi):\n{e.stderr}")
    except Exception as e:
        print(f"[PYTHON] Lỗi không mong muốn khi rejoin (root): {e}")

def load_config():
    """Tải cấu hình từ file config.json."""
    try:
        with open(CONFIG_FILE, "r") as f:
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
        with open(CONFIG_FILE, "w") as f:
            json.dump(config, f, indent=4)
        print("[PYTHON] Cấu hình đã được lưu.")
    except Exception as e:
        print(f"[PYTHON] Lỗi khi lưu file cấu hình: {e}")

def get_config_input():
    """Yêu cầu người dùng nhập Place ID và VIP Link."""
    config = {}
    config["place_id"] = input("Nhập Place ID: ")
    config["vip_link"] = input("Nhập Server VIP Link (tùy chọn, để trống nếu không có): ")
    return config

def display_menu(config, config_set):
    """Hiển thị menu."""
    print("\n--- Auto Rejoin Roblox (Root - Logo Check Only) ---")
    if not config_set:
        print("Vui lòng thiết lập cấu hình trước khi tiếp tục.")
    else:
        print(f"1. Thiết lập/Đặt lại cấu hình")
        print(f"2. Bắt đầu Auto Rejoin")
        print(f"3. Dừng (Ctrl+C)")
        print(f"4. Thoát")
        print("Nhập lựa chọn của bạn:")

def main():
    """Hàm chính để chạy script - Chỉ kiểm tra logo để rejoin."""
    global running
    running = False
    config = load_config()
    config_set = bool(config and config.get("place_id"))
    normal_logo_image = None

    if not config_set:
        print("[PYTHON] Chào mừng! Thiết lập cấu hình.")
        config = get_config_input()
        save_config(config)
        config_set = True

    # Chụp ảnh tham chiếu logo nếu chưa tồn tại
    if not os.path.exists(NORMAL_LOGO_IMAGE_PATH):
        print("[PYTHON] Tiến hành chụp ảnh tham chiếu logo lần đầu...")
        first_logo = get_region_screenshot()
        if first_logo:
            try:
                first_logo.save(NORMAL_LOGO_IMAGE_PATH)
                print(f"[PYTHON] Đã lưu ảnh tham chiếu logo tại {NORMAL_LOGO_IMAGE_PATH}")
                normal_logo_image = first_logo
            except Exception as e:
                print(f"[PYTHON] Lỗi khi lưu ảnh tham chiếu: {e}")
                return
        else:
            print("[PYTHON] Không thể chụp ảnh logo tham chiếu ban đầu.")
            return
    else:
        try:
            normal_logo_image = Image.open(NORMAL_LOGO_IMAGE_PATH).convert("RGB")
            print("[PYTHON] Đã tải ảnh tham chiếu logo.")
        except FileNotFoundError:
            print(f"[PYTHON] Không tìm thấy ảnh tham chiếu logo tại {NORMAL_LOGO_IMAGE_PATH}.")
            return
        except Exception as e:
            print(f"[PYTHON] Lỗi khi mở ảnh tham chiếu logo: {e}")
            return

    while True:
        display_menu(config, config_set)
        choice = input()

        if choice == "1":
            print("[PYTHON] Thiết lập cấu hình...")
            config = get_config_input()
            save_config(config)
        elif choice == "2" and config_set:
            print("[PYTHON] Bắt đầu Auto Rejoin (chỉ kiểm tra logo)...")
            running = True
            while running:
                current_logo = get_region_screenshot()

                if current_logo is None:
                    print("[PYTHON] Không tìm thấy logo (không thể chụp ảnh). Tiến hành Rejoin...")
                    rejoin_roblox(config.get("place_id"), config.get("vip_link"))
                elif normal_logo_image:
                    similarity = compare_images(normal_logo_image, current_logo)
                    print(f"[PYTHON] Độ tương đồng logo: {similarity:.2f}")
                    if similarity < NORMAL_LOGO_THRESHOLD:
                        print("[PYTHON] Biểu tượng logo có vẻ đã thay đổi. Tiến hành Rejoin...")
                        rejoin_roblox(config.get("place_id"), config.get("vip_link"))
                else:
                    print("[PYTHON] Chưa có ảnh tham chiếu logo để so sánh.")

                time.sleep(CHECK_INTERVAL)
            print("[PYTHON] Auto Rejoin đã dừng.")
        elif choice == "3":
            print("[PYTHON] Dừng...")
            running = False
        elif choice == "4":
            print("[PYTHON] Thoát.")
            sys.exit()
        elif choice == "2" and not config_set:
            print("[PYTHON] Vui lòng thiết lập cấu hình trước khi bắt đầu.")
        else:
            print("[PYTHON] Lựa chọn không hợp lệ.")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n[PYTHON] Script dừng bởi người dùng (Ctrl+C).")
    except Exception as e:
        print(f"[PYTHON] Đã xảy ra lỗi không mong muốn: {e}")
