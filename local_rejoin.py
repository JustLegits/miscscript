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

def clear():
    os.system("clear" if os.name == "posix" else "cls")

def wait_back_menu():
    input("[Nhấn Enter để quay lại menu]")
    os.system("clear")
 
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
    keywords = ["roblox", "bduy", "mangcut", "concacug","codex","delta","arceus","ugpornkiki"]

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
        subprocess.run(["pkill", "-f", package], check=False)
        print(f"[✓] Đã kill {package}")
    except Exception as e:
        print(f"[!] Lỗi khi kill {package}: {e}")
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
        time.sleep(2)
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
            with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except:
            pass
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

def find_autoexecute_dirs(bases=None):
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
            # Nếu có thư mục "Autoexecute" hoặc "Autoexe"
            for dirname in ["Autoexecute", "Autoexec"]:
                if dirname in dirs:
                    results.append(os.path.join(root, dirname))
    return results

# ============ Heartbeat ============
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

        if status.lower() != "online":
            return (False, age, user, "Status khác 'online'")
        if abs(age) > 60:
            return (False, age, user, f"Heartbeat quá cũ ({age:.0f}s)")
        return (True, age, user, "OK")
    except Exception as e:
        return (False, 1e9, "", f"Lỗi đọc JSON: {e}")

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
# /1: Auto Rejoin
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
            clear()
            msg("[i] Bắt đầu vòng check mới...", "info")
            for pkg, username in accounts:
                hb_file = os.path.join(reconnect_dir, f"reconnect_status_{username}.json")
                online, age, uname, reason = read_heartbeat(hb_file)
                if online:
                    msg(f"[✓] {username} online (age={age:.0f}s)", "ok")
                else:
                    msg(f"[*] {username} OFFLINE → {reason} → rejoin {pkg}", "err")
                    kill_roblox_process(pkg)
                    link = links.get(pkg, "")
                    launch_roblox(pkg, link)
                    send_webhook(f"{username} OFFLINE ({reason}) → rejoined {pkg}")
                time.sleep(5)
            time.sleep(200)
    except KeyboardInterrupt:
        msg("[i] Dừng auto rejoin.")

# /2: thêm username thủ công (auto detect package)
def user_id_menu():
    accounts = load_accounts()
    pkgs = get_custom_packages()
    if not pkgs:
        msg("[!] Không tìm thấy package Roblox nào.", "err")
        wait_back_menu()
        return

    if len(pkgs) == 1:
        pkg = pkgs[0]
        print(Fore.LIGHTGREEN_EX + f"Tự động phát hiện package: {pkg}")
    else:
        print("Tìm thấy nhiều package Roblox:")
        for i, p in enumerate(pkgs):
            print(f"{i+1}. {p}")
        idx = int(input("Chọn số: ")) - 1
        pkg = pkgs[idx]

    username = prompt("Nhập username:")
    accounts.append((pkg, username))
    save_accounts(accounts)
    msg(f"[i] Đã lưu Username cho package {pkg}.", "ok")
    wait_back_menu()


# /3: thiết lập link chung (auto detect packages)
def set_common_link():
    pkgs = get_custom_packages()
    if not pkgs:
        msg("[!] Không tìm thấy package Roblox nào.", "err")
        wait_back_menu()
        return

    link = prompt("Nhập ID Game/Link server chung:")
    formatted = format_server_link(link)
    if not formatted:
        msg("[!] Link không hợp lệ.", "err")
        wait_back_menu()
        return

    save_server_links([(pkg, formatted) for pkg in pkgs])
    msg(f"[i] Đã lưu link chung cho {len(pkgs)} package.", "ok")
    wait_back_menu()


# /4: gán link riêng (chọn package từ danh sách detect)
def set_package_link():
    pkgs = get_custom_packages()
    if not pkgs:
        msg("[!] Không tìm thấy package Roblox nào.", "err")
        wait_back_menu()
        return

    print("Danh sách package Roblox:")
    for i, p in enumerate(pkgs):
        print(f"{i+1}. {p}")
    idx = int(input("Chọn số package để gán link: ")) - 1
    pkg = pkgs[idx]

    link = prompt(f"Nhập link cho package {pkg}:")
    formatted = format_server_link(link)
    if not formatted:
        msg("[!] Link không hợp lệ.", "err")
        wait_back_menu()
        return

    links = load_server_links()
    links = [(p, l) for p, l in links if p != pkg]  # xóa link cũ của pkg
    links.append((pkg, formatted))
    save_server_links(links)
    msg(f"[i] Đã lưu link riêng cho {pkg}.", "ok")
    wait_back_menu()

# /5: xoá
def delete_entry():
    t = prompt("Xóa (1=User file, 2=Server link file, 3=Cả hai):")
    if t == "1":
        if os.path.exists(ACCOUNTS_FILE):
            os.remove(ACCOUNTS_FILE)
            msg("[i] Đã xóa toàn bộ Account.txt.", "ok")
        else:
            msg("[!] Account.txt không tồn tại.", "err")
    elif t == "2":
        if os.path.exists(SERVER_LINKS_FILE):
            os.remove(SERVER_LINKS_FILE)
            msg("[i] Đã xóa toàn bộ Private_Link.txt.", "ok")
        else:
            msg("[!] Private_Link.txt không tồn tại.", "err")
    elif t == "3":
        if os.path.exists(ACCOUNTS_FILE):
            os.remove(ACCOUNTS_FILE)
            msg("[i] Đã xóa toàn bộ Account.txt.", "ok")
        else:
            msg("[!] Account.txt không tồn tại.", "err")
        if os.path.exists(SERVER_LINKS_FILE):
            os.remove(SERVER_LINKS_FILE)
            msg("[i] Đã xóa toàn bộ Private_Link.txt.", "ok")
        else:
            msg("[!] Private_Link.txt không tồn tại.", "err")
    else:
        msg("[!] Lựa chọn không hợp lệ.", "err")
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
            with open(fpath, "r", encoding="utf-8") as f:
                data = json.load(f)
            uid = str(data.get("UserId", ""))
        except:
            uid = ""

        username = ""
        if uid:
            try:
                r = requests.get(f"https://users.roblox.com/v1/users/{uid}", timeout=5)
                if r.status_code == 200:
                    username = r.json().get("name", "")
            except:
                pass

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
            save_server_links([(pkg, formatted) for pkg, _ in accounts])
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

# /10: Thêm script vào autoexecute folder
def add_autoexecute_script():
    dirs = find_autoexecute_dirs()
    auto_dir = None

    if not dirs:
        print(Fore.LIGHTRED_EX + "Không tìm thấy thư mục Autoexecute. Hãy kiểm tra lại!")
        return
    elif len(dirs) == 1:
        auto_dir = dirs[0]
    else:
        print("Tìm thấy nhiều thư mục Autoexecute:")
        for i, d in enumerate(dirs):
            print(f"{i+1}. {d}")
        idx = int(input("Chọn số: ")) - 1
        auto_dir = dirs[idx]

    print("""
Chọn loại script:
1. Script Check Online (tạo file checkonline.lua)
2. Tự nhập script thủ công (autoexecuteN.lua)
    """)
    choice = input("Nhập lựa chọn: ").strip()

    if choice == "1":
        filename = os.path.join(auto_dir, "checkonline.lua")
        script_content = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/JustLegits/miscscript/main/checkonline.lua"))()'
    elif choice == "2":
        # Tìm số tiếp theo cho file autoexecuteN.lua
        existing = [f for f in os.listdir(auto_dir) if f.startswith("autoexecute") and f.endswith(".lua")]
        nums = []
        for f in existing:
            try:
                n = int(f.replace("autoexecute", "").replace(".lua", ""))
                nums.append(n)
            except:
                pass
        next_num = max(nums) + 1 if nums else 1
        filename = os.path.join(auto_dir, f"autoexecute{next_num}.lua")

        print(Fore.LIGHTBLUE_EX + f"Nhập script của bạn (gõ 'end' trên 1 dòng để kết thúc):")
        lines = []
        while True:
            line = input()
            if line.strip().lower() == "end":
                break
            lines.append(line)
        script_content = "\n".join(lines)
    else:
        print(Fore.LIGHTRED_EX + "Lựa chọn không hợp lệ.")
        return

    with open(filename, "w", encoding="utf-8") as f:
        f.write(script_content + "\n")

    print(Fore.LIGHTGREEN_EX + f"Đã lưu script vào {filename}")
    wait_back_menu()

# /11: Export, Import Config
# import pyperclip  # pip install pyperclip <-- Không cần thiết cho chức năng này nữa

def export_import_config():
    print("\n===== EXPORT / IMPORT CONFIG =====")
    print("1. Export config (ghi ra file + gửi lên webhook)")
    print("2. Import config (nhập JSON, link URL, hoặc file)")
    print("3. Quay lại")
    choice = input("Chọn: ").strip()

    if choice == "1":
        data = {}

        # lấy config.json
        if os.path.exists(CONFIG_FILE):
            try:
                with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                    data["config"] = json.load(f)
            except:
                data["config"] = {}
        else:
            data["config"] = {}

        # lấy Account.txt
        data["accounts"] = load_accounts()

        # lấy Private_Link.txt
        data["links"] = load_server_links()

        # lấy Webhook.txt
        url, uid = get_webhook()
        data["webhook"] = {"url": url, "uid": uid}

        try:
            # Vẫn ghi file local để backup
            json_text = json.dumps(data, ensure_ascii=False)
            with open("localrejoinconfig.json", "w", encoding="utf-8") as f:
                f.write(json_text)
            
            msg("[✓] Đã export config → localrejoinconfig.json", "ok")

            # Gửi file config lên webhook
            if not url:
                msg("[!] Không tìm thấy webhook URL để gửi. Chỉ export ra file.", "err")
            else:
                msg("[i] Đang gửi config backup lên webhook...", "info")
                try:
                    # Gửi file json dưới dạng file đính kèm
                    files = {
                        'file': ('localrejoinconfig.json', json_text, 'application/json')
                    }
                    payload_json = {
                        "content": f"Backup config từ tool localrejoin. User: <@{uid}>" if uid else "Backup config từ tool localrejoin."
                    }
                    r = requests.post(url, files=files, data={"payload_json": json.dumps(payload_json)}, timeout=10)
                    
                    if 200 <= r.status_code < 300:
                        msg("[✓] Đã gửi config backup lên webhook thành công.", "ok")
                    else:
                        msg(f"[!] Gửi webhook thất bại. Status: {r.status_code}, Response: {r.text}", "err")
                except Exception as e:
                    msg(f"[!] Lỗi khi gửi config lên webhook: {e}", "err")

        except Exception as e:
            msg(f"[!] Lỗi export: {e}", "err")

        wait_back_menu()

    elif choice == "2":
        pasted = prompt("Dán JSON, nhập URL, hoặc Enter để đọc file localrejoinconfig.json:")
        data = None
        
        try:
            pasted = pasted.strip()
            if not pasted:
                # 1. Nhấn Enter -> Đọc file local
                with open("localrejoinconfig.json", "r", encoding="utf-8") as f:
                    data = json.load(f)
                msg("[i] Đã đọc config từ localrejoinconfig.json", "info")
            
            elif pasted.startswith("http://") or pasted.startswith("https://"):
                # 2. Nhập URL -> Tải từ link
                try:
                    msg("[i] Đang tải config từ URL...", "info")
                    r = requests.get(pasted, timeout=10)
                    r.raise_for_status()  # Báo lỗi nếu status code không phải 2xx
                    data = r.json()
                    msg("[✓] Tải và phân tích JSON từ URL thành công.", "ok")
                except requests.exceptions.RequestException as req_e:
                    msg(f"[!] Lỗi khi tải URL: {req_e}", "err")
                    wait_back_menu()
                    return
                except json.JSONDecodeError as json_e:
                    msg(f"[!] Nội dung từ URL không phải JSON hợp lệ: {json_e}", "err")
                    wait_back_menu()
                    return
            
            elif pasted.startswith("{") and pasted.endswith("}"):
                # 3. Dán JSON -> Đọc trực tiếp
                data = json.loads(pasted)
                msg("[i] Đã phân tích JSON được dán vào.", "info")
            
            else:
                msg("[!] Đầu vào không hợp lệ. Không phải URL, JSON, hoặc để trống.", "err")
                wait_back_menu()
                return

        except Exception as e:
            msg(f"[!] Lỗi phân tích JSON hoặc đọc file: {e}", "err")
            wait_back_menu()
            return

        if data is None:
            msg("[!] Không thể tải dữ liệu config.", "err")
            wait_back_menu()
            return
            
        try:
            # Ghi config (giữ nguyên logic cũ)
            if "config" in data:
                with open(CONFIG_FILE, "w", encoding="utf-8") as f:
                    json.dump(data["config"], f, indent=2, ensure_ascii=False)

            if "accounts" in data:
                save_accounts(data["accounts"])

            if "links" in data:
                save_server_links(data["links"])

            if "webhook" in data and isinstance(data["webhook"], dict):
                set_webhook(data["webhook"].get("url", ""), data["webhook"].get("uid", ""))

            msg("[✓] Đã import config thành công!", "ok")
        except Exception as e:
            msg(f"[!] Lỗi khi import dữ liệu: {e}", "err")

        wait_back_menu()

    elif choice == "3":
        return
    else:
        msg("[!] Lựa chọn không hợp lệ.", "err")

# /12: Tắt bật auto startup tool
def manage_startup():
    # dùng absolute path vì khi chạy dưới su thì ~ sẽ thành /root
    startup_dir = "/data/data/com.termux/files/home/.termux/boot"
    startup_file = os.path.join(startup_dir, "startup.sh")

    print("\n===== STARTUP AUTO =====")
    print("1. Bật auto start khi khởi động máy")
    print("2. Tắt auto start")
    print("3. Quay lại")
    choice = input("Chọn: ").strip()

    if choice == "1":
        try:
            os.makedirs(startup_dir, exist_ok=True)
            script_content = """#!/data/data/com.termux/files/usr/bin/bash
# đợi 20s cho hệ thống khởi động xong
sleep 20

# chạy local_rejoin.py với quyền root
su -c "export PATH=$PATH:/data/data/com.termux/files/usr/bin && \
       export TERM=xterm-256color && \
       cd /sdcard/Download && \
       python local_rejoin.py --auto" >> ~/local_rejoin.log 2>&1
"""
            with open(startup_file, "w", encoding="utf-8") as f:
                f.write(script_content)

            os.chmod(startup_file, 0o755)
            print(Fore.LIGHTGREEN_EX + f"[✓] Đã bật auto start. File: {startup_file}")
        except Exception as e:
            print(Fore.LIGHTRED_EX + f"[!] Lỗi khi bật startup: {e}")
        wait_back_menu()

    elif choice == "2":
        try:
            if os.path.exists(startup_file):
                os.remove(startup_file)
                print(Fore.LIGHTGREEN_EX + "[✓] Đã tắt auto start.")
            else:
                print(Fore.LIGHTYELLOW_EX + "[i] Startup chưa được bật hoặc file không tồn tại.")
        except Exception as e:
            print(Fore.LIGHTRED_EX + f"[!] Lỗi khi tắt startup: {e}")
        wait_back_menu()

    elif choice == "3":
        return
    else:
        msg("[!] Lựa chọn không hợp lệ.", "err")

# ============ Menu ============
def menu():
    while True:
        clear()
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
9 Tối ưu máy, thay AndroidID, Tắt Animation
10 Thêm script vào Auto Execute
11 Export, Import Config
12 Quản lý Startup Auto
13 Thoát tool
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
            add_autoexecute_script()
        elif choice == "11":
            export_import_config()
        elif choice == "12":
            manage_startup()
        elif choice == "13":
            break
        else:
            msg("[!] Lựa chọn không hợp lệ.", "err")

# ============ Entry ============
if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--auto":
        auto_rejoin()
    else:
        menu()
