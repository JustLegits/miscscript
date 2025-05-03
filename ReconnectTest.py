import os
import time

STATUS_FILE = "/sdcard/roblox_status/status.txt"
REJOIN_DELAY = 300  # 5 phút
TIME_THRESHOLD = 120  # 2 phút
ROBLOX_LINK = "roblox://placeId=YOUR_PLACE_ID"  # <-- Thay bằng của bạn

def kill_roblox():
    os.system("su -c 'pkill -f \"com.roblox.client\"'")
    print("✅ Đã kill Roblox.")

def rejoin_game():
    os.system(f'am start -a android.intent.action.VIEW -d "{ROBLOX_LINK}"')
    print(f"✅ Đã rejoin vào {ROBLOX_LINK}")

def read_timestamp():
    try:
        with open(STATUS_FILE, "r") as f:
            return int(f.read().strip())
    except Exception as e:
        print(f"[!] Lỗi khi đọc file: {e}")
        return 0

while True:
    now = int(time.time())
    last = read_timestamp()

    diff = now - last
    print(f"[⏱️] Time diff: {diff} giây")

    if diff > TIME_THRESHOLD:
        print("[⚠️] Phát hiện offline! Rejoining...")
        kill_roblox()
        time.sleep(2)
        rejoin_game()
        time.sleep(REJOIN_DELAY)  # chờ 5p trước lần check tiếp theo
    else:
        print("✅ Online. Không cần rejoin.")

    time.sleep(60)
