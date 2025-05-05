# TERMUX require python
# pkg install python
# python <(curl -s https://raw.githubusercontent.com/JustLegits/miscscript/refs/heads/main/Reconnect.py)
# Only Delta hihi (●'◡'●)
# Với quyền root

import time
import json
import os
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import logging
from logging.handlers import RotatingFileHandler

# Cấu hình logging
log_filename = "status_watcher.log"
log_max_size = 10 * 1024 * 1024  # 10MB
log_backup_count = 5  # Tối đa 5 file backup

# Tạo thư mục logs nếu nó không tồn tại
log_dir = os.path.dirname(log_filename)
if log_dir and not os.path.exists(log_dir):
    os.makedirs(log_dir)

logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s - %(levelname)s - %(message)s')
handler = RotatingFileHandler(log_filename, maxBytes=log_max_size,
                            backupCount=log_backup_count)
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
handler.setFormatter(formatter)
logging.getLogger('').addHandler(handler)

# Đường dẫn đến file status.json
file_path = "status.json"

# Thời gian chờ giữa các lần kiểm tra (giây)
wait_time = 120

# Biến toàn cục để theo dõi trạng thái kết nối và thời gian
global is_disconnected
global last_check_time
is_disconnected = False
last_check_time = 0


# Lớp xử lý sự kiện của Watchdog
class MyEventHandler(FileSystemEventHandler):
    def on_modified(self, event):
        if event.src_path.endswith(file_path):
            handle_file_change()

    def on_created(self, event):
        if event.src_path.endswith(file_path):
            handle_file_change()


# Hàm xử lý thay đổi file
def handle_file_change():
    global is_disconnected
    global last_check_time
    try:
        with open(file_path, "r") as f:
            data = json.load(f)
            # Kiểm tra các khóa cần thiết
            if "isDisconnected" in data and "time" in data:
                is_disconnected = data["isDisconnected"]
                last_check_time = data["time"]
                log_message = f"File {file_path} changed.  isDisconnected: {is_disconnected}, Time: {last_check_time}"
                logging.info(log_message)  # Sử dụng logging
            else:
                logging.warning(f"File {file_path} thiếu các khóa 'isDisconnected' hoặc 'time'. Bỏ qua cập nhật.")
    except json.JSONDecodeError:
        logging.error(f"Lỗi giải mã JSON trong file {file_path}. Bỏ qua cập nhật.")
    except FileNotFoundError:
        logging.error(f"File {file_path} không tồn tại.  Có thể được tạo lại.")
    except Exception as e:
        logging.error(f"Lỗi không xác định khi đọc file {file_path}: {e}")


# Hàm kiểm tra trạng thái và đưa ra cảnh báo
def check_status():
    global is_disconnected
    global last_check_time
    current_time = time.time()
    time_difference = current_time - last_check_time

    if is_disconnected and time_difference > wait_time:
        message = "Mất kết nối quá 120 giây! Hãy kiểm tra lại kết nối của bạn."
        logging.warning(message)  # Sử dụng logging
        print(message) # In ra console để người dùng thấy

    elif not is_disconnected:
        logging.info("Người chơi vẫn kết nối.") # Sử dụng logging
        print("Người chơi vẫn kết nối.")

def main():
    # Lặp lại kiểm tra trạng thái
    while True:
        check_status()
        time.sleep(wait_time)

if __name__ == "__main__":
    # Tạo một observer và bắt đầu theo dõi file
    event_handler = MyEventHandler()
    observer = Observer()
    observer.schedule(event_handler, path=".", recursive=False)  # Theo dõi thư mục hiện tại
    observer.start()
    logging.info(f"Đang theo dõi file {file_path} để phát hiện thay đổi.")
    try:
        main()
    except KeyboardInterrupt:
        observer.stop()
        observer.join()
        logging.info("Chương trình kết thúc.")
