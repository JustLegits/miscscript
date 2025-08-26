#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Local Rejoin Tool (no API for rejoin)
-------------------------------------
- Menu: 1–8, 10 (bỏ số 9)
- /1 Auto rejoin: đọc file heartbeat JSON trong thư mục Reconnect
  * Account.txt lưu theo username
  * status == "Online" và timestamp lệch ≤ 60s → online
  * ngược lại → offline → kill Roblox + rejoin + gửi webhook
- /2 Thêm username thủ công
- /3, /4, /6, /8 giữ nguyên
- /5 Xoá: thêm lựa chọn xoá cả username + link
- /7 Tự động tìm UID từ appStorage.json → gọi API Roblox lấy username → ghi vào Account.txt
- Tự động quét /sdcard/Android/data để tìm thư mục Reconnect/
"""

import os, time, json, subprocess, requests, sys

CONFIG_FILE = "config.json"
SERVER_LINKS_FILE = "Private_Link.txt"
ACCOUNTS_FILE = "Account.txt"
WEBHOOK_FILE = "Webhook.txt"

# ============ Các hàm tiện ích ============
def msg(text, type="info"):
    print(text)

def prompt(text):
    return input(text+" ").strip()

def wait_back_menu():
    input("[Nhấn Enter để quay lại menu]")

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
def get_roblox_packages():
    result = subprocess.run(
        "pm list packages | grep 'roblox'",
        shell=True,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return []
    pkgs = []
    for line in result.stdout.splitlines():
        if ":" in line:
            pkgs.append(line.split(":", 1)[1].strip())
    return pkgs

def kill_roblox_process(package):
    subprocess.run(["pkill", "-f", package])
    time.sleep(2)

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
        time.sleep(2.5)
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
            if "Reconnect" in dirs:
                results.append(os.path.join(root, "Reconnect"))
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
def set_webhook(url):
    open(WEBHOOK_FILE,"w",encoding="utf-8").write(url.strip())

def get_webhook():
    if not os.path.exists(WEBHOOK_FILE):
        return ""
    return open(WEBHOOK_FILE,"r",encoding="utf-8").read().strip()

def send_webhook(msgtxt):
    url = get_webhook()
    if not url: return
    try:
        requests.post(url, json={"content": msgtxt}, timeout=5)
    except: pass

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
                time.sleep(3)
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
    set_webhook(url)
    msg("[i] Đã lưu webhook.", "ok")
    wait_back_menu()

# /7: dùng UID từ appStorage.json → API lấy username
def find_uid_from_appstorage():
    pkgs = get_roblox_packages()
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
