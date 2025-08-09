# Obfuscated by ro-obf-bot
_ctfRiVPd = 56245201
assert _ctfRiVPd == 56245201
import sys
assert not sys.gettrace()
if 0: _rYZLkyXk = 735336
for _ in range(3): pass
try: _PqObGqtX = 1/1
except: pass
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
import xml .etree .ElementTree as ET 
import random 
from colorama import init ,Fore ,Style 
from PIL import ImageGrab # Pillow, dùng cho screenshot

init (autoreset =True )

SERVER_LINKS_FILE =('Private_Link.txt') 
ACCOUNTS_FILE =('Account.txt') 
CONFIG_FILE =('Config.json') 

# ------------- Language -------------
LANGS ={
('vi') :{
('menu_title') :('') ,
('menu') :[
('/1 Auto rejoin') ,
('/2 User ID') ,
('/3 Thiết lập chung 1 ID Game/Link server') ,
('/4 Gán ID Game/Link riêng cho từng pack') ,
('/5 Xóa User ID hoặc Link server') ,
('/6 Thiết lập webhook Discord') ,
('/7 Tự động tìm User ID từ appStorage.json') ,
('/8 Xem danh sách đã lưu') ,
('/9 Same hardware id + Bypass key') ,
('/10 Thoát tool') 
],
('input_choice') :('Nhập lựa chọn (1-10):') ,
('no_account_link') :('Chưa có User ID hoặc link Server! Thiết lập trước.') ,
('starting_roblox') :('Đang khởi động Roblox...') ,
('auto_running') :('Auto rejoin đang chạy. Dừng bằng Ctrl+C!') ,
('stop_auto') :('Dừng auto rejoin.') ,
('enter_uid') :('Nhập User ID hoặc Username cho {package}:') ,
('getting_uid') :('Đang lấy User ID cho {name}...') ,
('cant_get_uid') :('Không lấy được User ID! Nhập tay:') ,
('assign_uid') :('Gán {package} cho User ID {uid}') ,
('saved_uid') :('Đã lưu User ID!') ,
('enter_link') :('Nhập ID Game hoặc Link Server:') ,
('saved_link') :('Đã lưu link server!') ,
('enter_link_each') :('Nhập ID Game/Link server cho {package}:') ,
('saved_each_link') :('Đã lưu từng link server!') ,
('delete_what') :('Xóa gì? [1]UserID [2]Link [3]Cả 2 :') ,
('deleted_uid') :('Đã xóa User ID.') ,
('deleted_link') :('Đã xóa Link Server.') ,
('deleted_both') :('Đã xóa cả User ID và Link Server.') ,
('invalid_or_not_exist') :('Không hợp lệ hoặc file không tồn tại.') ,
('enter_webhook') :('Nhập webhook Discord:') ,
('enter_device') :('Nhập tên thiết bị:') ,
('enter_interval') :('Phút giữa mỗi lần gửi thông tin lên webhook:') ,
('must_int') :('Nhập số nguyên!') ,
('saved_webhook') :('Đã lưu webhook config!') ,
('not_found_uid') :('Không tìm được User ID cho {pkg}') ,
('found_uid') :('{pkg}: {uid}') ,
('saved_uid_appstorage') :('Đã lưu User ID từ appStorage.json') ,
('enter_link_appstorage') :('Nhập ID Game/Link Server:') ,
('saved_link_appstorage') :('Đã lưu link server!') ,
('saved_accounts') :('Danh sách tài khoản Roblox đã lưu:') ,
('bye') :('Tạm biệt!') ,
('invalid_choice') :('Lựa chọn không hợp lệ!') ,
('playing') :('Đang chơi') ,
('lobby') :('Trong sảnh') ,
('offline') :('Offline') ,
('unknown') :('?') ,
('fluxus_bypass') :('Fluxus Bypass: {bypass_status}') ,
('rejoin_out') :('{username} ({uid}) đã out. Đang rejoin...') ,
('rejoin_in') :('{username} ({uid}) vẫn đang chơi.') ,
('send_webhook_ok') :('Đã gửi thông tin thiết bị lên webhook!') ,
('send_webhook_err') :('Lỗi gửi webhook!') ,
('roblox_launch_err') :('Lỗi mở Roblox cho {package}: {e}') ,
('invalid_link') :('Link không hợp lệ!') ,
('bypass_done') :('Đã thực hiện samehwid + bypass key codeX!') ,
('androidid_fail') :('Không thể đổi Android ID!') ,
},
('en') :{
('menu_title') :('') ,
('menu') :[
('/1 Auto rejoin Roblox game') ,
('/2 Set User ID for each package') ,
('/3 Set a single Game ID/Server Link for all') ,
('/4 Assign Game ID/Server Link for each package') ,
('/5 Delete User ID or Server Link') ,
('/6 Configure Discord webhook') ,
('/7 Auto-detect User ID from appStorage.json') ,
('/8 View saved accounts and links') ,
('/9 Same hardware id + Bypass key') ,
('/10 Exit tool') 
],
('input_choice') :('Enter your choice (1-10):') ,
('no_account_link') :('No User ID or Server Link found! Please set up first.') ,
('starting_roblox') :('Starting Roblox...') ,
('auto_running') :('Auto rejoin is running. Stop with Ctrl+C!') ,
('stop_auto') :('Stopped auto rejoin.') ,
('enter_uid') :('Enter User ID or Username for {package}:') ,
('getting_uid') :('Getting User ID for {name}...') ,
('cant_get_uid') :('Could not get User ID! Enter manually:') ,
('assign_uid') :('Assigned {package} to User ID {uid}') ,
('saved_uid') :('User ID saved!') ,
('enter_link') :('Enter Game ID or Server Link:') ,
('saved_link') :('Server link saved!') ,
('enter_link_each') :('Enter Game ID/Server Link for {package}:') ,
('saved_each_link') :('Saved each server link!') ,
('delete_what') :('Delete what? [1]UserID [2]Link [3]Both :') ,
('deleted_uid') :('User ID deleted.') ,
('deleted_link') :('Server Link deleted.') ,
('deleted_both') :('Both User ID and Server Link deleted.') ,
('invalid_or_not_exist') :('Invalid or file does not exist.') ,
('enter_webhook') :('Enter Discord webhook:') ,
('enter_device') :('Enter device name:') ,
('enter_interval') :('Minutes between each webhook info send:') ,
('must_int') :('Enter an integer!') ,
('saved_webhook') :('Webhook config saved!') ,
('not_found_uid') :('Could not find User ID for {pkg}') ,
('found_uid') :('{pkg}: {uid}') ,
('saved_uid_appstorage') :('User ID from appStorage.json saved') ,
('enter_link_appstorage') :('Enter Game ID/Server Link:') ,
('saved_link_appstorage') :('Server link saved!') ,
('saved_accounts') :('Saved Roblox accounts:') ,
('bye') :('Goodbye!') ,
('invalid_choice') :('Invalid choice!') ,
('playing') :('Playing') ,
('lobby') :('In lobby') ,
('offline') :('Offline') ,
('unknown') :('?') ,
('fluxus_bypass') :('beta Bypass: {bypass_status}') ,
('rejoin_out') :('{username} ({uid}) is out. Rejoining...') ,
('rejoin_in') :('{username} ({uid}) is still playing.') ,
('send_webhook_ok') :('Device info sent to webhook!') ,
('send_webhook_err') :('Failed to send webhook!') ,
('roblox_launch_err') :('Failed to launch Roblox for {package}: {e}') ,
('invalid_link') :('Invalid link!') ,
('bypass_done') :('Done samehwid + bypass key codeX!') ,
('androidid_fail') :('Failed to change Android ID!') ,
}
}

LANG =LANGS [('vi') ]# default

def _gniJtgnv ():
    global LANG 
    print (Fore .LIGHTYELLOW_EX +('Select language :') )
    print (('1. Vietnamese') )
    print (('2. English') )
    lang_choice =input (('Choice : ') ).strip ()
    if lang_choice ==('2') :
        LANG =LANGS [('en') ]
    else :
        LANG =LANGS [('vi') ]

        # ------------- UI Helper -------------
def _LQEnYvZW ():
    import os 
    # Xóa sạch màn hình, không in lại gì cả
    os .system (('cls') if os .name ==('nt') else ('clear') )

def _bplstWIm ():
    _LQEnYvZW ()
    print (Fore .LIGHTMAGENTA_EX +("\n  ____                 _       __  __                                   \n |  _ \\ ___  ___ _   _| |__   |  \\/  | __ _ _ __   __ _  __ _  ___ _ __ \n | |_) / _ \\/ __| | | | '_ \\  | |\\/| |/ _` | '_ \\ / _` |/ _` |/ _ \\ '__|\n |  _ < (_) \\__ \\ |_| | |_) | | |  | | (_| | | | | (_| | (_| |  __/ |   \n |_| \\_\\___/|___/\\__, |_.__/  |_|  |_|\\__,_|_| |_|\\__,_|\\__, |\\___|_|   \n                 |___/                                  |___/                                                                                        \n") +Style .RESET_ALL )
    _iSwujKlt ()
    print (Fore .LIGHTMAGENTA_EX +('') +Fore .LIGHTCYAN_EX +(' discord.gg/KmFM6DyvPB        ') +Fore .LIGHTMAGENTA_EX +('') )
    print (Fore .LIGHTMAGENTA_EX +('') +Fore .LIGHTCYAN_EX +(' Made by : th4t9ng - Rosyb Manager                       ') +Fore .LIGHTMAGENTA_EX +('') +Style .RESET_ALL )
    print ()

def _iSwujKlt ():
    cpu =psutil .cpu_percent (interval =0.5 )
    ram =psutil .virtual_memory ().percent 
    disk =psutil .disk_usage (('/') ).percent 
    print (
    f"{Fore .LIGHTYELLOW_EX }CPU: {cpu :.1f}% | RAM: {ram :.1f}% | Disk: {disk :.1f}%{Style .RESET_ALL }"
    )

def _SrnhTFkZ ():
    print (Fore .LIGHTBLACK_EX +('─') *55 +Style .RESET_ALL )

def _IhCyFGYg ():
    menu_title =LANG .get (('menu_title') ,('') )
    print (Fore .LIGHTGREEN_EX +menu_title +Style .RESET_ALL )
    print (Fore .LIGHTBLUE_EX +('+----+-----------------------------------------------+') +Style .RESET_ALL )
    print (Fore .LIGHTBLUE_EX +('| No | Service Name                                 |') +Style .RESET_ALL )
    print (Fore .LIGHTBLUE_EX +('+----+-----------------------------------------------+') +Style .RESET_ALL )
    for idx ,_ZAZCsRdv in enumerate (LANG [('menu') ],1 ):
        name =_ZAZCsRdv 
        if ('/') in name :
            name =name .split ((' ') ,1 )[-1 ]
        if len (name )>45 :
            name =name [:42 ]+('...') 
        print (f"| {str (idx ).ljust (2 )} | {name .ljust (45 )}|")
    print (Fore .LIGHTBLUE_EX +('+----+-----------------------------------------------+') +Style .RESET_ALL )
    _SrnhTFkZ ()

def _dSYvqykq (_dafuzPzX ,type =('info') ):
    if type ==('info') :
        print (Fore .LIGHTCYAN_EX +('[i]') +Style .RESET_ALL ,_dafuzPzX )
    elif type ==('ok') :
        print (Fore .LIGHTGREEN_EX +('[✓]') +Style .RESET_ALL ,_dafuzPzX )
    elif type ==('err') :
        print (Fore .LIGHTRED_EX +('[!]') +Style .RESET_ALL ,_dafuzPzX )
    elif type ==('warn') :
        print (Fore .LIGHTYELLOW_EX +('[*]') +Style .RESET_ALL ,_dafuzPzX )
    elif type ==('input') :
        print (Fore .LIGHTMAGENTA_EX +('[?]') +Style .RESET_ALL ,_dafuzPzX ,end =(' ') )
    else :
        print (_dafuzPzX )

def _zYnBhkEn (accounts ,bypass_status ):
    _SrnhTFkZ ()
    print (f"{Fore .LIGHTBLUE_EX }{('Gói') if LANG ==LANGS [('vi') ]else ('Package') :<18} {('User') :<18} {('Trạng thái') if LANG ==LANGS [('vi') ]else ('Status') :<12}{Style .RESET_ALL }")
    _SrnhTFkZ ()
    for package ,uid in accounts :
        username =_IdzgLGfc (uid )or uid 
        ptype =_GENWfnFz (uid )
        if ptype ==2 :
            status =Fore .LIGHTGREEN_EX +LANG [('playing') ]
        elif ptype ==1 :
            status =Fore .LIGHTYELLOW_EX +LANG [('lobby') ]
        elif ptype ==0 :
            status =Fore .LIGHTRED_EX +LANG [('offline') ]
        else :
            status =Fore .LIGHTBLACK_EX +LANG [('unknown') ]
        print (f"{Fore .LIGHTCYAN_EX }{package :<18}{Style .RESET_ALL } {username :<18} {status +Style .RESET_ALL :<12}")
    _SrnhTFkZ ()
    print (Fore .LIGHTMAGENTA_EX +LANG [('fluxus_bypass') ].format (bypass_status =bypass_status )+Style .RESET_ALL )
    _SrnhTFkZ ()

def _EywWRPVv (_dafuzPzX ):
    _dSYvqykq (_dafuzPzX ,('input') )
    return input ()

def _yYAsLMaa ():
    input (('\nPress Enter to back to menu...') )

    # ------------- CONFIG -------------
def _dCYYhBVx ():
    if os .path .exists (CONFIG_FILE ):
        with open (CONFIG_FILE ,('r') )as f :
            cfg =json .load (f )
            return cfg .get (('webhook_url') ),cfg .get (('device_name') ),cfg .get (('interval') )
    return None ,None ,None 

def _tFWpAAab (webhook_url ,device_name ,interval ):
    with open (CONFIG_FILE ,('w') )as f :
        json .dump ({('webhook_url') :webhook_url ,('device_name') :device_name ,('interval') :interval },f )

        # ------------- File IO -------------
def _VdkhPQJw (server_links ):
    with open (SERVER_LINKS_FILE ,('w') )as f :
        for package ,link in server_links :
            f .write (f"{package },{link }\n")

def _AoODPJlV ():
    if not os .path .exists (SERVER_LINKS_FILE ):return []
    with open (SERVER_LINKS_FILE ,('r') )as f :
        return [tuple (line .strip ().split ((',') ,1 ))for line in f ]

def _eUuPsmdO (accounts ):
    with open (ACCOUNTS_FILE ,('w') )as f :
        for package ,uid in accounts :
            f .write (f"{package },{uid }\n")

def _pbgOpVjA ():
    if not os .path .exists (ACCOUNTS_FILE ):return []
    with open (ACCOUNTS_FILE ,('r') )as f :
        return [tuple (line .strip ().split ((',') ,1 ))for line in f ]

def _tAnfcFxA (_klXhDVpk ):
    try :
        with open (_klXhDVpk ,('r') )as f :
            c =f .read ()
            s =c .find (('"UserId":"') )
            if s ==-1 :return None 
            s +=len (('"UserId":"') )
            e =c .find (('"') ,s )
            return c [s :e ]
    except :return None 

    # ------------- Roblox -------------
def _HzAzytrj ():
    result =subprocess .run (("pm list packages | grep 'roblox'") ,shell =True ,capture_output =True ,text =True )
    if result .returncode ==0 :
        return [line .split ((':') )[1 ]for line in result .stdout .splitlines ()]
    return []

async def _IAzNTOnx (username ):
    url =('https://users.roblox.com/v1/usernames/users') 
    payload ={('usernames') :[username ],('excludeBannedUsers') :True }
    headers ={('Content-Type') :('application/json') }
    async with aiohttp .ClientSession ()as session :
        async with session .post (url ,json =payload ,headers =headers )as response :
            data =await response .json ()
            if ('data') in data and len (data [('data') ])>0 :
                return str (data [('data') ][0 ][('id') ])
    return None 

def _IdzgLGfc (_biAxJzox ):
    try :
        url =f"https://users.roblox.com/v1/users/{_biAxJzox }"
        r =requests .get (url ,timeout =3 )
        r .raise_for_status ()
        data =r .json ()
        return data .get (('name') ,('Không rõ') if LANG ==LANGS [('vi') ]else ('Unknown') )
    except :
        return None 

def _GENWfnFz (_biAxJzox ):
    try :
        url =('https://presence.roblox.com/v1/presence/users') 
        headers ={('Content-Type') :('application/json') }
        body =json .dumps ({('userIds') :[int (_biAxJzox )]})
        r =requests .post (url ,headers =headers ,data =body ,timeout =3 )
        r .raise_for_status ()
        data =r .json ()
        return data [('userPresences') ][0 ][('userPresenceType') ]
    except :
        return None 

def _iYGPuYtq ():
    for package in _HzAzytrj ():
        os .system (f"pkill -f {package }")
    time .sleep (2 )

def _eZDXukPO (package ):
    os .system (f"pkill -f {package }")
    time .sleep (2 )

def _zQEoUbxb (package ,_wSLYFZxT ):
    try :
        subprocess .run ([('am') ,('start') ,('-n') ,f'{package }/com.roblox.client.startup.ActivitySplash',('-d') ,_wSLYFZxT ],stdout =subprocess .DEVNULL ,stderr =subprocess .DEVNULL )
        time .sleep (3 )
        subprocess .run ([('am') ,('start') ,('-n') ,f'{package }/com.roblox.client.ActivityProtocolLaunch',('-d') ,_wSLYFZxT ],stdout =subprocess .DEVNULL ,stderr =subprocess .DEVNULL )
        time .sleep (3 )
    except Exception as e :
        _dSYvqykq (LANG [('roblox_launch_err') ].format (package =package ,e =e ),('err') )

def _ObwBeGAh (_QfLZllso ):
    if ('roblox.com') in _QfLZllso :
        return _QfLZllso 
    elif _QfLZllso .isdigit ():
        return f'roblox://placeID={_QfLZllso }'
    else :
        _dSYvqykq (LANG [('invalid_link') ],('err') )
        return None 

        # ------------- Screenshot & Webhook -------------
def _dgCcSFBR(filename="screenshot.png"):
    try:
        import os, subprocess, time
        # Tạo tên file ảnh mới theo timestamp
        filename = f"screenshot_{int(time.time())}.png"
        filepath = os.path.join(os.getcwd(), filename)
        # Gọi termux-screenshot
        subprocess.run(["termux-screenshot", filepath], check=True)
        if os.path.exists(filepath):
            return filepath
        else:
            return None
    except Exception as e:
        return None

def _SgixsLHi (webhook_url ,device_name ):
    sysinfo =_nyyarPPs ()
    embed ={
    ('title') :f"{('Thông tin hệ thống') if LANG ==LANGS [('vi') ]else ('System info') } {device_name }",
    ('color') :15258703 ,
    ('fields') :[
    {('name') :('Tên thiết bị') if LANG ==LANGS [('vi') ]else ('Device name') ,('value') :device_name ,('inline') :True },
    {('name') :('CPU') ,('value') :f"{sysinfo [('cpu_usage') ]}%",('inline') :True },
    {('name') :('RAM đã dùng') if LANG ==LANGS [('vi') ]else ('RAM used') ,('value') :f"{sysinfo [('memory_used') ]/sysinfo [('memory_total') ]*100 :.2f}%",('inline') :True },
    {('name') :('RAM trống') if LANG ==LANGS [('vi') ]else ('RAM free') ,('value') :f"{sysinfo [('memory_available') ]/sysinfo [('memory_total') ]*100 :.2f}%",('inline') :True },
    {('name') :('Tổng RAM') if LANG ==LANGS [('vi') ]else ('Total RAM') ,('value') :f"{sysinfo [('memory_total') ]/(1024 **3 ):.2f} GB",('inline') :True },
    {('name') :('Uptime') ,('value') :f"{sysinfo [('uptime') ]/3600 :.2f} {('giờ') if LANG ==LANGS [('vi') ]else ('hours') }",('inline') :True }
    ]
    }
    screenshot_file =_dgCcSFBR ()
    files ={}
    if screenshot_file and os .path .exists (screenshot_file ):
        files ={('file') :open (screenshot_file ,('rb') )}
    payload ={('embeds') :[embed ],('username') :device_name }
    try :
        if files :
            response =requests .post (webhook_url ,data ={('payload_json') :json .dumps (payload )},files =files ,timeout =10 )
            files [('file') ].close ()
            os .remove (screenshot_file )
        else :
            response =requests .post (webhook_url ,json =payload ,timeout =10 )
        if response .status_code ==204 or response .status_code ==200 :
            _dSYvqykq (LANG [('send_webhook_ok') ],('ok') )
        else :
            _dSYvqykq (LANG [('send_webhook_err') ],('err') )
    except Exception :
        _dSYvqykq (LANG [('send_webhook_err') ],('err') )

def _nyyarPPs ():
    cpu_usage =psutil .cpu_percent (interval =1 )
    memory_info =psutil .virtual_memory ()
    uptime =time .time ()-psutil .boot_time ()
    return {
    ('cpu_usage') :cpu_usage ,
    ('memory_total') :memory_info .total ,
    ('memory_available') :memory_info .available ,
    ('memory_used') :memory_info .used ,
    ('uptime') :uptime 
    }

def _nNsWJBsH (webhook_url ,device_name ,interval ,stop_event ):
    while not stop_event .is_set ():
        _SgixsLHi (webhook_url ,device_name )
        stop_event .wait (interval *60 )

        # ------------- Android ID changer -------------
def _UMhYOsOq ():
    xml_path =('/data/system/users/0/settings_ssaid.xml') 
    fixed_id =('9c47a1f3b6e8d2c5') 
    try :
        tree =ET .parse (xml_path )
        root =tree .getroot ()
        changed =False 
        for setting in root .findall (('setting') ):
            if setting .attrib .get (('id') )==('android_id') :
                setting .set (('value') ,fixed_id )
                changed =True 
        if not changed :
            ET .SubElement (root ,('setting') ,id =('android_id') ,value =fixed_id )
        tree .write (xml_path )
        os .system (f"chmod 600 {xml_path }")
        # Nếu muốn tự động reboot máy ảo sau khi đổi, bỏ comment dòng dưới:
        # os.system("reboot")
        return True 
    except Exception as e :
        _dSYvqykq (LANG [('androidid_fail') ],('err') )
        return False 

        # ------------- MAIN -------------
def _wKTTSoTG ():
    _gniJtgnv ()
    stop_event =threading .Event ()
    webhook_thread =None 
    _bplstWIm ()
    webhook_url ,device_name ,interval =_dCYYhBVx ()
    bypass_status =('Chưa sử dụng') if LANG ==LANGS [('vi') ]else ('Not used') 

    while True :
        _LQEnYvZW ()# Xóa sạch màn hình trước khi in menu
        _bplstWIm ()# In lại banner ở trên cùng
        _IhCyFGYg ()
        choice =_EywWRPVv (LANG [('input_choice') ]).strip ()
        if choice ==('1') :
            accounts =_pbgOpVjA ()
            server_links =_AoODPJlV ()
            if not accounts or not server_links :
                _dSYvqykq (LANG [('no_account_link') ],('err') )
                continue 
            if webhook_url and device_name and interval and (webhook_thread is None or not webhook_thread .is_alive ()):
                stop_event .clear ()
                webhook_thread =threading .Thread (target =_nNsWJBsH ,args =(webhook_url ,device_name ,interval ,stop_event ))
                webhook_thread .daemon =True 
                webhook_thread .start ()
            _dSYvqykq (LANG [('starting_roblox') ],('info') )
            _iYGPuYtq ()
            time .sleep (2 )
            for package ,_wSLYFZxT in server_links :
                _zQEoUbxb (package ,_wSLYFZxT )
            _dSYvqykq (LANG [('auto_running') ],('ok') )
            try :
                while True :
                    for package ,uid in accounts :
                        username =_IdzgLGfc (uid )or uid 
                        status =_GENWfnFz (uid )
                        if status ==2 :
                            _dSYvqykq (LANG [('rejoin_in') ].format (username =username ,uid =uid ),('ok') )
                        else :
                            _dSYvqykq (LANG [('rejoin_out') ].format (username =username ,uid =uid ),('warn') )
                            _eZDXukPO (package )
                            link =dict (server_links ).get (package ,('') )
                            _zQEoUbxb (package ,link )
                        time .sleep (3 )
                    _zYnBhkEn (accounts ,bypass_status )
                    time .sleep (120 )
            except KeyboardInterrupt :
                _dSYvqykq (LANG [('stop_auto') ],('warn') )
        elif choice ==('2') :
            accounts =[]
            for package in _HzAzytrj ():
                name =_EywWRPVv (LANG [('enter_uid') ].format (package =package )).strip ()
                uid =name 
                if not name .isdigit ():
                    _dSYvqykq (LANG [('getting_uid') ].format (name =name ),('info') )
                    uid2 =asyncio .run (_IAzNTOnx (name ))
                    if uid2 :uid =uid2 
                    else :uid =_EywWRPVv (LANG [('cant_get_uid') ]).strip ()
                accounts .append ((package ,uid ))
                _dSYvqykq (LANG [('assign_uid') ].format (package =package ,uid =uid ),('ok') )
            _eUuPsmdO (accounts )
            _dSYvqykq (LANG [('saved_uid') ],('ok') )
            _yYAsLMaa ()
        elif choice ==('3') :
            link =_EywWRPVv (LANG [('enter_link') ]).strip ()
            formatted =_ObwBeGAh (link )
            if formatted :
                pkgs =_HzAzytrj ()
                _VdkhPQJw ([(p ,formatted )for p in pkgs ])
                _dSYvqykq (LANG [('saved_link') ],('ok') )
            _yYAsLMaa ()
        elif choice ==('4') :
            links =[]
            for package in _HzAzytrj ():
                link =_EywWRPVv (LANG [('enter_link_each') ].format (package =package )).strip ()
                formatted =_ObwBeGAh (link )
                if formatted :links .append ((package ,formatted ))
            _VdkhPQJw (links )
            _dSYvqykq (LANG [('saved_each_link') ],('ok') )
            _yYAsLMaa ()
        elif choice ==('5') :
            c =_EywWRPVv (LANG [('delete_what') ]).strip ()
            if c ==('1') and os .path .exists (ACCOUNTS_FILE ):
                os .remove (ACCOUNTS_FILE )
                _dSYvqykq (LANG [('deleted_uid') ],('ok') )
            elif c ==('2') and os .path .exists (SERVER_LINKS_FILE ):
                os .remove (SERVER_LINKS_FILE )
                _dSYvqykq (LANG [('deleted_link') ],('ok') )
            elif c ==('3') :
                if os .path .exists (ACCOUNTS_FILE ):os .remove (ACCOUNTS_FILE )
                if os .path .exists (SERVER_LINKS_FILE ):os .remove (SERVER_LINKS_FILE )
                _dSYvqykq (LANG [('deleted_both') ],('ok') )
            else :
                _dSYvqykq (LANG [('invalid_or_not_exist') ],('err') )
            _yYAsLMaa ()
        elif choice ==('6') :
            webhook_url =_EywWRPVv (LANG [('enter_webhook') ])
            device_name =_EywWRPVv (LANG [('enter_device') ])
            try :
                interval =int (_EywWRPVv (LANG [('enter_interval') ]))
            except :
                _dSYvqykq (LANG [('must_int') ],('err') );continue 
            _tFWpAAab (webhook_url ,device_name ,interval )
            _dSYvqykq (LANG [('saved_webhook') ],('ok') )
            _yYAsLMaa ()
        elif choice ==('7') :
            pkgs =_HzAzytrj ()
            accounts =[]
            for pkg in pkgs :
                fpath =f'/data/data/{pkg }/files/appData/LocalStorage/appStorage.json'
                uid =_tAnfcFxA (fpath )
                if uid :
                    accounts .append ((pkg ,uid ))
                    _dSYvqykq (LANG [('found_uid') ].format (pkg =pkg ,uid =uid ),('ok') )
                else :
                    _dSYvqykq (LANG [('not_found_uid') ].format (pkg =pkg ),('err') )
            _eUuPsmdO (accounts )
            _dSYvqykq (LANG [('saved_uid_appstorage') ],('ok') )
            link =_EywWRPVv (LANG [('enter_link_appstorage') ])
            formatted =_ObwBeGAh (link )
            if formatted :
                _VdkhPQJw ([(pkg ,formatted )for pkg in pkgs ])
                _dSYvqykq (LANG [('saved_link_appstorage') ],('ok') )
            _yYAsLMaa ()
        elif choice ==('8') :
            accounts =_pbgOpVjA ()
            links =_AoODPJlV ()
            print (Fore .LIGHTCYAN_EX +LANG [('saved_accounts') ]+Style .RESET_ALL )
            for (pkg ,uid ),(_PqrxTKPS ,link )in zip (accounts ,links ):
                username =_IdzgLGfc (uid )or uid 
                print (f"{pkg :<18} {username :<15} {uid :<15} {link }")
            _SrnhTFkZ ()
            _yYAsLMaa ()
        elif choice ==('9') :
            ok =_UMhYOsOq ()
            if ok :
                _dSYvqykq (LANG [('bypass_done') ],('ok') )
            else :
                _dSYvqykq (LANG [('androidid_fail') ],('err') )
            _yYAsLMaa ()
        elif choice ==('10') :
            if webhook_thread and webhook_thread .is_alive ():
                stop_event .set ()
            _dSYvqykq (LANG [('bye') ],('info') )
            break 
        else :
            _dSYvqykq (LANG [('invalid_choice') ],('err') )

if __name__ ==('__main__') :
    _wKTTSoTG ()
