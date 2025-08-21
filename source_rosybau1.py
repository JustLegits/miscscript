# -*- coding: utf-8 -*-
import os
import requests
import json
import time
import subprocess
import asyncio
import aiohttp
import threading
import psutil
import uuid
import hashlib
import xml.etree.ElementTree as ET
import random
from colorama import init, Fore, Style
from PIL import ImageGrab  # Pillow, dùng cho screenshot

init(autoreset=True)

SERVER_LINKS_FILE = "Private_Link.txt"
ACCOUNTS_FILE = "Account.txt"
CONFIG_FILE = "Config.json"

# ------------- Language -------------
LANGS = {
    "vi": {
        "menu_title": "",
        "menu": [
            "/1 Auto rejoin",
            "/2 User ID",
            "/3 Thiết lập chung 1 ID Game/Link server",
            "/4 Gán ID Game/Link riêng cho từng pack",
            "/5 Xóa User ID hoặc Link server",
            "/6 Thiết lập webhook Discord",
            "/7 Tự động tìm User ID từ appStorage.json",
            "/8 Xem danh sách đã lưu",
            "/9 Same hardware id + Bypass key",
            "/10 Thoát tool"
        ],
        "input_choice": "Nhập lựa chọn (1-10):",
        "no_account_link": "Chưa có User ID hoặc link Server! Thiết lập trước.",
        "starting_roblox": "Đang khởi động Roblox...",
        "auto_running": "Auto rejoin đang chạy. Dừng bằng Ctrl+C!",
        "stop_auto": "Dừng auto rejoin.",
        "enter_uid": "Nhập User ID hoặc Username cho {package}:",
        "getting_uid": "Đang lấy User ID cho {name}...",
        "cant_get_uid": "Không lấy được User ID! Nhập tay:",
        "assign_uid": "Gán {package} cho User ID {uid}",
        "saved_uid": "Đã lưu User ID!",
        "enter_link": "Nhập ID Game hoặc Link Server:",
        "saved_link": "Đã lưu link server!",
        "enter_link_each": "Nhập ID Game/Link server cho {package}:",
        "saved_each_link": "Đã lưu từng link server!",
        "delete_what": "Xóa gì? [1]UserID [2]Link [3]Cả 2 :",
        "deleted_uid": "Đã xóa User ID.",
        "deleted_link": "Đã xóa Link Server.",
        "deleted_both": "Đã xóa cả User ID và Link Server.",
        "invalid_or_not_exist": "Không hợp lệ hoặc file không tồn tại.",
        "enter_webhook": "Nhập webhook Discord:",
        "enter_device": "Nhập tên thiết bị:",
        "enter_interval": "Phút giữa mỗi lần gửi thông tin lên webhook:",
        "must_int": "Nhập số nguyên!",
        "saved_webhook": "Đã lưu webhook config!",
        "not_found_uid": "Không tìm được User ID cho {pkg}",
        "found_uid": "{pkg}: {uid}",
        "saved_uid_appstorage": "Đã lưu User ID từ appStorage.json",
        "enter_link_appstorage": "Nhập ID Game/Link Server:",
        "saved_link_appstorage": "Đã lưu link server!",
        "saved_accounts": "Danh sách tài khoản Roblox đã lưu:",
        "bye": "Tạm biệt!",
        "invalid_choice": "Lựa chọn không hợp lệ!",
        "playing": "Đang chơi",
        "lobby": "Trong sảnh",
        "offline": "Offline",
        "unknown": "?",
        "fluxus_bypass": "Fluxus Bypass: {bypass_status}",
        "rejoin_out": "{username} ({uid}) đã out. Đang rejoin...",
        "rejoin_in": "{username} ({uid}) vẫn đang chơi.",
        "send_webhook_ok": "Đã gửi thông tin thiết bị lên webhook!",
        "send_webhook_err": "Lỗi gửi webhook!",
        "roblox_launch_err": "Lỗi mở Roblox cho {package}: {e}",
        "invalid_link": "Link không hợp lệ!",
        "bypass_done": "Đã thực hiện samehwid + bypass key codeX!",
        "androidid_fail": "Không thể đổi Android ID!",
    },
    "en": {
        "menu_title": "",
        "menu": [
            "/1 Auto rejoin Roblox game",
            "/2 Set User ID for each package",
            "/3 Set a single Game ID/Server Link for all",
            "/4 Assign Game ID/Server Link for each package",
            "/5 Delete User ID or Server Link",
            "/6 Configure Discord webhook",
            "/7 Auto-detect User ID from appStorage.json",
            "/8 View saved accounts and links",
            "/9 Same hardware id + Bypass key",
            "/10 Exit tool"
        ],
        "input_choice": "Enter your choice (1-10):",
        "no_account_link": "No User ID or Server Link found! Please set up first.",
        "starting_roblox": "Starting Roblox...",
        "auto_running": "Auto rejoin is running. Stop with Ctrl+C!",
        "stop_auto": "Stopped auto rejoin.",
        "enter_uid": "Enter User ID or Username for {package}:",
        "getting_uid": "Getting User ID for {name}...",
        "cant_get_uid": "Could not get User ID! Enter manually:",
        "assign_uid": "Assigned {package} to User ID {uid}",
        "saved_uid": "User ID saved!",
        "enter_link": "Enter Game ID or Server Link:",
        "saved_link": "Server link saved!",
        "enter_link_each": "Enter Game ID/Server Link for {package}:",
        "saved_each_link": "Saved each server link!",
        "delete_what": "Delete what? [1]UserID [2]Link [3]Both :",
        "deleted_uid": "User ID deleted.",
        "deleted_link": "Server Link deleted.",
        "deleted_both": "Both User ID and Server Link deleted.",
        "invalid_or_not_exist": "Invalid or file does not exist.",
        "enter_webhook": "Enter Discord webhook:",
        "enter_device": "Enter device name:",
        "enter_interval": "Minutes between each webhook info send:",
        "must_int": "Enter an integer!",
        "saved_webhook": "Webhook config saved!",
        "not_found_uid": "Could not find User ID for {pkg}",
        "found_uid": "{pkg}: {uid}",
        "saved_uid_appstorage": "User ID from appStorage.json saved",
        "enter_link_appstorage": "Enter Game ID/Server Link:",
        "saved_link_appstorage": "Server link saved!",
        "saved_accounts": "Saved Roblox accounts:",
        "bye": "Goodbye!",
        "invalid_choice": "Invalid choice!",
        "playing": "Playing",
        "lobby": "In lobby",
        "offline": "Offline",
        "unknown": "?",
        "fluxus_bypass": "beta Bypass: {bypass_status}",
        "rejoin_out": "{username} ({uid}) is out. Rejoining...",
        "rejoin_in": "{username} ({uid}) is still playing.",
        "send_webhook_ok": "Device info sent to webhook!",
        "send_webhook_err": "Failed to send webhook!",
        "roblox_launch_err": "Failed to launch Roblox for {package}: {e}",
        "invalid_link": "Invalid link!",
        "bypass_done": "Done samehwid + bypass key codeX!",
        "androidid_fail": "Failed to change Android ID!",
    }
}

LANG = LANGS["vi"]  # default

def select_language():
    global LANG
    print(Fore.LIGHTYELLOW_EX + "Select language :")
    print("1. Vietnamese")
    print("2. English")
    lang_choice = input("Choice : ").strip()
    if lang_choice == "2":
        LANG = LANGS["en"]
    else:
        LANG = LANGS["vi"]

# ------------- UI Helper -------------
def clear():
    import os
    # Xóa sạch màn hình, không in lại gì cả
    os.system('cls' if os.name == 'nt' else 'clear')

def banner():
    clear()
    print(Fore.LIGHTMAGENTA_EX + r"""
  ____                 _       __  __                                   
 |  _ \ ___  ___ _   _| |__   |  \/  | __ _ _ __   __ _  __ _  ___ _ __ 
 | |_) / _ \/ __| | | | '_ \  | |\/| |/ _` | '_ \ / _` |/ _` |/ _ \ '__|
 |  _ < (_) \__ \ |_| | |_) | | |  | | (_| | | | | (_| | (_| |  __/ |   
 |_| \_\___/|___/\__, |_.__/  |_|  |_|\__,_|_| |_|\__,_|\__, |\___|_|   
                 |___/                                  |___/                                                                                        
""" + Style.RESET_ALL)
    show_sysinfo()
    print(Fore.LIGHTMAGENTA_EX + "" + Fore.LIGHTCYAN_EX + " discord.gg/KmFM6DyvPB        " + Fore.LIGHTMAGENTA_EX + "")
    print(Fore.LIGHTMAGENTA_EX + "" + Fore.LIGHTCYAN_EX + " Made by : th4t9ng - Rosyb Manager                       " + Fore.LIGHTMAGENTA_EX + "" + Style.RESET_ALL)
    print()

def show_sysinfo():
    cpu = psutil.cpu_percent(interval=0.5)
    ram = psutil.virtual_memory().percent
    disk = psutil.disk_usage('/').percent
    print(
        f"{Fore.LIGHTYELLOW_EX}CPU: {cpu:.1f}% | RAM: {ram:.1f}% | Disk: {disk:.1f}%{Style.RESET_ALL}"
    )

def divider():
    print(Fore.LIGHTBLACK_EX + "─" * 55 + Style.RESET_ALL)

def menu():
    menu_title = LANG.get("menu_title", "")
    print(Fore.LIGHTGREEN_EX + menu_title + Style.RESET_ALL)
    print(Fore.LIGHTBLUE_EX + "+----+-----------------------------------------------+" + Style.RESET_ALL)
    print(Fore.LIGHTBLUE_EX + "| No | Service Name                                 |" + Style.RESET_ALL)
    print(Fore.LIGHTBLUE_EX + "+----+-----------------------------------------------+" + Style.RESET_ALL)
    for idx, item in enumerate(LANG["menu"], 1):
        name = item
        if "/" in name:
            name = name.split(" ", 1)[-1]
        if len(name) > 45:
            name = name[:42] + '...'
        print(f"| {str(idx).ljust(2)} | {name.ljust(45)}|")
    print(Fore.LIGHTBLUE_EX + "+----+-----------------------------------------------+" + Style.RESET_ALL)
    divider()

def msg(txt, type="info"):
    if type == "info":
        print(Fore.LIGHTCYAN_EX + "[i]" + Style.RESET_ALL, txt)
    elif type == "ok":
        print(Fore.LIGHTGREEN_EX + "[✓]" + Style.RESET_ALL, txt)
    elif type == "err":
        print(Fore.LIGHTRED_EX + "[!]" + Style.RESET_ALL, txt)
    elif type == "warn":
        print(Fore.LIGHTYELLOW_EX + "[*]" + Style.RESET_ALL, txt)
    elif type == "input":
        print(Fore.LIGHTMAGENTA_EX + "[?]" + Style.RESET_ALL, txt, end=' ')
    else:
        print(txt)

def status_table(accounts, bypass_status):
    divider()
    print(f"{Fore.LIGHTBLUE_EX}{'Gói' if LANG==LANGS['vi'] else 'Package':<18} {'User':<18} {'Trạng thái' if LANG==LANGS['vi'] else 'Status':<12}{Style.RESET_ALL}")
    divider()
    for package, uid in accounts:
        username = get_username(uid) or uid
        ptype = check_user_online(uid)
        if ptype == 2:
            status = Fore.LIGHTGREEN_EX + LANG["playing"]
        elif ptype == 1:
            status = Fore.LIGHTYELLOW_EX + LANG["lobby"]
        elif ptype == 0:
            status = Fore.LIGHTRED_EX + LANG["offline"]
        else:
            status = Fore.LIGHTBLACK_EX + LANG["unknown"]
        print(f"{Fore.LIGHTCYAN_EX}{package:<18}{Style.RESET_ALL} {username:<18} {status + Style.RESET_ALL:<12}")
    divider()
    print(Fore.LIGHTMAGENTA_EX + LANG["fluxus_bypass"].format(bypass_status=bypass_status) + Style.RESET_ALL)
    divider()

def prompt(txt):
    msg(txt, "input")
    return input()

def wait_back_menu():
    input('\nPress Enter to back to menu...')

# ------------- CONFIG -------------
def load_config():
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, "r") as f:
            cfg = json.load(f)
            return cfg.get("webhook_url"), cfg.get("device_name"), cfg.get("interval")
    return None, None, None

def save_config(webhook_url, device_name, interval):
    with open(CONFIG_FILE, "w") as f:
        json.dump({"webhook_url": webhook_url, "device_name": device_name, "interval": interval}, f)

# ------------- File IO -------------
def save_server_links(server_links):
    with open(SERVER_LINKS_FILE, "w") as f:
        for package, link in server_links:
            f.write(f"{package},{link}\n")

def load_server_links():
    if not os.path.exists(SERVER_LINKS_FILE): return []
    with open(SERVER_LINKS_FILE, "r") as f:
        return [tuple(line.strip().split(",", 1)) for line in f]

def save_accounts(accounts):
    with open(ACCOUNTS_FILE, "w") as f:
        for package, uid in accounts:
            f.write(f"{package},{uid}\n")

def load_accounts():
    if not os.path.exists(ACCOUNTS_FILE): return []
    with open(ACCOUNTS_FILE, "r") as f:
        return [tuple(line.strip().split(",", 1)) for line in f]

def find_userid_from_file(file_path):
    try:
        with open(file_path, 'r') as f:
            c = f.read()
            s = c.find('"UserId":"')
            if s == -1: return None
            s += len('"UserId":"')
            e = c.find('"', s)
            return c[s:e]
    except: return None

# ------------- Roblox -------------
def get_roblox_packages():
    result = subprocess.run("pm list packages | grep 'roblox'", shell=True, capture_output=True, text=True)
    if result.returncode == 0:
        return [line.split(":")[1] for line in result.stdout.splitlines()]
    return []

async def get_user_id(username):
    url = "https://users.roblox.com/v1/usernames/users"
    payload = {"usernames": [username], "excludeBannedUsers": True}
    headers = {"Content-Type": "application/json"}
    async with aiohttp.ClientSession() as session:
        async with session.post(url, json=payload, headers=headers) as response:
            data = await response.json()
            if 'data' in data and len(data['data']) > 0:
                return str(data['data'][0]['id'])
    return None

def get_username(user_id):
    try:
        url = f"https://users.roblox.com/v1/users/{user_id}"
        r = requests.get(url, timeout=3)
        r.raise_for_status()
        data = r.json()
        return data.get("name", "Không rõ" if LANG==LANGS["vi"] else "Unknown")
    except:
        return None

def check_user_online(user_id):
    try:
        url = "https://presence.roblox.com/v1/presence/users"
        headers = {'Content-Type': 'application/json'}
        body = json.dumps({"userIds": [int(user_id)]})
        r = requests.post(url, headers=headers, data=body, timeout=3)
        r.raise_for_status()
        data = r.json()
        return data["userPresences"][0]["userPresenceType"]
    except:
        return None

def kill_roblox_processes():
    for package in get_roblox_packages():
        os.system(f"pkill -f {package}")
    time.sleep(2)

def kill_roblox_process(package):
    os.system(f"pkill -f {package}")
    time.sleep(2)

def launch_roblox(package, server_link):
    try:
        subprocess.run(['am', 'start', '-n', f'{package}/com.roblox.client.startup.ActivitySplash', '-d', server_link], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(3)
        subprocess.run(['am', 'start', '-n', f'{package}/com.roblox.client.ActivityProtocolLaunch', '-d', server_link], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(3)
    except Exception as e:
        msg(LANG["roblox_launch_err"].format(package=package, e=e), "err")

def format_server_link(input_link):
    if 'roblox.com' in input_link:
        return input_link
    elif input_link.isdigit():
        return f'roblox://placeID={input_link}'
    else:
        msg(LANG["invalid_link"], "err")
        return None

# ------------- Screenshot & Webhook -------------
def take_screenshot(filename="screenshot.png"):
    try:
        img = ImageGrab.grab()
        img.save(filename)
        return filename
    except Exception as e:
        return None

def send_webhook_with_screenshot(webhook_url, device_name):
    sysinfo = get_system_info()
    embed = {
        "title": f"{'Thông tin hệ thống' if LANG==LANGS['vi'] else 'System info'} {device_name}",
        "color": 15258703,
        "fields": [
            {"name": "Tên thiết bị" if LANG==LANGS["vi"] else "Device name", "value": device_name, "inline": True},
            {"name": "CPU", "value": f"{sysinfo['cpu_usage']}%", "inline": True},
            {"name": "RAM đã dùng" if LANG==LANGS["vi"] else "RAM used", "value": f"{sysinfo['memory_used']/sysinfo['memory_total']*100:.2f}%", "inline": True},
            {"name": "RAM trống" if LANG==LANGS["vi"] else "RAM free", "value": f"{sysinfo['memory_available']/sysinfo['memory_total']*100:.2f}%", "inline": True},
            {"name": "Tổng RAM" if LANG==LANGS["vi"] else "Total RAM", "value": f"{sysinfo['memory_total'] / (1024 ** 3):.2f} GB", "inline": True},
            {"name": "Uptime", "value": f"{sysinfo['uptime']/3600:.2f} {'giờ' if LANG==LANGS['vi'] else 'hours'}", "inline": True}
        ]
    }
    screenshot_file = take_screenshot()
    files = {}
    if screenshot_file and os.path.exists(screenshot_file):
        files = {'file': open(screenshot_file, 'rb')}
    payload = {"embeds": [embed], "username": device_name}
    try:
        if files:
            response = requests.post(webhook_url, data={"payload_json": json.dumps(payload)}, files=files, timeout=10)
            files['file'].close()
            os.remove(screenshot_file)
        else:
            response = requests.post(webhook_url, json=payload, timeout=10)
        if response.status_code == 204 or response.status_code == 200:
            msg(LANG["send_webhook_ok"], "ok")
        else:
            msg(LANG["send_webhook_err"], "err")
    except Exception:
        msg(LANG["send_webhook_err"], "err")

def get_system_info():
    cpu_usage = psutil.cpu_percent(interval=1)
    memory_info = psutil.virtual_memory()
    uptime = time.time() - psutil.boot_time()
    return {
        "cpu_usage": cpu_usage,
        "memory_total": memory_info.total,
        "memory_available": memory_info.available,
        "memory_used": memory_info.used,
        "uptime": uptime
    }

def webhook_loop(webhook_url, device_name, interval, stop_event):
    while not stop_event.is_set():
        send_webhook_with_screenshot(webhook_url, device_name)
        stop_event.wait(interval*60)

# ------------- Android ID changer -------------
def change_android_id_fixed():
    xml_path = "/data/system/users/0/settings_ssaid.xml"
    fixed_id = "9c47a1f3b6e8d2c5"
    try:
        tree = ET.parse(xml_path)
        root = tree.getroot()
        changed = False
        for setting in root.findall("setting"):
            if setting.attrib.get("id") == "android_id":
                setting.set("value", fixed_id)
                changed = True
        if not changed:
            ET.SubElement(root, "setting", id="android_id", value=fixed_id)
        tree.write(xml_path)
        os.system(f"chmod 600 {xml_path}")
        # Nếu muốn tự động reboot máy ảo sau khi đổi, bỏ comment dòng dưới:
        # os.system("reboot")
        return True
    except Exception as e:
        msg(LANG["androidid_fail"], "err")
        return False

def robust_check_user_online(user_id, prev_status=None, retries=2, delay=2):
    """
    Retry presence check if status is 'lobby' and previous status was 'playing'.
    """
    status = check_user_online(user_id)
    if status == 1 and prev_status == 2:
        # If previously playing, but now lobby, retry a few times
        for _ in range(retries):
            time.sleep(delay)
            status = check_user_online(user_id)
            if status == 2:
                break
    return status

# ------------- MAIN -------------
def main():
    select_language()
    stop_event = threading.Event()
    webhook_thread = None
    banner()
    webhook_url, device_name, interval = load_config()
    bypass_status = "Chưa sử dụng" if LANG==LANGS["vi"] else "Not used"

    while True:
        clear()  # Xóa sạch màn hình trước khi in menu
        banner() # In lại banner ở trên cùng
        menu()
        choice = prompt(LANG["input_choice"]).strip()
        if choice == "1":
            accounts = load_accounts()
            server_links = load_server_links()
            if not accounts or not server_links:
                msg(LANG["no_account_link"], "err")
                continue
            if webhook_url and device_name and interval and (webhook_thread is None or not webhook_thread.is_alive()):
                stop_event.clear()
                webhook_thread = threading.Thread(target=webhook_loop, args=(webhook_url, device_name, interval, stop_event))
                webhook_thread.daemon = True
                webhook_thread.start()
            msg(LANG["starting_roblox"], "info")
            kill_roblox_processes()
            time.sleep(2)
            for package, server_link in server_links:
                launch_roblox(package, server_link)
            msg(LANG["auto_running"], "ok")
            try:
                status_cache = {}  # Add this line to cache previous statuses
                while True:
                    for package, uid in accounts:
                        username = get_username(uid) or uid
                        prev_status = status_cache.get(uid)
                        status = robust_check_user_online(uid, prev_status)
                        status_cache[uid] = status
                        if status == 2:
                            msg(LANG["rejoin_in"].format(username=username, uid=uid), "ok")
                        else:
                            msg(LANG["rejoin_out"].format(username=username, uid=uid), "warn")
                            kill_roblox_process(package)
                            link = dict(server_links).get(package, "")
                            launch_roblox(package, link)
                        time.sleep(3)
                    status_table(accounts, bypass_status)
                    time.sleep(30)
            except KeyboardInterrupt:
                msg(LANG["stop_auto"], "warn")
        elif choice == "2":
            accounts = []
            for package in get_roblox_packages():
                name = prompt(LANG["enter_uid"].format(package=package)).strip()
                uid = name
                if not name.isdigit():
                    msg(LANG["getting_uid"].format(name=name), "info")
                    uid2 = asyncio.run(get_user_id(name))
                    if uid2: uid = uid2
                    else: uid = prompt(LANG["cant_get_uid"]).strip()
                accounts.append((package, uid))
                msg(LANG["assign_uid"].format(package=package, uid=uid), "ok")
            save_accounts(accounts)
            msg(LANG["saved_uid"], "ok")
            wait_back_menu()
        elif choice == "3":
            link = prompt(LANG["enter_link"]).strip()
            formatted = format_server_link(link)
            if formatted:
                pkgs = get_roblox_packages()
                save_server_links([(p, formatted) for p in pkgs])
                msg(LANG["saved_link"], "ok")
            wait_back_menu()
        elif choice == "4":
            links = []
            for package in get_roblox_packages():
                link = prompt(LANG["enter_link_each"].format(package=package)).strip()
                formatted = format_server_link(link)
                if formatted: links.append((package, formatted))
            save_server_links(links)
            msg(LANG["saved_each_link"], "ok")
            wait_back_menu()
        elif choice == "5":
            c = prompt(LANG["delete_what"]).strip()
            if c == "1" and os.path.exists(ACCOUNTS_FILE):
                os.remove(ACCOUNTS_FILE)
                msg(LANG["deleted_uid"], "ok")
            elif c == "2" and os.path.exists(SERVER_LINKS_FILE):
                os.remove(SERVER_LINKS_FILE)
                msg(LANG["deleted_link"], "ok")
            elif c == "3":
                if os.path.exists(ACCOUNTS_FILE): os.remove(ACCOUNTS_FILE)
                if os.path.exists(SERVER_LINKS_FILE): os.remove(SERVER_LINKS_FILE)
                msg(LANG["deleted_both"], "ok")
            else:
                msg(LANG["invalid_or_not_exist"], "err")
            wait_back_menu()
        elif choice == "6":
            webhook_url = prompt(LANG["enter_webhook"])
            device_name = prompt(LANG["enter_device"])
            try:
                interval = int(prompt(LANG["enter_interval"]))
            except:
                msg(LANG["must_int"], "err"); continue
            save_config(webhook_url, device_name, interval)
            msg(LANG["saved_webhook"], "ok")
            wait_back_menu()
        elif choice == "7":
            pkgs = get_roblox_packages()
            accounts = []
            for pkg in pkgs:
                fpath = f'/data/data/{pkg}/files/appData/LocalStorage/appStorage.json'
                uid = find_userid_from_file(fpath)
                if uid:
                    accounts.append((pkg, uid))
                    msg(LANG["found_uid"].format(pkg=pkg, uid=uid), "ok")
                else:
                    msg(LANG["not_found_uid"].format(pkg=pkg), "err")
            save_accounts(accounts)
            msg(LANG["saved_uid_appstorage"], "ok")
            link = prompt(LANG["enter_link_appstorage"])
            formatted = format_server_link(link)
            if formatted:
                save_server_links([(pkg, formatted) for pkg in pkgs])
                msg(LANG["saved_link_appstorage"], "ok")
            wait_back_menu()
        elif choice == "8":
            accounts = load_accounts()
            links = load_server_links()
            print(Fore.LIGHTCYAN_EX + LANG["saved_accounts"] + Style.RESET_ALL)
            for (pkg, uid), (_, link) in zip(accounts, links):
                username = get_username(uid) or uid
                print(f"{pkg:<18} {username:<15} {uid:<15} {link}")
            divider()
            wait_back_menu()
        elif choice == "9":
            ok = change_android_id_fixed()
            if ok:
                msg(LANG["bypass_done"], "ok")
            else:
                msg(LANG["androidid_fail"], "err")
            wait_back_menu()
        elif choice == "10":
            if webhook_thread and webhook_thread.is_alive():
                stop_event.set()
            msg(LANG["bye"], "info")
            break
        else:
            msg(LANG["invalid_choice"], "err")

if __name__ == "__main__":
    main()
