#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os, time, json, subprocess, requests, sys
from colorama import Fore, Style, init

# Khởi tạo colorama
init(autoreset=True)

# ============ CẤU HÌNH & CONSTANT ============
CONFIG_FILE = "config.json"

# Cấu trúc mặc định của file config.json
DEFAULT_DB = {
    "settings": {
        "android_id": "b419fa14320149db",
        "reconnect_dir": "",
        "restart_intervals": {}  # { "package_name": minutes }
    },
    "webhook": {
        "url": "",
        "uid": ""
    },
    "accounts": [],  # List of dicts: [{"package": "...", "username": "..."}]
    "links": {}      # Dict: {"package_name": "link_server"}
}

# ============ QUẢN LÝ DATA (DATABASE) ============

def load_db():
    """Load toàn bộ config từ file json, có migrate dữ liệu cũ nếu cần."""
    data = DEFAULT_DB.copy()
    
    # 1. Nếu chưa có config.json, thử tìm các file cũ để migrate
    if not os.path.exists(CONFIG_FILE):
        print(Fore.YELLOW + "[i] Không thấy config.json, đang kiểm tra dữ liệu cũ để chuyển đổi...")
        migrated = False
        
        # Migrate Account.txt
        if os.path.exists("Account.txt"):
            try:
                with open("Account.txt", "r", encoding="utf-8") as f:
                    for line in f:
                        if "," in line:
                            parts = line.strip().split(",", 1)
                            if len(parts) == 2:
                                data["accounts"].append({"package": parts[0].strip(), "username": parts[1].strip()})
                print(Fore.GREEN + "[+] Đã nhập dữ liệu từ Account.txt")
                migrated = True
            except: pass

        # Migrate Private_Link.txt
        if os.path.exists("Private_Link.txt"):
            try:
                with open("Private_Link.txt", "r", encoding="utf-8") as f:
                    for line in f:
                        if "," in line:
                            parts = line.strip().split(",", 1)
                            if len(parts) == 2:
                                data["links"][parts[0].strip()] = parts[1].strip()
                print(Fore.GREEN + "[+] Đã nhập dữ liệu từ Private_Link.txt")
                migrated = True
            except: pass

        # Migrate Webhook.txt
        if os.path.exists("Webhook.txt"):
            try:
                lines = open("Webhook.txt", "r", encoding="utf-8").read().splitlines()
                if len(lines) > 0: data["webhook"]["url"] = lines[0].strip()
                if len(lines) > 1: data["webhook"]["uid"] = lines[1].strip()
                print(Fore.GREEN + "[+] Đã nhập dữ liệu từ Webhook.txt")
                migrated = True
            except: pass
            
        # Migrate config cũ (nếu có json config cũ cấu trúc khác)
        # (Ở đây giả sử nếu có config.json cũ thì nó sẽ được load ở bước dưới, 
        # nhưng nếu file chưa tồn tại thì ta dùng default)
        
        if migrated:
            save_db(data)
            return data

    # 2. Load bình thường
    try:
        with open(CONFIG_FILE, "r", encoding="utf-8") as f:
            loaded = json.load(f)
            # Merge keys để tránh lỗi thiếu key khi update version mới
            for k, v in DEFAULT_DB.items():
                if k not in loaded:
                    loaded[k] = v
                elif isinstance(v, dict):
                    for sub_k, sub_v in v.items():
                        if sub_k not in loaded[k]:
                            loaded[k][sub_k] = sub_v
            return loaded
    except Exception as e:
        print(Fore.RED + f"[!] Lỗi đọc config.json: {e}. Dùng cấu hình mặc định.")
        return DEFAULT_DB

def save_db(data):
    """Lưu toàn bộ data vào config.json."""
    try:
        with open(CONFIG_FILE, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
    except Exception as e:
        print(Fore.RED + f"[!] Lỗi lưu config.json: {e}")

# --- Helper functions để tương thích code cũ ---
def get_setting(key, default=None):
    db = load_db()
    return db["settings"].get(key, default)

def update_setting(key, value):
    db = load_db()
    db["settings"][key] = value
    save_db(db)

def get_accounts_list():
    """Trả về list tuples [(pkg, user)] như code cũ."""
    db = load_db()
    return [(acc["package"], acc["username"]) for acc in db["accounts"]]

def add_account(pkg, username):
    db = load_db()
    # Check trùng
    for acc in db["accounts"]:
        if acc["package"] == pkg:
            acc["username"] = username # Update nếu trùng pkg
            save_db(db)
            return
    db["accounts"].append({"package": pkg, "username": username})
    save_db(db)

def clear_accounts():
    db = load_db()
    db["accounts"] = []
    save_db(db)

def get_links_dict():
    db = load_db()
    return db["links"]

def update_link(pkg, link):
    db = load_db()
    db["links"][pkg] = link
    save_db(db)

def clear_links():
    db = load_db()
    db["links"] = {}
    save_db(db)

def get_webhook_config():
    db = load_db()
    return db["webhook"]["url"], db["webhook"]["uid"]

def update_webhook_config(url, uid):
    db = load_db()
    db["webhook"] = {"url": url, "uid": uid}
    save_db(db)

# ============ CÁC HÀM TIỆN ÍCH HỆ THỐNG ============
def msg(text, type="info"):
    if type == "info": print(Fore.BLUE + text)
    elif type == "ok": print(Fore.GREEN + text)
    elif type == "warn": print(Fore.YELLOW + text)
    elif type == "err": print(Fore.RED + text)
    else: print(text)

def prompt(text):
    return input(text+" ").strip()

def clear():
    os.system("clear" if os.name == "posix" else "cls")

def wait_back_menu():
    input(Fore.CYAN + "\n[Nhấn Enter để quay lại menu]")
    clear()

def run_cmd(cmd, check_success=True):
    try:
        result = subprocess.run(cmd, capture_output=True, text=True)
        if check_success:
            return result.returncode == 0
        return result
    except Exception as e:
        print(f"Lỗi khi chạy lệnh {cmd}: {e}")
        return False

# ============ ROBLOX ACTIONS ============
def get_custom_packages():
    keywords = ["roblox", "bduy", "mangcut", "concacug","codex","delta","arceus","ugpornkiki","nhat"]
    result = subprocess.run("pm list packages", shell=True, capture_output=True, text=True)
    if result.returncode != 0: return []
    
    pkgs = []
    for line in result.stdout.splitlines():
        if ":" not in line: continue
        pkg = line.split(":", 1)[1].strip()
        if any(keyword in pkg.lower() for keyword in keywords):
            pkgs.append(pkg)
    return pkgs

def kill_roblox_process(package):
    try:
        subprocess.run(["pkill", "-f", package], check=False)
        # print(f"[✓] Đã kill {package}") # Optional logging
    except Exception as e:
        print(f"[!] Lỗi khi kill {package}: {e}")
    time.sleep(2)

def format_server_link(link):
    link = link.strip()
    if not link: return ""
    if "roblox.com" in link or link.startswith("roblox://"): return link
    if link.isdigit(): return f"roblox://placeID={link}"
    return ""

def launch_roblox(package, server_link):
    if not server_link: return
    try:
        subprocess.run([
            "am", "start", "-n", f"{package}/com.roblox.client.startup.ActivitySplash",
            "-d", server_link,
        ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(2)
        subprocess.run([
            "am", "start", "-n", f"{package}/com.roblox.client.ActivityProtocolLaunch",
            "-d", server_link,
        ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception as e:
        msg(f"[!] Lỗi mở Roblox: {e}", "err")

# ============ RECONNECT DIR & HEARTBEAT ============
def find_reconnect_dirs(bases=None):
    if bases is None: bases = ["/sdcard/Android/data", "/storage/emulated/0"]
    results = []
    for base in bases:
        if not os.path.exists(base): continue
        for root, dirs, files in os.walk(base):
            if "Workspace" in dirs:
                workspace_dir = os.path.join(root, "Workspace")
                reconnect_dir = os.path.join(workspace_dir, "Reconnect")
                if not os.path.exists(reconnect_dir):
                    try:
                        os.makedirs(reconnect_dir, exist_ok=True)
                        print(Fore.GREEN + f"Đã tạo thư mục: {reconnect_dir}")
                    except: continue
                results.append(reconnect_dir)
    return results

def find_autoexecute_dirs(bases=None):
    if bases is None: bases = ["/sdcard/Android/data", "/storage/emulated/0"]
    results = []
    for base in bases:
        if not os.path.exists(base): continue
        for root, dirs, files in os.walk(base):
            for dirname in ["Autoexecute", "Autoexec"]:
                if dirname in dirs:
                    results.append(os.path.join(root, dirname))
    return results

def read_heartbeat(path):
    try:
        if not os.path.exists(path):
            return (False, 1e9, "", "Không tìm thấy file heartbeat")
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
        status = data.get("status", "")
        ts = float(data.get("timestamp", 0))
        user = data.get("user", "")
        age = time.time() - ts
        
        if status.lower() != "online": return (False, age, user, "Status khác 'online'")
        if abs(age) > 60: return (False, age, user, f"Heartbeat quá cũ ({age:.0f}s)")
        return (True, age, user, "OK")
    except Exception as e:
        return (False, 1e9, "", f"Lỗi đọc JSON: {e}")

# ============ WEBHOOK ============
def send_webhook(msgtxt):
    url, uid = get_webhook_config()
    if not url: return
    try:
        content = f"<@{uid}> {msgtxt}" if uid else msgtxt
        requests.post(url, json={"content": content}, timeout=5)
    except: pass

# ============ OPTIMIZATION FUNCTIONS ============
def disable_bloatware_apps():
    print(Fore.BLUE + "Đang vô hiệu hóa các ứng dụng không cần thiết (safe list)...")
    apps_to_disable = [
        "com.wsh.toolkit", "com.wsh.appstorage", "com.wsh.launcher2", 
        "com.og.toolcenter", "com.og.gamecenter", "com.wsh.appstore", "com.android.tools", 
        "net.sourceforge.opencamera", "com.sec.android.gallery3d", "com.miui.gallery", 
        "com.coloros.gallery3d", "com.vivo.gallery", "com.motorola.gallery", 
        "com.transsion.gallery", "com.sonyericsson.album", "com.lge.gallery", 
        "com.htc.album", "com.huawei.photos", "com.android.gallery3d", "com.android.gallery",
        "com.sec.android.app.clockpackage", "com.miui.clock", "com.coloros.alarmclock",
        "com.vivo.alarmclock", "com.motorola.timeweatherwidget", "com.huawei.clock",
        "com.lge.clock", "com.htc.alarmclock", "com.android.dreams.basic", 
        "com.android.dreams.phototable", "com.android.wallpaperbackup", "com.android.wallpapercropper"
    ]
    for package_name in apps_to_disable:
        if run_cmd(["pm", "disable-user", "--user", "0", package_name], check_success=False):
            print(Fore.GREEN + f"Đã vô hiệu hóa: {package_name}")
        else:
            print(Fore.YELLOW + f"Bỏ qua: {package_name}")

def set_android_id():
    current_id = get_setting("android_id", "b419fa14320149db")
    user_input = input(f"Nhập Android ID mới (Enter dùng ID lưu trong config: {current_id}): ").strip()
    
    new_id = user_input if user_input else current_id
    
    print(Fore.YELLOW + f"Đang đặt Android ID thành {new_id}...", end=" ")
    if run_cmd(["settings", "put", "secure", "android_id", new_id], check_success=True):
        print(Fore.GREEN + "Hoàn tất")
        update_setting("android_id", new_id)
        return True
    else:
        print(Fore.RED + "Thất bại (Cần quyền root/adb)")
        return False

def disable_animations():
    print(Fore.YELLOW + "Đang tắt hiệu ứng động Android...", end=" ")
    animation_settings = [
        ["settings", "put", "global", "window_animation_scale", "0"],
        ["settings", "put", "global", "transition_animation_scale", "0"],
        ["settings", "put", "global", "animator_duration_scale", "0"]
    ]
    success = True
    for cmd in animation_settings:
        if not run_cmd(cmd, check_success=True): success = False
    
    if success: print(Fore.GREEN + "Thành công")
    else: print(Fore.RED + "Thất bại một phần")
    return success

# ============ MENU FUNCTIONS ============

# /1 Auto Rejoin
def auto_rejoin():
    db = load_db()
    settings = db["settings"]
    reconnect_dir = settings.get("reconnect_dir", "")
    restart_intervals = settings.get("restart_intervals", {})
    
    # 1. Check Reconnect Dir
    if not reconnect_dir or not os.path.exists(reconnect_dir):
        found = find_reconnect_dirs()
        if not found:
            reconnect_dir = prompt("Không tìm thấy thư mục Reconnect. Nhập thủ công:")
        elif len(found) == 1:
            reconnect_dir = found[0]
        else:
            print("Tìm thấy nhiều thư mục:")
            for i, d in enumerate(found): print(f"{i+1}. {d}")
            idx = int(input("Chọn số: ")) - 1
            reconnect_dir = found[idx]
        # Lưu lại path mới vào DB
        update_setting("reconnect_dir", reconnect_dir)
    
    # 2. Setup Accounts & Links
    accounts = get_accounts_list() # list tuples
    links = get_links_dict()
    for pkg in links:
        links[pkg] = format_server_link(links[pkg])
    
    # 3. Apply Android ID (Nếu cần thiết phải set lại mỗi lần chạy)
    saved_android_id = settings.get("android_id")
    if saved_android_id:
         run_cmd(["settings", "put", "secure", "android_id", saved_android_id], check_success=False)

    # 4. Init Timers
    last_restart_track = {pkg: time.time() for pkg, _ in accounts}
    
    msg("[i] Bắt đầu auto rejoin local (Single Config Version)...", "info")
    print(Fore.CYAN + "--- Cấu hình Auto Restart ---")
    for pkg, mins in restart_intervals.items():
        if mins > 0: print(f"> {pkg}: {mins} phút")
    print("-----------------------------")

    try:
        while True:
            clear()
            msg(f"[i] Vòng check mới lúc {time.strftime('%H:%M:%S')}", "info")
            current_time = time.time()

            for pkg, username in accounts:
                # A. Scheduled Restart Logic
                interval_minutes = restart_intervals.get(pkg, 0)
                if pkg not in last_restart_track: last_restart_track[pkg] = current_time
                
                if interval_minutes > 0:
                    elapsed = current_time - last_restart_track[pkg]
                    if elapsed >= (interval_minutes * 60):
                        msg(f"[!!!] SCHEDULED RESTART: {username} ({interval_minutes}m)", "warn")
                        kill_roblox_process(pkg)
                        launch_roblox(pkg, links.get(pkg, ""))
                        last_restart_track[pkg] = time.time()
                        send_webhook(f"♻️ **Scheduled Restart** executed for **{username}**.")
                        time.sleep(5)
                        continue

                # B. Heartbeat Logic
                hb_file = os.path.join(reconnect_dir, f"reconnect_status_{username}.json")
                online, age, uname, reason = read_heartbeat(hb_file)
                
                if online:
                    msg(f"[✓] {username} online ({age:.0f}s)", "ok")
                else:
                    msg(f"[*] {username} OFFLINE ({reason}) → rejoin {pkg}", "err")
                    kill_roblox_process(pkg)
                    launch_roblox(pkg, links.get(pkg, ""))
                    last_restart_track[pkg] = time.time() # Reset timer khi crash
                    send_webhook(f"⚠️ **{username} OFFLINE** ({reason}) → rejoined {pkg}")
                
                time.sleep(3)
            
            msg(f"[i] Ngủ 200s...", "info")
            time.sleep(200)
    except KeyboardInterrupt:
        msg("[i] Dừng auto rejoin.")

# /2 User ID Menu
def user_id_menu():
    pkgs = get_custom_packages()
    if not pkgs:
        msg("[!] Không tìm thấy package Roblox nào.", "err")
        wait_back_menu()
        return

    print("Chọn package:")
    for i, p in enumerate(pkgs): print(f"{i+1}. {p}")
    try:
        idx = int(input("Chọn số: ")) - 1
        pkg = pkgs[idx]
        username = prompt("Nhập username:")
        add_account(pkg, username)
        msg(f"[i] Đã lưu User: {username} cho {pkg}", "ok")
    except:
        msg("[!] Lỗi nhập liệu.", "err")
    wait_back_menu()

# /3 Common Link
def set_common_link():
    pkgs = get_custom_packages()
    if not pkgs: return
    
    link = prompt("Nhập ID Game/Link server chung:")
    formatted = format_server_link(link)
    if not formatted:
        msg("[!] Link không hợp lệ.", "err")
        wait_back_menu()
        return
    
    for pkg in pkgs:
        update_link(pkg, formatted)
    msg(f"[i] Đã lưu link chung cho {len(pkgs)} package.", "ok")
    wait_back_menu()

# /4 Private Link
def set_package_link():
    pkgs = get_custom_packages()
    print("Chọn package:")
    for i, p in enumerate(pkgs): print(f"{i+1}. {p}")
    try:
        idx = int(input("Chọn số: ")) - 1
        pkg = pkgs[idx]
        link = prompt(f"Nhập link cho {pkg}:")
        formatted = format_server_link(link)
        if formatted:
            update_link(pkg, formatted)
            msg("[✓] Đã lưu link.", "ok")
        else:
            msg("[!] Link lỗi.", "err")
    except: pass
    wait_back_menu()

# /5 Delete
def delete_entry():
    print("1. Xóa tất cả Accounts")
    print("2. Xóa tất cả Server Links")
    print("3. Xóa cả hai")
    t = prompt("Chọn:")
    if t == "1":
        clear_accounts()
        msg("Đã xóa accounts.", "ok")
    elif t == "2":
        clear_links()
        msg("Đã xóa links.", "ok")
    elif t == "3":
        clear_accounts()
        clear_links()
        msg("Đã xóa tất cả.", "ok")
    wait_back_menu()

# /6 Webhook
def set_webhook_menu():
    url = prompt("Webhook URL:")
    uid = prompt("Discord User ID (Enter để bỏ qua):")
    update_webhook_config(url, uid)
    msg("[✓] Đã lưu webhook.", "ok")
    wait_back_menu()

# /7 Find UID AppStorage
def find_uid_from_appstorage():
    pkgs = get_custom_packages()
    found_count = 0
    for pkg in pkgs:
        fpath = f'/data/data/{pkg}/files/appData/LocalStorage/appStorage.json'
        uid, username = "", ""
        try:
            with open(fpath, "r", encoding="utf-8") as f:
                data = json.load(f)
            uid = str(data.get("UserId", ""))
        except: pass

        if uid:
            try:
                r = requests.get(f"https://users.roblox.com/v1/users/{uid}", timeout=5)
                if r.status_code == 200:
                    username = r.json().get("name", "")
            except: pass

        if username:
            add_account(pkg, username)
            msg(f"[+] Tìm thấy {username} ({pkg})", "ok")
            found_count += 1
        else:
            msg(f"[-] Không tìm thấy user trong {pkg}", "err")
    
    if found_count > 0:
        link = prompt("Nhập link chung cho các acc vừa tìm thấy (Enter để bỏ qua):")
        formatted = format_server_link(link)
        if formatted:
            for pkg in pkgs: update_link(pkg, formatted)
            msg("[✓] Đã lưu link chung.", "ok")

    wait_back_menu()

# /8 Show Saved
def show_saved():
    db = load_db()
    print(Fore.CYAN + "--- ACCOUNTS ---")
    for acc in db["accounts"]:
        print(f"Pkg: {acc['package']} | User: {acc['username']}")
    
    print(Fore.CYAN + "\n--- LINKS ---")
    for pkg, link in db["links"].items():
        print(f"{pkg}: {link}")
    
    print(Fore.CYAN + "\n--- WEBHOOK ---")
    print(f"URL: {db['webhook']['url']}")
    print(f"UID: {db['webhook']['uid']}")
    
    print(Fore.CYAN + "\n--- SETTINGS ---")
    print(f"AndroidID: {db['settings']['android_id']}")
    print(f"Reconnect Dir: {db['settings']['reconnect_dir']}")
    wait_back_menu()

# /9 Optimize
def optimize_android_menu():
    print("\n===== TỐI ƯU MÁY =====")
    print("1. Chạy tất cả (Bloatware, AndroidID, Animation)")
    print("2. Vô hiệu hóa Bloatware")
    print("3. Đổi Android ID")
    print("4. Tắt Animation")
    print("5. Quay lại")
    c = input("Chọn: ").strip()
    if c == "1":
        disable_bloatware_apps()
        set_android_id()
        disable_animations()
    elif c == "2": disable_bloatware_apps()
    elif c == "3": set_android_id()
    elif c == "4": disable_animations()
    elif c == "5": return
    else: return
    wait_back_menu()

# /10 AutoExecute Script
def add_autoexecute_script():
    dirs = find_autoexecute_dirs()
    if not dirs:
        msg("[!] Không thấy thư mục Autoexecute.", "err")
        return
    auto_dir = dirs[0] if len(dirs) == 1 else dirs[int(input("Chọn thư mục số: "))-1]

    print("1. Script Check Online (GitHub)")
    print("2. Tự nhập script")
    c = input("Chọn: ").strip()
    
    if c == "1":
        fname = os.path.join(auto_dir, "checkonline.txt")
        content = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/JustLegits/miscscript/main/checkonline.lua"))()'
    elif c == "2":
        # Tìm file tiếp theo
        existing = [f for f in os.listdir(auto_dir) if f.startswith("autoexecute") and f.endswith(".txt")]
        nums = [int(f.replace("autoexecute","").replace(".txt","")) for f in existing if f[11:-4].isdigit()]
        next_num = max(nums) + 1 if nums else 1
        fname = os.path.join(auto_dir, f"autoexecute{next_num}.txt")
        
        print("Nhập script (Gõ 'end' để kết thúc):")
        lines = []
        while True:
            l = input()
            if l.strip().lower() == "end": break
            lines.append(l)
        content = "\n".join(lines)
    else: return

    with open(fname, "w", encoding="utf-8") as f: f.write(content + "\n")
    msg(f"[✓] Đã lưu vào {fname}", "ok")
    wait_back_menu()

# /11 Export/Import
def export_import_config():
    print("1. Export Config (In ra màn hình & Copy)")
    print("2. Import Config (Dán JSON vào đây)")
    c = input("Chọn: ").strip()
    
    if c == "1":
        db = load_db()
        json_str = json.dumps(db, indent=2, ensure_ascii=False)
        print(Fore.GREEN + "\nCopy nội dung dưới đây và lưu lại:\n")
        print(json_str)
        # Gửi webhook backup nếu có
        url, uid = get_webhook_config()
        if url:
            try:
                msg("[i] Đang gửi backup lên webhook...", "info")
                files = {'file': ('config_backup.json', json_str, 'application/json')}
                requests.post(url, files=files, data={"content": f"Backup Config LocalRejoin <@{uid}>"}, timeout=10)
                msg("[✓] Đã gửi backup lên webhook.", "ok")
            except: pass

    elif c == "2":
        raw = prompt("Dán nội dung JSON vào đây (hoặc URL):")
        try:
            if raw.startswith("http"):
                new_data = requests.get(raw).json()
            else:
                new_data = json.loads(raw)
            save_db(new_data)
            msg("[✓] Import thành công!", "ok")
        except Exception as e:
            msg(f"[!] Lỗi import: {e}", "err")
    wait_back_menu()

# /12 Startup
def manage_startup():
    path = "/data/data/com.termux/files/home/.termux/boot/startup.sh"
    print("1. Bật Auto Start\n2. Tắt Auto Start")
    c = input("Chọn: ").strip()
    if c == "1":
        os.makedirs(os.path.dirname(path), exist_ok=True)
        content = """#!/data/data/com.termux/files/usr/bin/bash
sleep 20
su -c "export PATH=$PATH:/data/data/com.termux/files/usr/bin && cd /sdcard/Download && python local_rejoin.py --auto" >> ~/local_rejoin.log 2>&1
"""
        with open(path, "w") as f: f.write(content)
        os.chmod(path, 0o755)
        msg("[✓] Đã bật startup.", "ok")
    elif c == "2":
        if os.path.exists(path): os.remove(path)
        msg("[✓] Đã tắt startup.", "ok")
    wait_back_menu()

# /13 Restart Interval
def restart_interval_menu():
    db = load_db()
    current = db["settings"].get("restart_intervals", {})
    
    print("1. Cài đặt TẤT CẢ package")
    print("2. Cài đặt TỪNG package")
    c = input("Chọn: ").strip()
    
    pkgs = get_custom_packages()
    if not pkgs: return
    
    if c == "1":
        m = int(input("Số phút (0 để tắt): "))
        for p in pkgs: current[p] = m
    elif c == "2":
        for i, p in enumerate(pkgs): print(f"{i+1}. {p} ({current.get(p,0)}m)")
        idx = int(input("Chọn số: ")) - 1
        m = int(input("Số phút: "))
        current[pkgs[idx]] = m
    
    db["settings"]["restart_intervals"] = current
    save_db(db)
    msg("[✓] Đã lưu cài đặt restart.", "ok")
    wait_back_menu()

# ============ MAIN MENU ============
def menu():
    while True:
        clear()
        print(Fore.LIGHTGREEN_EX + """
======== LOCAL REJOIN PRO (SINGLE CONFIG) ========
1.  Auto Rejoin (Chạy tool)
2.  Thêm User ID (Thủ công)
3.  Link Server Chung (Tất cả pack)
4.  Link Server Riêng (Từng pack)
5.  Xóa dữ liệu (Account/Link)
6.  Cấu hình Webhook Discord
7.  Auto Scan User từ AppStorage
8.  Xem thông tin đã lưu
9.  Tối ưu máy (AndroidID, Bloatware...)
10. Script AutoExecute
11. Backup / Restore Config
12. Quản lý Auto Startup
13. Cài đặt Auto Restart (Định kỳ)
14. Thoát
==================================================
""")
        c = input("Chọn: ").strip()
        if c == "1": auto_rejoin()
        elif c == "2": user_id_menu()
        elif c == "3": set_common_link()
        elif c == "4": set_package_link()
        elif c == "5": delete_entry()
        elif c == "6": set_webhook_menu()
        elif c == "7": find_uid_from_appstorage()
        elif c == "8": show_saved()
        elif c == "9": optimize_android_menu()
        elif c == "10": add_autoexecute_script()
        elif c == "11": export_import_config()
        elif c == "12": manage_startup()
        elif c == "13": restart_interval_menu()
        elif c == "14": break
        else: msg("Sai lựa chọn", "err")

if __name__ == "__main__":
    # Load config một lần để check migrate ngay khi mở tool
    load_db() 
    
    if len(sys.argv) > 1 and sys.argv[1] == "--auto":
        auto_rejoin()
    else:
        menu()