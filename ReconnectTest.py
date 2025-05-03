import os
import time
import json
import subprocess
from datetime import datetime

STATUS_FILE = "/data/data/com.roblox.client/files/krnl/workspace/status.txt"
CHECK_INTERVAL = 300  # 5 phút
MAX_TIME_DIFF = 120   # 2 phút (tính bằng giây)
ROBLOX_LINK = "roblox://placeId=72829404259339"

def read_status():
    try:
        with open(STATUS_FILE, "r") as f:
            data = json.load(f)
            return data.get("time")
    except Exception as e:
        print(f"[Lỗi] Không đọc được status.txt: {e}")
        return None

def kill_roblox():
    try:
        subprocess.run(["su", "-c", "pkill -f com.roblox.client"])
        print("✅ Đã tắt Roblox")
    except Exception as e:
        print(f"[Lỗi] Không thể kill Roblox: {e}")

def rejoin_game():
    try:
        os.system(f'am start -a android.intent.action.VIEW -d "{ROBLOX_LINK}"')
        print("✅ Đã gửi intent mở Roblox")
    except Exception as e:
        print(f"[Lỗi] Không thể rejoin: {e}")

def check_status():
    unix_time = read_status()
    if not unix_time:
        print("[⚠️] Không có dữ liệu, sẽ thử rejoin")
        return True

    current_time = int(time.time())
    diff = current_time - int(unix_time)

    print(f"[i] Time hiện tại: {current_time}, time file: {unix_time}, lệch: {diff}s")

    if diff > MAX_TIME_DIFF:
        print("[⚠️] Trạng thái quá cũ, đang thực hiện rejoin...")
        return True
    else:
        print("✅ Trạng thái bình thường.")
        return False

def main():
    while True:
        if check_status():
            kill_roblox()
            time.sleep(3)
            rejoin_game()
        time.sleep(CHECK_INTERVAL)

if __name__ == "__main__":
    main()
