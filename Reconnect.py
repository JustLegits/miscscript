import os
import time

STATUS_PATH = "/sdcard/roblox_status/status.txt"
CHECK_INTERVAL = 300  # 5 phút
TIMEOUT_SECONDS = 120  # 2 phút

def ensure_file():
    folder = os.path.dirname(STATUS_PATH)
    if not os.path.exists(folder):
        os.makedirs(folder)
    if not os.path.exists(STATUS_PATH):
        with open(STATUS_PATH, "w") as f:
            f.write(str(int(time.time())))

def read_timestamp():
    try:
        with open(STATUS_PATH, "r") as f:
            return int(f.read().strip())
    except:
        return 0

def rejoin():
    print("[!] Mất kết nối - Thực hiện rejoin...")
    # Thay dòng dưới bằng lệnh rejoin thực tế, ví dụ gọi subprocess hoặc am start
    os.system("echo 'REJOIN GAME'")

# Chạy chính
ensure_file()
while True:
    timestamp = read_timestamp()
    now = int(time.time())
    delay = now - timestamp

    if delay > TIMEOUT_SECONDS:
        rejoin()
    else:
        print(f"[✓] Đang online, delay: {delay}s")

    time.sleep(CHECK_INTERVAL)
