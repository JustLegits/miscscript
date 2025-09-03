#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os, time, json, subprocess, requests, sys
from colorama import Fore, Style, init
init(autoreset=True)

CONFIG_FILE = "config.json"
SERVER_LINKS_FILE = "Private_Link.txt"
ACCOUNTS_FILE = "Account.txt"
WEBHOOK_FILE = "Webhook.txt"
ANDROID_ID = "b419fa14320149db"

# ============ Các hàm tiện ích ============
def msg(text, type="info"):
    print(text)

def prompt(text):
    return input(text+" ").strip()

def wait_back_menu():
    input("[Nhấn Enter để quay lại menu]")
 
def run_cmd(cmd, check_success=True):
    try:
        result = subprocess.run(cmd, capture_output=True, text=True)
        if check_success:
            return result.returncode == 0
        return result
    except Exception as e:
        print(f"Lỗi khi chạy lệnh {cmd}: {e}")
        return False
     
# ============ File IO ============
def load_pairs(path):
    if not os.path.exists(path):
        return []
    pairs = []
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or "," not in line:
                continue
            a, b = line.split(",", 1)
            pairs.append((a.strip(), b.strip()))
    return pairs

def save_pairs(path, pairs):
    with open(path, "w", encoding="utf-8") as f:
        for a, b in pairs:
            f.write(f"{a},{b}\n")

def load_accounts():
    return load_pairs(ACCOUNTS_FILE)

def save_accounts(accs):
    save_pairs(ACCOUNTS_FILE, accs)

def load_server_links():
    return load_pairs(SERVER_LINKS_FILE)

def save_server_links(links):
    save_pairs(SERVER_LINKS_FILE, links)

# ============ Roblox actions ============
def get_custom_packages():
    # Các từ khóa nhận diện package
    keywords = ["roblox", "bduy", "mangcut", "concacug"]

    result = subprocess.run(
        "pm list packages",
        shell=True,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return []

    pkgs = []
    for line in result.stdout.splitlines():
        if ":" not in line:
            continue
        pkg = line.split(":", 1)[1].strip()
        # Giữ lại nếu tên chứa 1 trong các từ khóa
        if any(keyword in pkg.lower() for keyword in keywords):
            pkgs.append(pkg)
    return pkgs

def kill_roblox_process(package):
    try:
        subprocess.run(["am", "force-stop", package], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(3)
    except Exception as e:
        msg(f"[!] Lỗi khi dừng {package}: {e}", "err")

def format_server_link(link):
    link = link.strip()
    if not link:
        return ""
    if "roblox.com" in link or link.startswith("roblox://"):
        return link
    if link.isdigit():
        return f"roblox://placeID={link}"
    return ""

def launch_roblox(package, server_link):
    if not server_link:
        return
    try:
        subprocess.run([
            "am", "start", "-n",
            f"{package}/com.roblox.client.startup.ActivitySplash",
            "-d", server_link,
        ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(4)
        subprocess.run([
            "am", "start", "-n",
            f"{package}/com.roblox.client.ActivityProtocolLaunch",
            "-d", server_link,
        ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception as e:
        msg(f"[!] Lỗi mở Roblox: {e}", "err")

# ============ Config & Reconnect dir ============
def load_config():
    if os.path.exists(CONFIG_FILE):
        try:
            return json.load(open(CONFIG_FILE,"r",encoding="utf-8"))
        except: pass
    return {}

def save_config(cfg):
    json.dump(cfg, open(CONFIG_FILE,"w",encoding="utf-8"), indent=2)

import os

def find_reconnect_dirs(bases=None):
    if bases is None:
        bases = [
            "/sdcard/Android/data",
            "/storage/emulated/0"
        ]
    
    results = []
    for base in bases:
        if not os.path.exists(base):
            continue
        for root, dirs, files in os.walk(base):
            if "Workspace" in dirs:
                workspace_dir = os.path.join(root, "Workspace")
                reconnect_dir = os.path.join(workspace_dir, "Reconnect")
                if not os.path.exists(reconnect_dir):
                    try:
                        os.makedirs(reconnect_dir, exist_ok=True)
                        print(Fore.LIGHTGREEN_EX + f"Đã tạo thư mục: {reconnect_dir}")
                    except Exception as e:
                        print(Fore.LIGHTRED_EX + f"Lỗi tạo thư mục {reconnect_dir}: {e}")
                        continue
                results.append(reconnect_dir)
    return results

# ============ Heartbeat ============
def read_heartbeat(path):
    try:
        data = json.load(open(path,"r",encoding="utf-8"))
        status = data.get("status", "")
        ts = float(data.get("timestamp", 0))
        user = data.get("user", "")
        age = time.time() - ts
        online = (status.lower() == "online" and abs(age) <= 60)
        return (online, age, user)
    except:
        return (False, 1e9, "")

# ============ Webhook ============
def set_webhook(url, user_id=""):
    with open(WEBHOOK_FILE, "w", encoding="utf-8") as f:
        f.write(url.strip() + "\n" + user_id.strip())

def get_webhook():
    if not os.path.exists(WEBHOOK_FILE):
        return "", ""
    lines = open(WEBHOOK_FILE, "r", encoding="utf-8").read().splitlines()
    url = lines[0].strip() if len(lines) > 0 else ""
    uid = lines[1].strip() if len(lines) > 1 else ""
    return url, uid

def send_webhook(msgtxt):
    url, uid = get_webhook()
    if not url:
        return
    try:
        if uid:
            content = f"<@{uid}> {msgtxt}"
        else:
            content = msgtxt
        requests.post(url, json={"content": content}, timeout=5)
    except:
        pass

def disable_bloatware_apps():
    print(Fore.LIGHTBLUE_EX + "Đang vô hiệu hóa các ứng dụng không cần thiết (safe list)...")
    apps_to_disable = [
        "com.wsh.toolkit", "com.wsh.appstorage", "com.wsh.launcher2", 
        "com.og.toolcenter", "com.og.gamecenter", "com.og.launcher",
        "com.wsh.appstore", "com.android.tools", 
        "net.sourceforge.opencamera",
        # Gallery apps từ OEM
        "com.sec.android.gallery3d", "com.miui.gallery", "com.coloros.gallery3d",
        "com.vivo.gallery", "com.motorola.gallery", "com.transsion.gallery",
        "com.sonyericsson.album", "com.lge.gallery", "com.htc.album", "com.huawei.photos",
        "com.android.gallery3d", "com.android.gallery",
        # Clock/Alarm OEM (để tránh duplicate với đồng hồ mặc định)
        "com.sec.android.app.clockpackage", "com.miui.clock", "com.coloros.alarmclock",
        "com.vivo.alarmclock", "com.motorola.timeweatherwidget",
        "com.huawei.clock", "com.lge.clock", "com.htc.alarmclock",
        # Misc rác ít dùng
        "com.android.dreams.basic", "com.android.dreams.phototable",
        "com.android.wallpaperbackup", "com.android.wallpapercropper"
    ]
    for package_name in apps_to_disable:
        if run_cmd(["pm", "disable-user", "--user", "0", package_name], check_success=False):
            print(Fore.LIGHTGREEN_EX + f"Đã vô hiệu hóa: {package_name}")
        else:
            print(Fore.LIGHTYELLOW_EX + f"Bỏ qua hoặc không thể vô hiệu hóa: {package_name}")

def set_android_id():
    global ANDROID_ID
    user_input = input(f"Nhập Android ID mới (Enter để dùng mặc định: {ANDROID_ID}): ").strip()
    if user_input:
        ANDROID_ID = user_input

    print(Fore.LIGHTYELLOW_EX + f"Đang đặt Android ID thành {ANDROID_ID}...", end=" ")
    if run_cmd(["settings", "put", "secure", "android_id", ANDROID_ID], check_success=True):
        print(Fore.LIGHTGREEN_EX + "Hoàn tất")
        return True
    else:
        print(Fore.LIGHTRED_EX + "Không thể đặt Android ID")
        return False

def disable_animations():
    print(Fore.LIGHTYELLOW_EX + "Đang tắt hiệu ứng động Android...", end=" ")
    animation_settings = [
        ["settings", "put", "global", "window_animation_scale", "0"],
        ["settings", "put", "global", "transition_animation_scale", "0"],
        ["settings", "put", "global", "animator_duration_scale", "0"]
    ]
    success = True
    for cmd in animation_settings:
        if not run_cmd(cmd, check_success=True):
            print(Fore.LIGHTRED_EX + f"Không thể tắt {cmd[3]}")
            success = False
    if success:
        print(Fore.LIGHTGREEN_EX + "Đã tắt tất cả hiệu ứng động thành công")
    return success

# ============ MENU FUNCTIONS ============
def auto_rejoin():
    cfg = load_config()
    reconnect_dir = cfg.get("reconnect_dir")

    if not reconnect_dir or not os.path.exists(reconnect_dir):
        found = find_reconnect_dirs()
        if not found:
            reconnect_dir = prompt("Không tìm thấy. Nhập thủ công đường dẫn Reconnect:")
        elif len(found) == 1:
            reconnect_dir = found[0]
        else:
            print("Tìm thấy nhiều thư mục:")
            for i, d in enumerate(found):
                print(f"{i+1}. {d}")
            idx = int(input("Chọn số: ")) - 1
            reconnect_dir = found[idx]
        cfg["reconnect_dir"] = reconnect_dir
        save_config(cfg)

    accounts = load_accounts()  # (package, username)
    links = dict(load_server_links())
    for pkg in list(links.keys()):
        links[pkg] = format_server_link(links[pkg])

    msg("[i] Bắt đầu auto rejoin local...")
    try:
        while True:
            for pkg, username in accounts:
                hb_file = os.path.join(reconnect_dir, f"reconnect_status_{username}.json")
                online, age, uname = read_heartbeat(hb_file)
                if online:
                    msg(f"[✓] {username} online (age={age:.0f}s)", "ok")
                else:
                    msg(f"[*] {username} offline (age={age:.0f}s) → rejoin {pkg}", "err")
                    kill_roblox_process(pkg)
                    link = links.get(pkg, "")
                    launch_roblox(pkg, link)
                    send_webhook(f"{username} offline → rejoined {pkg}")
                time.sleep(5)
            time.sleep(200)
    except KeyboardInterrupt:
        msg("[i] Dừng auto rejoin.")

# /2: thêm username thủ công
def user_id_menu():
    accounts = load_accounts()
    pkg = prompt("Nhập package Roblox:")
    username = prompt("Nhập username:")
    accounts.append((pkg, username))
    save_accounts(accounts)
    msg("[i] Đã lưu Username.", "ok")
    wait_back_menu()

# /3: thiết lập link chung
def set_common_link():
    link = prompt("Nhập ID Game/Link server chung:")
    pkgs = [pkg for pkg,_ in load_accounts()]
    save_server_links([(pkg, link) for pkg in pkgs])
    msg("[i] Đã lưu link chung.", "ok")
    wait_back_menu()

# /4: gán link riêng
def set_package_link():
    links = load_server_links()
    pkg = prompt("Nhập package Roblox:")
    link = prompt("Nhập link cho package này:")
    links = [(p,l) for p,l in links if p!=pkg]
    links.append((pkg, link))
    save_server_links(links)
    msg("[i] Đã lưu link riêng.", "ok")
    wait_back_menu()

# /5: xoá
def delete_entry():
    t = prompt("Xóa (1=Username, 2=Link, 3=Cả hai):")
    if t=="1":
        accounts = load_accounts()
        username = prompt("Nhập username cần xóa:")
        accounts = [(p,u) for p,u in accounts if u!=username]
        save_accounts(accounts)
        msg("[i] Đã xóa username.", "ok")
    elif t=="2":
        links = load_server_links()
        pkg = prompt("Nhập package cần xóa link:")
        links = [(p,l) for p,l in links if p!=pkg]
        save_server_links(links)
        msg("[i] Đã xóa link.", "ok")
    elif t=="3":
        accounts = load_accounts()
        username = prompt("Nhập username cần xóa:")
        accounts = [(p,u) for p,u in accounts if u!=username]
        save_accounts(accounts)
        links = load_server_links()
        pkg = prompt("Nhập package cần xóa link:")
        links = [(p,l) for p,l in links if p!=pkg]
        save_server_links(links)
        msg("[i] Đã xóa cả username và link.", "ok")
    wait_back_menu()

# /6: webhook
def set_webhook_menu():
    url = prompt("Nhập webhook URL:")
    user_id = prompt("Nhập Discord User ID để ping (có thể bỏ trống):")
    set_webhook(url, user_id)
    msg("[i] Đã lưu webhook và user ID.", "ok")
    wait_back_menu()

# /7: dùng UID từ appStorage.json → API lấy username
def find_uid_from_appstorage():
    pkgs = get_custom_packages()
    accounts = []
    for pkg in pkgs:
        fpath = f'/data/data/{pkg}/files/appData/LocalStorage/appStorage.json'
        try:
            data = json.load(open(fpath,"r",encoding="utf-8"))
            uid = str(data.get("UserId",""))
        except:
            uid = ""
        username = ""
        if uid:
            try:
                r = requests.get(f"https://users.roblox.com/v1/users/{uid}", timeout=5)
                if r.status_code==200:
                    username = r.json().get("name","")
            except: pass
        if username:
            accounts.append((pkg, username))
            msg(f"Tìm thấy username {username} cho {pkg}", "ok")
        else:
            msg(f"Không tìm thấy UID/username cho {pkg}", "err")
    if accounts:
        save_accounts(accounts)
        msg("[i] Đã lưu username từ appStorage.", "ok")
        link = prompt("Nhập link chung cho các package:")
        formatted = format_server_link(link)
        if formatted:
            save_server_links([(pkg, formatted) for pkg,_ in accounts])
            msg("[i] Đã lưu link cho appStorage.", "ok")
    wait_back_menu()

# /8: xem danh sách
def show_saved():
    print("--- Account.txt ---")
    for a in load_accounts():
        print(a)
    print("--- Private_Link.txt ---")
    for l in load_server_links():
        print(l)
    wait_back_menu()

# /9: Tối ưu máy và change android 
def optimize_android_menu():
    while True:
        print("\n===== TỐI ƯU MÁY =====")
        print("1. Tất cả")
        print("2. Vô hiệu hóa bloatware")
        print("3. Đổi Android ID")
        print("4. Tắt animations")
        print("5. Quay lại")

        choice = input("Chọn một tùy chọn (1-5): ").strip()

        if choice == "1":
            if input("Bạn có chắc muốn chạy TẤT CẢ? (y/n): ").lower() == "y":
                disable_bloatware_apps()
                set_android_id()
                disable_animations()
                print(Fore.LIGHTGREEN_EX + "[✓] Tối ưu Android hoàn tất.")
        elif choice == "2":
            if input("Bạn có chắc muốn vô hiệu hóa bloatware? (y/n): ").lower() == "y":
                disable_bloatware_apps()
        elif choice == "3":
            set_android_id()
        elif choice == "4":
            disable_animations()
        elif choice == "5":
            print("Quay lại menu chính...")
            wait_back_menu()
            break
        else:
            print(Fore.LIGHTYELLOW_EX + "⚠ Lựa chọn không hợp lệ, vui lòng nhập 1-5.")

# ============ Menu ============
def menu():
    while True:
        print("""
======== MENU ========
1 Auto rejoin
2 User ID
3 Thiết lập chung 1 ID Game/Link server
4 Gán ID Game/Link riêng cho từng pack
5 Xóa User ID hoặc Link server
6 Thiết lập webhook Discord
7 Tự động tìm User ID từ appStorage.json
8 Xem danh sách đã lưu
9 Tối ưu máy
10 Thoát tool
======================
""")
        choice = input("Chọn: ").strip()
        if choice == "1":
            auto_rejoin()
        elif choice == "2":
            user_id_menu()
        elif choice == "3":
            set_common_link()
        elif choice == "4":
            set_package_link()
        elif choice == "5":
            delete_entry()
        elif choice == "6":
            set_webhook_menu()
        elif choice == "7":
            find_uid_from_appstorage()
        elif choice == "8":
            show_saved()
        elif choice == "9":
            optimize_android_menu()
        elif choice == "10":
            break
        else:
            msg("[!] Lựa chọn không hợp lệ.", "err")

# ============ Entry ============
if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--auto":
        auto_rejoin()
    else:
        menu()
