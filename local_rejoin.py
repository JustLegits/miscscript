#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import time
import json
import subprocess
import requests
import sys
import argparse
from typing import List, Tuple, Dict, Any, Optional
from colorama import Fore, Style, init

init(autoreset=True)

# Constants
CONFIG_FILE = "config.json"
SERVER_LINKS_FILE = "Private_Link.txt"
ACCOUNTS_FILE = "Account.txt"
WEBHOOK_FILE = "Webhook.txt"
DEFAULT_ANDROID_ID = "b419fa14320149db"

DEFAULT_KEYWORDS = ["roblox", "bduy", "mangcut", "concacug", "codex", "delta", "arceus", "ugpornkiki", "nhat"]
DEFAULT_BLOATWARE = [
    "com.wsh.toolkit", "com.wsh.appstorage", "com.wsh.launcher2",
    "com.og.toolcenter", "com.og.gamecenter",
    "com.wsh.appstore", "com.android.tools",
    "net.sourceforge.opencamera",
    "com.sec.android.gallery3d", "com.miui.gallery", "com.coloros.gallery3d",
    "com.vivo.gallery", "com.motorola.gallery", "com.transsion.gallery",
    "com.sonyericsson.album", "com.lge.gallery", "com.htc.album", "com.huawei.photos",
    "com.android.gallery3d", "com.android.gallery",
    "com.sec.android.app.clockpackage", "com.miui.clock", "com.coloros.alarmclock",
    "com.vivo.alarmclock", "com.motorola.timeweatherwidget",
    "com.huawei.clock", "com.lge.clock", "com.htc.alarmclock",
    "com.android.dreams.basic", "com.android.dreams.phototable",
    "com.android.wallpaperbackup", "com.android.wallpapercropper"
]

class Utils:
    @staticmethod
    def msg(text: str, type: str = "info") -> None:
        if type == "info":
            print(Fore.CYAN + text)
        elif type == "ok":
            print(Fore.GREEN + text)
        elif type == "err":
            print(Fore.RED + text)
        elif type == "warn":
            print(Fore.YELLOW + text)
        else:
            print(text)

    @staticmethod
    def prompt(text: str) -> str:
        return input(text + " ").strip()

    @staticmethod
    def clear() -> None:
        os.system("clear" if os.name == "posix" else "cls")

    @staticmethod
    def wait_back_menu() -> None:
        input("[Nhấn Enter để quay lại menu]")
        Utils.clear()

    @staticmethod
    def run_cmd(cmd: List[str] | str, check_success: bool = True) -> bool | subprocess.CompletedProcess:
        try:
            if isinstance(cmd, str):
                shell = True
            else:
                shell = False

            result = subprocess.run(cmd, capture_output=True, text=True, shell=shell)
            if check_success:
                return result.returncode == 0
            return result
        except Exception as e:
            print(f"Lỗi khi chạy lệnh {cmd}: {e}")
            return False

class ConfigManager:
    @staticmethod
    def load_pairs(path: str) -> List[Tuple[str, str]]:
        if not os.path.exists(path):
            return []
        pairs = []
        try:
            with open(path, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line or "," not in line:
                        continue
                    a, b = line.split(",", 1)
                    pairs.append((a.strip(), b.strip()))
        except Exception as e:
            Utils.msg(f"Error loading {path}: {e}", "err")
        return pairs

    @staticmethod
    def save_pairs(path: str, pairs: List[Tuple[str, str]]) -> None:
        try:
            with open(path, "w", encoding="utf-8") as f:
                for a, b in pairs:
                    f.write(f"{a},{b}\n")
        except Exception as e:
            Utils.msg(f"Error saving {path}: {e}", "err")

    @staticmethod
    def load_accounts() -> List[Tuple[str, str]]:
        return ConfigManager.load_pairs(ACCOUNTS_FILE)

    @staticmethod
    def save_accounts(accs: List[Tuple[str, str]]) -> None:
        ConfigManager.save_pairs(ACCOUNTS_FILE, accs)

    @staticmethod
    def load_server_links() -> List[Tuple[str, str]]:
        return ConfigManager.load_pairs(SERVER_LINKS_FILE)

    @staticmethod
    def save_server_links(links: List[Tuple[str, str]]) -> None:
        ConfigManager.save_pairs(SERVER_LINKS_FILE, links)

    @staticmethod
    def load_config() -> Dict[str, Any]:
        if os.path.exists(CONFIG_FILE):
            try:
                with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception as e:
                Utils.msg(f"Error loading config: {e}", "err")
        return {}

    @staticmethod
    def save_config(cfg: Dict[str, Any]) -> None:
        try:
            with open(CONFIG_FILE, "w", encoding="utf-8") as f:
                json.dump(cfg, f, indent=2)
        except Exception as e:
            Utils.msg(f"Error saving config: {e}", "err")

class RobloxManager:
    @staticmethod
    def get_custom_packages() -> List[str]:
        cfg = ConfigManager.load_config()
        keywords = cfg.get("keywords", DEFAULT_KEYWORDS)

        result = Utils.run_cmd("pm list packages", check_success=False)
        if isinstance(result, bool) and not result:
             return []
        if hasattr(result, 'stdout'):
             stdout = result.stdout
        else:
             return []

        pkgs = []
        for line in stdout.splitlines():
            if ":" not in line:
                continue
            pkg = line.split(":", 1)[1].strip()
            if any(keyword in pkg.lower() for keyword in keywords):
                pkgs.append(pkg)
        return pkgs

    @staticmethod
    def kill_roblox_process(package: str) -> None:
        try:
            subprocess.run(["pkill", "-f", package], check=False)
            print(f"[✓] Đã kill {package}")
        except Exception as e:
            print(f"[!] Lỗi khi kill {package}: {e}")
        time.sleep(2)

    @staticmethod
    def format_server_link(link: str) -> str:
        link = link.strip()
        if not link:
            return ""
        if "roblox.com" in link or link.startswith("roblox://"):
            return link
        if link.isdigit():
            return f"roblox://placeID={link}"
        return ""

    @staticmethod
    def launch_roblox(package: str, server_link: str) -> None:
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
            Utils.msg(f"[!] Lỗi mở Roblox: {e}", "err")

    @staticmethod
    def find_reconnect_dirs(bases: Optional[List[str]] = None) -> List[str]:
        if bases is None:
            bases = ["/sdcard/Android/data", "/storage/emulated/0"]

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

    @staticmethod
    def find_autoexecute_dirs(bases: Optional[List[str]] = None) -> List[str]:
        if bases is None:
            bases = ["/sdcard/Android/data", "/storage/emulated/0"]
        results = []
        for base in bases:
            if not os.path.exists(base):
                continue
            for root, dirs, files in os.walk(base):
                for dirname in ["Autoexecute", "Autoexec"]:
                    if dirname in dirs:
                        results.append(os.path.join(root, dirname))
        return results

    @staticmethod
    def read_heartbeat(path: str) -> Tuple[bool, float, str, str]:
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

class WebhookManager:
    @staticmethod
    def set_webhook(url: str, user_id: str = "") -> None:
        try:
            with open(WEBHOOK_FILE, "w", encoding="utf-8") as f:
                f.write(url.strip() + "\n" + user_id.strip())
        except Exception as e:
             Utils.msg(f"Error saving webhook: {e}", "err")

    @staticmethod
    def get_webhook() -> Tuple[str, str]:
        if not os.path.exists(WEBHOOK_FILE):
            return "", ""
        try:
            lines = open(WEBHOOK_FILE, "r", encoding="utf-8").read().splitlines()
            url = lines[0].strip() if len(lines) > 0 else ""
            uid = lines[1].strip() if len(lines) > 1 else ""
            return url, uid
        except Exception:
            return "", ""

    @staticmethod
    def send_webhook(msgtxt: str) -> None:
        url, uid = WebhookManager.get_webhook()
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

class SystemOptimizer:
    @staticmethod
    def disable_bloatware_apps() -> None:
        print(Fore.LIGHTBLUE_EX + "Đang vô hiệu hóa các ứng dụng không cần thiết (safe list)...")
        cfg = ConfigManager.load_config()
        apps_to_disable = cfg.get("bloatware_apps", DEFAULT_BLOATWARE)

        for package_name in apps_to_disable:
            if Utils.run_cmd(["pm", "disable-user", "--user", "0", package_name], check_success=False):
                print(Fore.LIGHTGREEN_EX + f"Đã vô hiệu hóa: {package_name}")
            else:
                print(Fore.LIGHTYELLOW_EX + f"Bỏ qua hoặc không thể vô hiệu hóa: {package_name}")

    @staticmethod
    def set_android_id() -> bool:
        user_input = input(f"Nhập Android ID mới (Enter để dùng mặc định: {DEFAULT_ANDROID_ID}): ").strip()
        new_id = user_input if user_input else DEFAULT_ANDROID_ID

        print(Fore.LIGHTYELLOW_EX + f"Đang đặt Android ID thành {new_id}...", end=" ")
        if Utils.run_cmd(["settings", "put", "secure", "android_id", new_id], check_success=True):
            print(Fore.LIGHTGREEN_EX + "Hoàn tất")
            return True
        else:
            print(Fore.LIGHTRED_EX + "Không thể đặt Android ID")
            return False

    @staticmethod
    def disable_animations() -> bool:
        print(Fore.LIGHTYELLOW_EX + "Đang tắt hiệu ứng động Android...", end=" ")
        animation_settings = [
            ["settings", "put", "global", "window_animation_scale", "0"],
            ["settings", "put", "global", "transition_animation_scale", "0"],
            ["settings", "put", "global", "animator_duration_scale", "0"]
        ]
        success = True
        for cmd in animation_settings:
            if not Utils.run_cmd(cmd, check_success=True):
                print(Fore.LIGHTRED_EX + f"Không thể tắt {cmd[3]}")
                success = False
        if success:
            print(Fore.LIGHTGREEN_EX + "Đã tắt tất cả hiệu ứng động thành công")
        return success

class MenuActions:
    @staticmethod
    def auto_rejoin() -> None:
        cfg = ConfigManager.load_config()
        reconnect_dir = cfg.get("reconnect_dir")

        restart_intervals = cfg.get("restart_intervals", {})
        last_restart_track = {}

        if not reconnect_dir or not os.path.exists(reconnect_dir):
            found = RobloxManager.find_reconnect_dirs()
            if not found:
                reconnect_dir = Utils.prompt("Không tìm thấy. Nhập thủ công đường dẫn Reconnect:")
            elif len(found) == 1:
                reconnect_dir = found[0]
            else:
                print("Tìm thấy nhiều thư mục:")
                for i, d in enumerate(found):
                    print(f"{i+1}. {d}")
                idx = int(input("Chọn số: ")) - 1
                reconnect_dir = found[idx]
            cfg["reconnect_dir"] = reconnect_dir
            ConfigManager.save_config(cfg)

        accounts = ConfigManager.load_accounts()
        links = dict(ConfigManager.load_server_links())
        for pkg in list(links.keys()):
            links[pkg] = RobloxManager.format_server_link(links[pkg])

        for pkg, _ in accounts:
            last_restart_track[pkg] = time.time()

        Utils.msg("[i] Bắt đầu auto rejoin local...", "info")

        print(Fore.LIGHTCYAN_EX + "--- Cấu hình Auto Restart ---")
        for pkg, mins in restart_intervals.items():
            if mins > 0:
                print(f"> {pkg}: {mins} phút")
        print("-----------------------------")

        try:
            while True:
                Utils.clear()
                Utils.msg("[i] Bắt đầu vòng check mới...", "info")
                current_time = time.time()

                for pkg, username in accounts:
                    interval_minutes = restart_intervals.get(pkg, 0)

                    if pkg not in last_restart_track:
                        last_restart_track[pkg] = current_time

                    if interval_minutes > 0:
                        elapsed = current_time - last_restart_track[pkg]
                        if elapsed >= (interval_minutes * 60):
                            Utils.msg(f"[!!!] SCHEDULED RESTART: {username} ({interval_minutes}m interval)", "warn")
                            RobloxManager.kill_roblox_process(pkg)
                            link = links.get(pkg, "")
                            RobloxManager.launch_roblox(pkg, link)

                            last_restart_track[pkg] = time.time()
                            WebhookManager.send_webhook(f"♻️ **Scheduled Restart** executed for **{username}** after {interval_minutes} mins.")

                            time.sleep(5)
                            continue

                    hb_file = os.path.join(reconnect_dir, f"reconnect_status_{username}.json")
                    online, age, uname, reason = RobloxManager.read_heartbeat(hb_file)
                    if online:
                        Utils.msg(f"[✓] {username} online (age={age:.0f}s)", "ok")
                    else:
                        Utils.msg(f"[*] {username} OFFLINE → {reason} → rejoin {pkg}", "err")
                        RobloxManager.kill_roblox_process(pkg)
                        link = links.get(pkg, "")
                        RobloxManager.launch_roblox(pkg, link)
                        
                        last_restart_track[pkg] = time.time()
                        WebhookManager.send_webhook(f"⚠️ **{username} OFFLINE** ({reason}) → rejoined {pkg}")
                    
                    time.sleep(5)
                
                Utils.msg(f"[i] Ngủ 200s trước vòng tiếp theo...", "info")
                time.sleep(200)
        except KeyboardInterrupt:
            Utils.msg("[i] Dừng auto rejoin.")

    @staticmethod
    def user_id_menu() -> None:
        accounts = ConfigManager.load_accounts()
        pkgs = RobloxManager.get_custom_packages()
        if not pkgs:
            Utils.msg("[!] Không tìm thấy package Roblox nào.", "err")
            Utils.wait_back_menu()
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

        username = Utils.prompt("Nhập username:")
        accounts.append((pkg, username))
        ConfigManager.save_accounts(accounts)
        Utils.msg(f"[i] Đã lưu Username cho package {pkg}.", "ok")
        Utils.wait_back_menu()

    @staticmethod
    def set_common_link() -> None:
        pkgs = RobloxManager.get_custom_packages()
        if not pkgs:
            Utils.msg("[!] Không tìm thấy package Roblox nào.", "err")
            Utils.wait_back_menu()
            return

        link = Utils.prompt("Nhập ID Game/Link server chung:")
        formatted = RobloxManager.format_server_link(link)
        if not formatted:
            Utils.msg("[!] Link không hợp lệ.", "err")
            Utils.wait_back_menu()
            return

        ConfigManager.save_server_links([(pkg, formatted) for pkg in pkgs])
        Utils.msg(f"[i] Đã lưu link chung cho {len(pkgs)} package.", "ok")
        Utils.wait_back_menu()

    @staticmethod
    def set_package_link() -> None:
        pkgs = RobloxManager.get_custom_packages()
        if not pkgs:
            Utils.msg("[!] Không tìm thấy package Roblox nào.", "err")
            Utils.wait_back_menu()
            return

        print("Danh sách package Roblox:")
        for i, p in enumerate(pkgs):
            print(f"{i+1}. {p}")
        idx = int(input("Chọn số package để gán link: ")) - 1
        pkg = pkgs[idx]

        link = Utils.prompt(f"Nhập link cho package {pkg}:")
        formatted = RobloxManager.format_server_link(link)
        if not formatted:
            Utils.msg("[!] Link không hợp lệ.", "err")
            Utils.wait_back_menu()
            return

        links = ConfigManager.load_server_links()
        links = [(p, l) for p, l in links if p != pkg]
        links.append((pkg, formatted))
        ConfigManager.save_server_links(links)
        Utils.msg(f"[i] Đã lưu link riêng cho {pkg}.", "ok")
        Utils.wait_back_menu()

    @staticmethod
    def delete_entry() -> None:
        t = Utils.prompt("Xóa (1=User file, 2=Server link file, 3=Cả hai):")
        if t == "1":
            if os.path.exists(ACCOUNTS_FILE):
                os.remove(ACCOUNTS_FILE)
                Utils.msg("[i] Đã xóa toàn bộ Account.txt.", "ok")
            else:
                Utils.msg("[!] Account.txt không tồn tại.", "err")
        elif t == "2":
            if os.path.exists(SERVER_LINKS_FILE):
                os.remove(SERVER_LINKS_FILE)
                Utils.msg("[i] Đã xóa toàn bộ Private_Link.txt.", "ok")
            else:
                Utils.msg("[!] Private_Link.txt không tồn tại.", "err")
        elif t == "3":
            if os.path.exists(ACCOUNTS_FILE):
                os.remove(ACCOUNTS_FILE)
                Utils.msg("[i] Đã xóa toàn bộ Account.txt.", "ok")
            if os.path.exists(SERVER_LINKS_FILE):
                os.remove(SERVER_LINKS_FILE)
                Utils.msg("[i] Đã xóa toàn bộ Private_Link.txt.", "ok")
        else:
            Utils.msg("[!] Lựa chọn không hợp lệ.", "err")
        Utils.wait_back_menu()

    @staticmethod
    def set_webhook_menu() -> None:
        url = Utils.prompt("Nhập webhook URL:")
        user_id = Utils.prompt("Nhập Discord User ID để ping (có thể bỏ trống):")
        WebhookManager.set_webhook(url, user_id)
        Utils.msg("[i] Đã lưu webhook và user ID.", "ok")
        Utils.wait_back_menu()

    @staticmethod
    def find_uid_from_appstorage() -> None:
        pkgs = RobloxManager.get_custom_packages()
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
                Utils.msg(f"Tìm thấy username {username} cho {pkg}", "ok")
            else:
                Utils.msg(f"Không tìm thấy UID/username cho {pkg}", "err")

        if accounts:
            ConfigManager.save_accounts(accounts)
            Utils.msg("[i] Đã lưu username từ appStorage.", "ok")
            link = Utils.prompt("Nhập link chung cho các package:")
            formatted = RobloxManager.format_server_link(link)
            if formatted:
                ConfigManager.save_server_links([(pkg, formatted) for pkg, _ in accounts])
                Utils.msg("[i] Đã lưu link cho appStorage.", "ok")

        Utils.wait_back_menu()

    @staticmethod
    def show_saved() -> None:
        print("--- Account.txt ---")
        for a in ConfigManager.load_accounts():
            print(a)
        print("--- Private_Link.txt ---")
        for l in ConfigManager.load_server_links():
            print(l)
        Utils.wait_back_menu()

    @staticmethod
    def optimize_android_menu() -> None:
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
                    SystemOptimizer.disable_bloatware_apps()
                    SystemOptimizer.set_android_id()
                    SystemOptimizer.disable_animations()
                    print(Fore.LIGHTGREEN_EX + "[✓] Tối ưu Android hoàn tất.")
            elif choice == "2":
                if input("Bạn có chắc muốn vô hiệu hóa bloatware? (y/n): ").lower() == "y":
                    SystemOptimizer.disable_bloatware_apps()
            elif choice == "3":
                SystemOptimizer.set_android_id()
            elif choice == "4":
                SystemOptimizer.disable_animations()
            elif choice == "5":
                print("Quay lại menu chính...")
                Utils.wait_back_menu()
                break
            else:
                print(Fore.LIGHTYELLOW_EX + "⚠ Lựa chọn không hợp lệ, vui lòng nhập 1-5.")

    @staticmethod
    def add_autoexecute_script() -> None:
        dirs = RobloxManager.find_autoexecute_dirs()
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
            filename = os.path.join(auto_dir, "checkonline.txt")
            script_content = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/JustLegits/miscscript/main/checkonline.lua"))()'
        elif choice == "2":
            existing = [f for f in os.listdir(auto_dir) if f.startswith("autoexecute") and f.endswith(".txt")]
            nums = []
            for f in existing:
                try:
                    n = int(f.replace("autoexecute", "").replace(".txt", ""))
                    nums.append(n)
                except:
                    pass
            next_num = max(nums) + 1 if nums else 1
            filename = os.path.join(auto_dir, f"autoexecute{next_num}.txt")

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

        try:
            with open(filename, "w", encoding="utf-8") as f:
                f.write(script_content + "\n")
            print(Fore.LIGHTGREEN_EX + f"Đã lưu script vào {filename}")
        except Exception as e:
            print(Fore.LIGHTRED_EX + f"Lỗi lưu file: {e}")

        Utils.wait_back_menu()

    @staticmethod
    def export_import_config() -> None:
        print("\n===== EXPORT / IMPORT CONFIG =====")
        print("1. Export config (ghi ra file + gửi lên webhook)")
        print("2. Import config (nhập JSON, link URL, hoặc file)")
        print("3. Quay lại")
        choice = input("Chọn: ").strip()

        if choice == "1":
            data = {}
            data["config"] = ConfigManager.load_config()
            data["accounts"] = ConfigManager.load_accounts()
            data["links"] = ConfigManager.load_server_links()
            url, uid = WebhookManager.get_webhook()
            data["webhook"] = {"url": url, "uid": uid}

            try:
                json_text = json.dumps(data, ensure_ascii=False)
                with open("localrejoinconfig.json", "w", encoding="utf-8") as f:
                    f.write(json_text)

                Utils.msg("[✓] Đã export config → localrejoinconfig.json", "ok")

                if not url:
                    Utils.msg("[!] Không tìm thấy webhook URL để gửi. Chỉ export ra file.", "err")
                else:
                    Utils.msg("[i] Đang gửi config backup lên webhook...", "info")
                    try:
                        files = {
                            'file': ('localrejoinconfig.json', json_text, 'application/json')
                        }
                        payload_json = {
                            "content": f"Backup config từ tool localrejoin. User: <@{uid}>" if uid else "Backup config từ tool localrejoin."
                        }
                        r = requests.post(url, files=files, data={"payload_json": json.dumps(payload_json)}, timeout=10)

                        if 200 <= r.status_code < 300:
                            Utils.msg("[✓] Đã gửi config backup lên webhook thành công.", "ok")
                        else:
                            Utils.msg(f"[!] Gửi webhook thất bại. Status: {r.status_code}, Response: {r.text}", "err")
                    except Exception as e:
                        Utils.msg(f"[!] Lỗi khi gửi config lên webhook: {e}", "err")

            except Exception as e:
                Utils.msg(f"[!] Lỗi export: {e}", "err")

            Utils.wait_back_menu()

        elif choice == "2":
            pasted = Utils.prompt("Dán JSON, nhập URL, hoặc Enter để đọc file localrejoinconfig.json:")
            data = None
            
            try:
                pasted = pasted.strip()
                if not pasted:
                    if os.path.exists("localrejoinconfig.json"):
                        with open("localrejoinconfig.json", "r", encoding="utf-8") as f:
                            data = json.load(f)
                        Utils.msg("[i] Đã đọc config từ localrejoinconfig.json", "info")
                    else:
                        Utils.msg("[!] File localrejoinconfig.json không tồn tại.", "err")
                        Utils.wait_back_menu()
                        return

                elif pasted.startswith("http://") or pasted.startswith("https://"):
                    try:
                        Utils.msg("[i] Đang tải config từ URL...", "info")
                        r = requests.get(pasted, timeout=10)
                        r.raise_for_status()
                        data = r.json()
                        Utils.msg("[✓] Tải và phân tích JSON từ URL thành công.", "ok")
                    except requests.exceptions.RequestException as req_e:
                        Utils.msg(f"[!] Lỗi khi tải URL: {req_e}", "err")
                        Utils.wait_back_menu()
                        return
                    except json.JSONDecodeError as json_e:
                        Utils.msg(f"[!] Nội dung từ URL không phải JSON hợp lệ: {json_e}", "err")
                        Utils.wait_back_menu()
                        return

                elif pasted.startswith("{") and pasted.endswith("}"):
                    data = json.loads(pasted)
                    Utils.msg("[i] Đã phân tích JSON được dán vào.", "info")

                else:
                    Utils.msg("[!] Đầu vào không hợp lệ. Không phải URL, JSON, hoặc để trống.", "err")
                    Utils.wait_back_menu()
                    return

            except Exception as e:
                Utils.msg(f"[!] Lỗi phân tích JSON hoặc đọc file: {e}", "err")
                Utils.wait_back_menu()
                return

            if data is None:
                Utils.msg("[!] Không thể tải dữ liệu config.", "err")
                Utils.wait_back_menu()
                return

            try:
                if "config" in data:
                    ConfigManager.save_config(data["config"])

                if "accounts" in data:
                    ConfigManager.save_accounts(data["accounts"])

                if "links" in data:
                    ConfigManager.save_server_links(data["links"])

                if "webhook" in data and isinstance(data["webhook"], dict):
                    WebhookManager.set_webhook(data["webhook"].get("url", ""), data["webhook"].get("uid", ""))

                Utils.msg("[✓] Đã import config thành công!", "ok")
            except Exception as e:
                Utils.msg(f"[!] Lỗi khi import dữ liệu: {e}", "err")

            Utils.wait_back_menu()

        elif choice == "3":
            return
        else:
            Utils.msg("[!] Lựa chọn không hợp lệ.", "err")

    @staticmethod
    def manage_startup() -> None:
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
            Utils.wait_back_menu()

        elif choice == "2":
            try:
                if os.path.exists(startup_file):
                    os.remove(startup_file)
                    print(Fore.LIGHTGREEN_EX + "[✓] Đã tắt auto start.")
                else:
                    print(Fore.LIGHTYELLOW_EX + "[i] Startup chưa được bật hoặc file không tồn tại.")
            except Exception as e:
                print(Fore.LIGHTRED_EX + f"[!] Lỗi khi tắt startup: {e}")
            Utils.wait_back_menu()

        elif choice == "3":
            return
        else:
            Utils.msg("[!] Lựa chọn không hợp lệ.", "err")

    @staticmethod
    def restart_interval_menu() -> None:
        cfg = ConfigManager.load_config()
        current_intervals = cfg.get("restart_intervals", {})

        print("\n===== PERIODIC RESTART (AUTO RESET) =====")
        print("Tính năng: Tự động tắt và mở lại game sau khoảng thời gian nhất định (bất kể đang online hay offline).")
        print("Nhập 0 để tắt tính năng này.")
        print("-----------------------------------------")
        print("1. Cài đặt thời gian cho TẤT CẢ package")
        print("2. Cài đặt thời gian cho TỪNG package riêng lẻ")
        print("3. Quay lại")

        choice = input("Chọn: ").strip()

        if choice == "1":
            try:
                minutes = int(input("Nhập số phút (VD: 30, 60, 0 để tắt): "))
            except ValueError:
                Utils.msg("[!] Vui lòng nhập số nguyên.", "err")
                Utils.wait_back_menu()
                return

            pkgs = RobloxManager.get_custom_packages()
            if not pkgs:
                Utils.msg("[!] Không tìm thấy package nào.", "err")
                return

            for pkg in pkgs:
                current_intervals[pkg] = minutes

            cfg["restart_intervals"] = current_intervals
            ConfigManager.save_config(cfg)
            Utils.msg(f"[✓] Đã đặt thời gian restart {minutes} phút cho {len(pkgs)} package.", "ok")
            Utils.wait_back_menu()

        elif choice == "2":
            pkgs = RobloxManager.get_custom_packages()
            if not pkgs:
                Utils.msg("[!] Không tìm thấy package nào.", "err")
                Utils.wait_back_menu()
                return

            print("\nDanh sách package:")
            for i, p in enumerate(pkgs):
                curr_val = current_intervals.get(p, 0)
                print(f"{i+1}. {p} (Hiện tại: {curr_val} phút)")

            try:
                idx = int(input("Chọn số thứ tự package: ")) - 1
                if 0 <= idx < len(pkgs):
                    target_pkg = pkgs[idx]
                    minutes = int(input(f"Nhập số phút restart cho {target_pkg} (0 để tắt): "))

                    current_intervals[target_pkg] = minutes
                    cfg["restart_intervals"] = current_intervals
                    ConfigManager.save_config(cfg)
                    Utils.msg(f"[✓] Đã cập nhật {target_pkg} -> {minutes} phút.", "ok")
                else:
                    Utils.msg("[!] Số thứ tự không hợp lệ.", "err")
            except ValueError:
                Utils.msg("[!] Vui lòng nhập số.", "err")
            Utils.wait_back_menu()

        elif choice == "3":
            return
        else:
            Utils.msg("[!] Lựa chọn không hợp lệ.", "err")

def menu() -> None:
    while True:
        Utils.clear()
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
13 Cài đặt Auto Restart (Interval Reset)
14 Thoát tool
======================
""")
        choice = input("Chọn: ").strip()
        if choice == "1":
            MenuActions.auto_rejoin()
        elif choice == "2":
            MenuActions.user_id_menu()
        elif choice == "3":
            MenuActions.set_common_link()
        elif choice == "4":
            MenuActions.set_package_link()
        elif choice == "5":
            MenuActions.delete_entry()
        elif choice == "6":
            MenuActions.set_webhook_menu()
        elif choice == "7":
            MenuActions.find_uid_from_appstorage()
        elif choice == "8":
            MenuActions.show_saved()
        elif choice == "9":
            MenuActions.optimize_android_menu()
        elif choice == "10":
            MenuActions.add_autoexecute_script()
        elif choice == "11":
            MenuActions.export_import_config()
        elif choice == "12":
            MenuActions.manage_startup()
        elif choice == "13":
            MenuActions.restart_interval_menu()
        elif choice == "14":
            break
        else:
            Utils.msg("[!] Lựa chọn không hợp lệ.", "err")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Local Rejoin Tool")
    parser.add_argument("--auto", action="store_true", help="Run auto rejoin immediately")
    args = parser.parse_args()

    if args.auto:
        MenuActions.auto_rejoin()
    else:
        menu()
