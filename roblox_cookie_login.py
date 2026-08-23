# pkg update && pkg upgrade
# pkg install python
# Need root, support clone package name

import os
import sys
import subprocess
import sqlite3
import time
import shutil

COOKIE_NAME = ".ROBLOSECURITY"
COOKIE_PREFIX = "_|WARNING:"
TMP_DIR = os.path.join(os.getcwd(), "tmp_roblox")
TMP_DB = os.path.join(TMP_DIR, "Cookies")

def run_su(cmd):
    """Chạy lệnh shell với quyền root và trả về (exit_code, stdout, stderr)"""
    try:
        # Thêm stdin=subprocess.DEVNULL để ngăn lệnh 'su' cướp bàn phím của Termux
        result = subprocess.run(
            ["su", "-c", cmd], 
            capture_output=True, 
            text=True, 
            timeout=60,
            stdin=subprocess.DEVNULL
        )
        return result.returncode, result.stdout.strip(), result.stderr.strip()
    except subprocess.TimeoutExpired:
        return -1, "", "Timeout: Lệnh su không phản hồi (có thể chưa cấp quyền Root)."
    except Exception as e:
        return -1, "", str(e)

def force_journal_mode(db_path, mode_byte):
    """Sửa byte 18-19 của header SQLite để ép Journal Mode (1=Legacy, 2=WAL) tránh lỗi F2FS."""
    if not os.path.exists(db_path) or os.path.getsize(db_path) < 100:
        return
    with open(db_path, "r+b") as f:
        f.seek(18)
        f.write(bytes([mode_byte, mode_byte]))

def check_root():
    code, out, err = run_su("id")
    if "uid=0" not in out:
        print("[-] Lỗi: Không có quyền Root! Hãy đảm bảo đã cấp quyền root cho Termux.")
        sys.exit(1)

def get_app_paths(pkg):
    app_data = f"/data/data/{pkg}"
    cookies_dir = f"{app_data}/app_webview/Default"
    cookies_db = f"{cookies_dir}/Cookies"
    return app_data, cookies_dir, cookies_db

def build_cookie_dict(cookie_value):
    """Tạo bộ giá trị theo chuẩn Chromium."""
    unix_epoch_offset_micros = 11644473600 * 1_000_000
    now_micros = int(time.time() * 1_000_000) + unix_epoch_offset_micros
    expires_utc = now_micros + (400 * 86400 * 1_000_000)

    return {
        "creation_utc": now_micros,
        "host_key": ".roblox.com",
        "name": COOKIE_NAME,
        "value": cookie_value,
        "path": "/",
        "expires_utc": expires_utc,
        "is_secure": 1,
        "is_httponly": 1,
        "last_access_utc": now_micros,
        "has_expires": 1,
        "is_persistent": 1,
        "priority": 1,
        "encrypted_value": b"",
        "samesite": -1,
        "source_scheme": 2,
        "top_frame_site_key": "",
        "source_port": 443,
        "last_update_utc": now_micros,
        "source_type": 0,
        "has_cross_site_ancestor": 0
    }

def extract_cookie(pkg):
    app_data, cookies_dir, cookies_db = get_app_paths(pkg)
    
    print(f"[*] Đang tắt {pkg}...")
    run_su(f"am force-stop {pkg}")
    
    code, out, _ = run_su(f"test -f {cookies_db} && echo OK")
    if "OK" not in out:
        print("[-] Lỗi: Không tìm thấy database Cookies. Hãy mở game 1 lần trước.")
        return

    os.makedirs(TMP_DIR, exist_ok=True)
    
    print("[*] Đang copy Database ra bộ nhớ tạm...")
    run_su(f"cp '{cookies_db}' '{TMP_DB}' && chmod 666 '{TMP_DB}'")
    run_su(f"if [ -f '{cookies_dir}/Cookies-wal' ]; then cp '{cookies_dir}/Cookies-wal' '{TMP_DIR}/Cookies-wal' && chmod 666 '{TMP_DIR}/Cookies-wal'; fi")

    try:
        query_cookie(TMP_DB)
    except sqlite3.DatabaseError as e:
        print(f"[*] Gặp lỗi ({e}), chuyển sang chế độ Legacy Fallback...")
        force_journal_mode(TMP_DB, 1) # Fallback Legacy
        run_su(f"rm -f '{TMP_DIR}/Cookies-wal'")
        query_cookie(TMP_DB)

    # Cleanup
    shutil.rmtree(TMP_DIR, ignore_errors=True)

def query_cookie(db_path):
    conn = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
    cursor = conn.cursor()
    cursor.execute(
        "SELECT value, encrypted_value FROM cookies WHERE name = ? AND host_key LIKE ?", 
        (COOKIE_NAME, '%roblox.com')
    )
    row = cursor.fetchone()
    conn.close()

    if not row:
        print("[-] Không tìm thấy cookie .ROBLOSECURITY. Bạn chưa đăng nhập?")
    else:
        value, enc_val = row
        if value:
            print("\n[+] ĐÃ TÌM THẤY COOKIE:\n")
            print(value)
            print("\n===============================")
        elif enc_val:
            print("[-] Cookie bị mã hóa (encrypted_value). Không thể đọc bằng plain-text.")
        else:
            print("[-] Cookie rỗng.")

def inject_cookie(pkg):
    cookie = input("Nhập cookie cần inject (Bắt đầu bằng _|WARNING: ): ").strip()
    if not cookie.startswith(COOKIE_PREFIX) or len(cookie) < 100:
        print("[-] Lỗi: Format cookie không hợp lệ!")
        return

    app_data, cookies_dir, cookies_db = get_app_paths(pkg)
    
    print(f"[*] Đang dọn dẹp và tắt {pkg}...")
    run_su(f"am force-stop {pkg}")
    run_su(f"rm -f '{cookies_dir}/Cookies-journal' '{cookies_dir}/Cookies-wal' '{cookies_dir}/Cookies-shm'")

    code, out, _ = run_su(f"test -f {cookies_db} && echo OK")
    if "OK" not in out:
        print("[-] Lỗi: Không tìm thấy database Cookies. Hãy mở game 1 lần trước.")
        return

    os.makedirs(TMP_DIR, exist_ok=True)
    run_su(f"cp '{cookies_db}' '{TMP_DB}' && chmod 666 '{TMP_DB}'")

    print("[*] Ép WAL mode bypass lỗi F2FS...")
    force_journal_mode(TMP_DB, 2)

    try:
        conn = sqlite3.connect(TMP_DB)
        cursor = conn.cursor()
        cursor.execute("PRAGMA journal_mode = WAL")
        cursor.execute("PRAGMA synchronous = NORMAL")

        # Kiểm tra encryption mode
        cursor.execute("SELECT COUNT(*) FROM cookies WHERE host_key LIKE '%roblox.com' AND length(encrypted_value) > 0")
        enc_count = cursor.fetchone()[0]
        if enc_count > 0:
            print("[-] Lỗi: WebView đang dùng mã hóa (encrypted_value). Chèn cookie plain-text sẽ thất bại.")
            conn.close()
            return

        cursor.execute("PRAGMA table_info(cookies)")
        schema_cols = [c[1] for c in cursor.fetchall()]

        cursor.execute("DELETE FROM cookies WHERE host_key LIKE '%roblox.com'")
        
        cookie_dict = build_cookie_dict(cookie)
        insert_cols = [col for col in schema_cols if col in cookie_dict]
        placeholders = ",".join(["?"] * len(insert_cols))
        values = [cookie_dict[col] for col in insert_cols]
        
        query = f"INSERT INTO cookies ({','.join(insert_cols)}) VALUES ({placeholders})"
        cursor.execute(query, values)
        
        conn.commit()
        
        # Checkpoint WAL -> Main DB
        cursor.execute("PRAGMA wal_checkpoint(TRUNCATE)")
        conn.close()
        print("[+] Sửa Database SQLite thành công!")
        
    except Exception as e:
        print(f"[-] Lỗi thao tác SQLite: {e}")
        shutil.rmtree(TMP_DIR, ignore_errors=True)
        return

    print("[*] Đang copy ngược về hệ thống và phân quyền...")
    run_su(f"rm -f '{cookies_db}.tmp'")
    run_su(f"cp '{TMP_DB}' '{cookies_db}.tmp'")
    code, out, err = run_su(f"mv '{cookies_db}.tmp' '{cookies_db}'")
    
    if code != 0:
        print(f"[-] Lỗi ghi đè DB: {err}")
        shutil.rmtree(TMP_DIR, ignore_errors=True)
        return

    # Khôi phục owner bằng lệnh stat -> chmod -> restorecon
    chown_cmd = f"(UID=$(stat -c '%u' {app_data} 2>/dev/null) && GID=$(stat -c '%g' {app_data} 2>/dev/null) && chown $UID:$GID {cookies_db}) || (set -- $(ls -nd {app_data}) && chown $3:$4 {cookies_db})"
    run_su(chown_cmd)
    run_su(f"chmod 660 {cookies_db}")
    run_su(f"restorecon {cookies_db}")
    
    shutil.rmtree(TMP_DIR, ignore_errors=True)
    print("[+] DONE! Đã chèn Cookie thành công. Hãy mở game Roblox ngay bây giờ.")

def main():
    check_root()
    print("=== ROBLOX COOKIE TOOL TERMUX ===")
    pkg = input("Nhập Package Name (VD: com.roblox.client hoặc com.roblox.client.vnggames):\n=> ").strip()
    
    if not pkg:
        print("Tên package không hợp lệ.")
        sys.exit(1)

    print("\nChọn chức năng:")
    print("1. Extract (Lấy Cookie đang đăng nhập)")
    print("2. Inject (Chèn Cookie để đăng nhập)")
    choice = input("=> ").strip()

    if choice == "1":
        extract_cookie(pkg)
    elif choice == "2":
        inject_cookie(pkg)
    else:
        print("Lựa chọn không hợp lệ.")

if __name__ == "__main__":
    main()
