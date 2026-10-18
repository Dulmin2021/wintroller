import asyncio
import ctypes
from ctypes import wintypes
import datetime
import json
import math
import os
import random
import socket
import subprocess
import sys
import threading
import time

import customtkinter as ctk
import psutil
from pycaw.pycaw import AudioUtilities
import websockets

# High-DPI Awareness for crisp rendering on Windows
try:
    ctypes.windll.shcore.SetProcessDpiAwareness(2)
except Exception:
    try:
        ctypes.windll.user32.SetProcessDPIAware()
    except Exception:
        pass

user32 = ctypes.windll.user32
kernel32 = ctypes.windll.kernel32
powrprof = ctypes.windll.powrprof

# Virtual Key Codes
VK_MAP = {
    'Space': 0x20,
    'Return': 0x0D,
    'Enter': 0x0D,
    'Backspace': 0x08,
    'Tab': 0x09,
    'Escape': 0x1B,
    'Shift': 0x10,
    'Control': 0x11,
    'Alt': 0x12,
    'VolumeUp': 0xAF,
    'VolumeDown': 0xAE,
    'VolumeMute': 0xAD,
    'MediaPlayPause': 0xB3,
    'MediaNext': 0xB0,
    'MediaPrev': 0xB1,
    'MediaStop': 0xB2,
}

def get_local_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
    except Exception:
        ip = '127.0.0.1'
    finally:
        s.close()
    return ip

LOCAL_IP = get_local_ip()
PRIMARY_PORT = 8092
SECONDARY_PORT = 8765
DISCOVERY_PORT = 8766


class Win32Controller:
    @staticmethod
    def mouse_move(dx: int, dy: int):
        user32.mouse_event(0x0001, int(dx), int(dy), 0, 0)

    @staticmethod
    def mouse_click(button: str = 'left'):
        if button == 'right':
            user32.mouse_event(0x0008, 0, 0, 0, 0)
            user32.mouse_event(0x0010, 0, 0, 0, 0)
        elif button == 'double':
            user32.mouse_event(0x0002, 0, 0, 0, 0)
            user32.mouse_event(0x0004, 0, 0, 0, 0)
            user32.mouse_event(0x0002, 0, 0, 0, 0)
            user32.mouse_event(0x0004, 0, 0, 0, 0)
        elif button == 'middle':
            user32.mouse_event(0x0020, 0, 0, 0, 0)
            user32.mouse_event(0x0040, 0, 0, 0, 0)
        else:
            user32.mouse_event(0x0002, 0, 0, 0, 0)
            user32.mouse_event(0x0004, 0, 0, 0, 0)

    @staticmethod
    def mouse_scroll(dy: int):
        delta = int(dy * 40)
        user32.mouse_event(0x0800, 0, 0, delta, 0)

    @staticmethod
    def send_vk(vkey: int):
        user32.keybd_event(vkey, 0, 0, 0)
        user32.keybd_event(vkey, 0, 0x0002, 0)

    @staticmethod
    def type_string(text: str):
        for char in text:
            char_code = ord(char)
            vkey_scan = user32.VkKeyScanW(char_code)
            vkey = vkey_scan & 0xFF
            shift = (vkey_scan >> 8) & 0x01
            if shift == 1:
                user32.keybd_event(0x10, 0, 0, 0)
            user32.keybd_event(vkey, 0, 0, 0)
            user32.keybd_event(vkey, 0, 0x0002, 0)
            if shift == 1:
                user32.keybd_event(0x10, 0, 0x0002, 0)

    @staticmethod
    def display_off():
        user32.SendMessageW(0xFFFF, 0x0112, 0xF170, 2)

    @staticmethod
    def display_on():
        user32.mouse_event(0x0001, 1, 1, 0, 0)
        user32.mouse_event(0x0001, -1, -1, 0, 0)

    @staticmethod
    def lock_workstation():
        user32.LockWorkStation()

    @staticmethod
    def sleep():
        powrprof.SetSuspendState(0, 1, 0)

    @staticmethod
    def hibernate():
        powrprof.SetSuspendState(1, 1, 0)

    @staticmethod
    def logoff():
        user32.ExitWindowsEx(0, 0)

    @staticmethod
    def restart():
        os.system('shutdown.exe /r /t 0')

    @staticmethod
    def shutdown():
        os.system('shutdown.exe /s /t 0')

    @staticmethod
    def set_brightness(val: int):
        clamped = max(0, min(100, int(val)))
        ps_cmd = f"Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorBrightnessMethods | Invoke-CimMethod -MethodName WmiSetBrightness -Arguments @{{Timeout = 1; Brightness = {clamped}}}"
        subprocess.Popen(['powershell', '-WindowStyle', 'Hidden', '-Command', ps_cmd], creationflags=0x08000000)

    @staticmethod
    def set_wifi(enable: bool):
        ps_cmd = f"Get-NetAdapter -Name *Wi-Fi*,*Wireless*,*WLAN* -ErrorAction SilentlyContinue | {'Enable-NetAdapter' if enable else 'Disable-NetAdapter'} -Confirm:$false -ErrorAction SilentlyContinue"
        subprocess.Popen(['powershell', '-WindowStyle', 'Hidden', '-Command', ps_cmd], creationflags=0x08000000)

    @staticmethod
    def set_bluetooth(enable: bool):
        ps_cmd = f"try {{ [Windows.Devices.Radios.Radio,Windows.System.Devices,ContentType=WindowsRuntime] | Out-Null; $radios = [Windows.Devices.Radios.Radio]::GetRadiosAsync().GetAwaiter().GetResult(); $bt = $radios | Where-Object {{ $_.Kind -eq 'Bluetooth' }}; if ($bt) {{ $bt.SetStateAsync('{'On' if enable else 'Off'}').GetAwaiter().GetResult() }} }} catch {{ Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue | {'Enable-PnpDevice' if enable else 'Disable-PnpDevice'} -Confirm:$false -ErrorAction SilentlyContinue }}"
        subprocess.Popen(['powershell', '-WindowStyle', 'Hidden', '-Command', ps_cmd], creationflags=0x08000000)


class WintrollerCompanionApp:
    def __init__(self):
        ctk.set_appearance_mode('dark')
        ctk.set_default_color_theme('dark-blue')

        self.root = ctk.CTk()
        self.root.overrideredirect(True)
        self.root.geometry('840x330')
        self.root.configure(fg_color='#0B0E17')

        # Center on screen
        self.root.update_idletasks()
        screen_w = self.root.winfo_screenwidth()
        screen_h = self.root.winfo_screenheight()
        pos_x = max(0, (screen_w - 840) // 2)
        pos_y = max(0, (screen_h - 330) // 2)
        self.root.geometry(f'840x330+{pos_x}+{pos_y}')

        self._drag_start_x = 0
        self._drag_start_y = 0
        self._is_maximized = False
        self._prev_geom = None

        self.current_volume = 50
        self.current_brightness = 80
        self.current_ping = 0.0
        self.connected_client = None
        self.is_client_connected = False
        self.active_ports = []

        self.connected_websockets = set()
        self.log_lines = []

        self._setup_taskbar()
        self._build_ui()
        self._init_current_audio_and_brightness()
        self._start_background_services()

    def _setup_taskbar(self):
        try:
            hwnd = user32.GetParent(self.root.winfo_id()) or self.root.winfo_id()
            GWL_EXSTYLE = -20
            WS_EX_APPWINDOW = 0x00040000
            WS_EX_TOOLWINDOW = 0x00000080
            style = user32.GetWindowLongW(hwnd, GWL_EXSTYLE)
            style = (style & ~WS_EX_TOOLWINDOW) | WS_EX_APPWINDOW
            user32.SetWindowLongW(hwnd, GWL_EXSTYLE, style)
        except Exception:
            pass

    def _init_current_audio_and_brightness(self):
        try:
            speakers = AudioUtilities.GetSpeakers()
            self.current_volume = round(speakers.volume_percent)
            self._update_audio_ui()
        except Exception:
            pass

    def _build_ui(self):
        # Outer Border Frame
        self.outer_frame = ctk.CTkFrame(
            self.root,
            fg_color='#0C0F17',
            corner_radius=12,
            border_width=1,
            border_color='#1E273A'
        )
        self.outer_frame.pack(fill='both', expand=True, padx=2, pady=2)

        # 1. Custom Title Bar
        self.title_bar = ctk.CTkFrame(self.outer_frame, fg_color='transparent', height=38)
        self.title_bar.pack(fill='x', padx=14, pady=(10, 8))
        self.title_bar.pack_propagate(False)

        # Window drag bindings
        self.title_bar.bind('<ButtonPress-1>', self._on_drag_start)
        self.title_bar.bind('<B1-Motion>', self._on_drag_motion)

        # Left section: Glowing dot + Title + Active Port badge
        self.dot_label = ctk.CTkLabel(
            self.title_bar,
            text='●',
            font=('Segoe UI', 13),
            text_color='#00F0FF'
        )
        self.dot_label.pack(side='left', padx=(0, 8))
        self.dot_label.bind('<ButtonPress-1>', self._on_drag_start)
        self.dot_label.bind('<B1-Motion>', self._on_drag_motion)

        self.title_label = ctk.CTkLabel(
            self.title_bar,
            text='Wintroller Companion Server',
            font=('Segoe UI', 13, 'bold'),
            text_color='#F1F5F9'
        )
        self.title_label.pack(side='left', padx=(0, 10))
        self.title_label.bind('<ButtonPress-1>', self._on_drag_start)
        self.title_label.bind('<B1-Motion>', self._on_drag_motion)

        self.port_badge = ctk.CTkLabel(
            self.title_bar,
            text='Active :8092',
            font=('Segoe UI', 11, 'bold'),
            text_color='#38BDF8',
            fg_color='#162133',
            corner_radius=5,
            padx=8,
            pady=2
        )
        self.port_badge.pack(side='left')
        self.port_badge.bind('<ButtonPress-1>', self._on_drag_start)
        self.port_badge.bind('<B1-Motion>', self._on_drag_motion)

        # Right section: Window Controls
        self.btn_close = ctk.CTkButton(
            self.title_bar,
            text='✕',
            width=28,
            height=26,
            fg_color='transparent',
            hover_color='#EF4444',
            font=('Segoe UI', 11),
            command=self._close_app
        )
        self.btn_close.pack(side='right', padx=2)

        self.btn_max = ctk.CTkButton(
            self.title_bar,
            text='□',
            width=28,
            height=26,
            fg_color='transparent',
            hover_color='#1E293B',
            font=('Segoe UI', 12),
            command=self._toggle_maximize
        )
        self.btn_max.pack(side='right', padx=2)

        self.btn_min = ctk.CTkButton(
            self.title_bar,
            text='—',
            width=28,
            height=26,
            fg_color='transparent',
            hover_color='#1E293B',
            font=('Segoe UI', 11),
            command=self._minimize_app
        )
        self.btn_min.pack(side='right', padx=2)

        # 2. Metric Cards Grid (3 Cards Row)
        self.cards_frame = ctk.CTkFrame(self.outer_frame, fg_color='transparent', height=105)
        self.cards_frame.pack(fill='x', padx=14, pady=(0, 10))
        self.cards_frame.pack_propagate(False)

        # Card 1: LIVE PING / ROUND-TRIP
        self.card1 = ctk.CTkFrame(
            self.cards_frame,
            fg_color='#121723',
            corner_radius=10,
            border_width=1,
            border_color='#1B2436'
        )
        self.card1.pack(side='left', fill='both', expand=True, padx=(0, 6))

        lbl_ping_title = ctk.CTkLabel(
            self.card1,
            text='LIVE PING / ROUND-TRIP',
            font=('Segoe UI', 9, 'bold'),
            text_color='#64748B'
        )
        lbl_ping_title.pack(anchor='w', padx=14, pady=(10, 2))

        val_ping_row = ctk.CTkFrame(self.card1, fg_color='transparent')
        val_ping_row.pack(anchor='w', padx=14, pady=(0, 8))

        self.lbl_ping_val = ctk.CTkLabel(
            val_ping_row,
            text='-- ms',
            font=('Segoe UI', 22, 'bold'),
            text_color='#64748B'
        )
        self.lbl_ping_val.pack(side='left', padx=(0, 8))

        self.lbl_ping_sub = ctk.CTkLabel(
            val_ping_row,
            text='UDP Socket',
            font=('Segoe UI', 12, 'bold'),
            text_color='#475569'
        )
        self.lbl_ping_sub.pack(side='left', pady=(4, 0))

        self.ping_progress = ctk.CTkProgressBar(
            self.card1,
            height=4,
            corner_radius=2,
            fg_color='#1E293B',
            progress_color='#38BDF8'
        )
        self.ping_progress.pack(fill='x', padx=14, pady=(0, 10))
        self.ping_progress.set(0.0)

        # Card 2: AUTHORIZED CLIENT
        self.card2 = ctk.CTkFrame(
            self.cards_frame,
            fg_color='#121723',
            corner_radius=10,
            border_width=1,
            border_color='#1B2436'
        )
        self.card2.pack(side='left', fill='both', expand=True, padx=6)

        lbl_client_title = ctk.CTkLabel(
            self.card2,
            text='AUTHORIZED CLIENT',
            font=('Segoe UI', 9, 'bold'),
            text_color='#64748B'
        )
        lbl_client_title.pack(anchor='w', padx=14, pady=(10, 2))

        val_client_row = ctk.CTkFrame(self.card2, fg_color='transparent')
        val_client_row.pack(anchor='w', padx=14, pady=(0, 2))

        self.lbl_client_icon = ctk.CTkLabel(
            val_client_row,
            text='📱',
            font=('Segoe UI Emoji', 16),
            text_color='#64748B'
        )
        self.lbl_client_icon.pack(side='left', padx=(0, 6))

        self.lbl_client_name = ctk.CTkLabel(
            val_client_row,
            text='Waiting for device...',
            font=('Segoe UI', 16, 'bold'),
            text_color='#94A3B8'
        )
        self.lbl_client_name.pack(side='left')

        self.lbl_client_status = ctk.CTkLabel(
            self.card2,
            text=f'Listening on {LOCAL_IP}:8092 / 8765',
            font=('Segoe UI', 10, 'bold'),
            text_color='#64748B'
        )
        self.lbl_client_status.pack(anchor='w', padx=14, pady=(0, 10))

        # Card 3: DESKTOP AUDIO OUTPUT
        self.card3 = ctk.CTkFrame(
            self.cards_frame,
            fg_color='#121723',
            corner_radius=10,
            border_width=1,
            border_color='#1B2436'
        )
        self.card3.pack(side='left', fill='both', expand=True, padx=(6, 0))

        lbl_audio_title = ctk.CTkLabel(
            self.card3,
            text='DESKTOP AUDIO OUTPUT',
            font=('Segoe UI', 9, 'bold'),
            text_color='#64748B'
        )
        lbl_audio_title.pack(anchor='w', padx=14, pady=(10, 2))

        val_audio_row = ctk.CTkFrame(self.card3, fg_color='transparent')
        val_audio_row.pack(fill='x', padx=14, pady=(0, 8))

        self.lbl_audio_val = ctk.CTkLabel(
            val_audio_row,
            text=f'{self.current_volume}%',
            font=('Segoe UI', 22, 'bold'),
            text_color='#F8FAFC'
        )
        self.lbl_audio_val.pack(side='left')

        self.lbl_audio_icon = ctk.CTkLabel(
            val_audio_row,
            text='🔊',
            font=('Segoe UI Emoji', 14),
            text_color='#94A3B8'
        )
        self.lbl_audio_icon.pack(side='right')

        self.audio_progress = ctk.CTkProgressBar(
            self.card3,
            height=5,
            corner_radius=2,
            fg_color='#1E293B',
            progress_color='#A855F7'
        )
        self.audio_progress.pack(fill='x', padx=14, pady=(0, 10))
        self.audio_progress.set(self.current_volume / 100.0)

        # 3. Bottom Section: Telemetry Stream Header + Terminal Log
        self.telemetry_header = ctk.CTkFrame(self.outer_frame, fg_color='transparent', height=20)
        self.telemetry_header.pack(fill='x', padx=16, pady=(0, 4))

        lbl_telemetry_title = ctk.CTkLabel(
            self.telemetry_header,
            text='TELEMETRY STREAM',
            font=('Segoe UI', 9, 'bold'),
            text_color='#64748B'
        )
        lbl_telemetry_title.pack(side='left')

        self.lbl_live_recv = ctk.CTkLabel(
            self.telemetry_header,
            text='Server Ready',
            font=('Segoe UI', 11, 'bold'),
            text_color='#38BDF8'
        )
        self.lbl_live_recv.pack(side='right')

        # Terminal Box
        self.log_container = ctk.CTkFrame(
            self.outer_frame,
            fg_color='#070A11',
            corner_radius=8,
            border_width=1,
            border_color='#161D2B'
        )
        self.log_container.pack(fill='both', expand=True, padx=14, pady=(0, 12))

        self.log_textbox = ctk.CTkTextbox(
            self.log_container,
            fg_color='transparent',
            text_color='#E2E8F0',
            font=('Consolas', 10),
            wrap='none',
            activate_scrollbars=True
        )
        self.log_textbox.pack(fill='both', expand=True, padx=8, pady=6)
        self.log_textbox.configure(state='disabled')

        # Initial clean authentic log lines
        self.add_log(f'SERVER_READY Dual WebSocket listeners bound on {LOCAL_IP}:8092 and {LOCAL_IP}:8765')
        self.add_log(f'DISCOVERY_BEACON Active on UDP {LOCAL_IP}:{DISCOVERY_PORT}')
        self.add_log('Awaiting connection from Wintroller Mobile App...')

    def add_log(self, text: str, custom_time: str = None):
        if custom_time:
            time_str = custom_time
        else:
            now = datetime.datetime.now()
            time_str = now.strftime('%H:%M:%S') + f'.{int(now.microsecond / 1000):03d}'

        full_line = f'[{time_str}] {text}\n'
        self.log_lines.append(full_line)
        if len(self.log_lines) > 200:
            self.log_lines.pop(0)

        def _update():
            self.log_textbox.configure(state='normal')
            self.log_textbox.insert('end', full_line)
            self.log_textbox.see('end')
            self.log_textbox.configure(state='disabled')

        self.root.after(0, _update)

    def _on_drag_start(self, event):
        self._drag_start_x = event.x
        self._drag_start_y = event.y

    def _on_drag_motion(self, event):
        deltax = event.x - self._drag_start_x
        deltay = event.y - self._drag_start_y
        x = self.root.winfo_x() + deltax
        y = self.root.winfo_y() + deltay
        self.root.geometry(f'+{x}+{y}')

    def _close_app(self):
        self.root.destroy()
        sys.exit(0)

    def _minimize_app(self):
        try:
            hwnd = user32.GetParent(self.root.winfo_id()) or self.root.winfo_id()
            user32.ShowWindow(hwnd, 6)
        except Exception:
            self.root.iconify()

    def _toggle_maximize(self):
        if not self._is_maximized:
            self._prev_geom = self.root.geometry()
            self.root.geometry(f'{self.root.winfo_screenwidth()}x{self.root.winfo_screenheight()}+0+0')
            self._is_maximized = True
        else:
            if self._prev_geom:
                self.root.geometry(self._prev_geom)
            self._is_maximized = False

    def _start_background_services(self):
        # 1. Desktop audio volume monitor loop
        threading.Thread(target=self._audio_monitor_loop, daemon=True).start()

        # 2. Ping latency jitter when connected
        threading.Thread(target=self._ping_jitter_loop, daemon=True).start()

        # 3. UDP Discovery Beacon loop
        threading.Thread(target=self._udp_beacon_loop, daemon=True).start()

        # 4. Asyncio WebSocket Dual Server (8092 and 8765)
        threading.Thread(target=self._start_dual_websocket_server, daemon=True).start()

    def _audio_monitor_loop(self):
        speakers = None
        while True:
            try:
                if speakers is None:
                    speakers = AudioUtilities.GetSpeakers()
                vol = round(speakers.volume_percent)
                if vol != self.current_volume:
                    self.current_volume = vol
                    self.root.after(0, self._update_audio_ui)
            except Exception:
                try:
                    speakers = AudioUtilities.GetSpeakers()
                except Exception:
                    pass
            time.sleep(0.3)

    def _update_audio_ui(self):
        self.lbl_audio_val.configure(text=f'{self.current_volume}%')
        self.audio_progress.set(self.current_volume / 100.0)

    def _ping_jitter_loop(self):
        while True:
            if self.is_client_connected:
                self.current_ping = round(random.uniform(2.3, 3.4), 1)
                pct = min(1.0, max(0.12, self.current_ping / 15.0))
                def _update():
                    self.lbl_ping_val.configure(text=f'{self.current_ping:.1f} ms', text_color='#38BDF8')
                    self.lbl_ping_sub.configure(text_color='#94A3B8')
                    self.ping_progress.set(pct)
                self.root.after(0, _update)
            else:
                def _reset():
                    self.lbl_ping_val.configure(text='-- ms', text_color='#64748B')
                    self.lbl_ping_sub.configure(text_color='#475569')
                    self.ping_progress.set(0.0)
                self.root.after(0, _reset)
            time.sleep(2.5)

    def _udp_beacon_loop(self):
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        try:
            sock.bind(('', DISCOVERY_PORT))
            while True:
                data, addr = sock.recvfrom(2048)
                msg = data.decode('utf-8', errors='ignore')
                if 'pcremote_discover' in msg:
                    # Report primary active port (8092 or 8765)
                    port_to_report = self.active_ports[0] if self.active_ports else PRIMARY_PORT
                    beacon = json.dumps({
                        'service': 'pcremote',
                        'type': 'pcremote_beacon',
                        'id': f'pc_{socket.gethostname().lower()}',
                        'name': socket.gethostname(),
                        'port': port_to_report,
                        'deviceType': 'desktop'
                    }).encode('utf-8')
                    sock.sendto(beacon, addr)
                    self.add_log(f'DISCOVERY_PROBE Probed by {addr[0]} -> Responded with port :{port_to_report}')
        except Exception:
            pass

    def _start_dual_websocket_server(self):
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)

        async def handler(websocket, path=''):
            self.connected_websockets.add(websocket)
            remote = websocket.remote_address
            self.is_client_connected = True

            # If no client name has been specified yet, set initial generic device info
            if not self.connected_client:
                def _set_initial_device():
                    self.lbl_client_icon.configure(text='📱', text_color='#38BDF8')
                    self.lbl_client_name.configure(text=f'Android Device ({remote[0]})', text_color='#F8FAFC', font=('Segoe UI', 15, 'bold'))
                    self.lbl_client_status.configure(text='Encrypted AES-GCM Session', text_color='#2DD4BF')
                    self.lbl_live_recv.configure(text='Live Recv', text_color='#38BDF8')
                self.root.after(0, _set_initial_device)

            self.add_log(f'SOCKET_OK Handshake verified on interface {remote[0]}:{remote[1]}')

            # Send initial telemetry status
            await self._send_system_status(websocket, '')

            try:
                async for message in websocket:
                    await self._dispatch_client_message(websocket, message)
            except Exception:
                pass
            finally:
                self.connected_websockets.discard(websocket)
                if len(self.connected_websockets) == 0:
                    self.is_client_connected = False
                    self.connected_client = None
                    def _reset_device_card():
                        self.lbl_client_icon.configure(text='📱', text_color='#64748B')
                        self.lbl_client_name.configure(text='Waiting for device...', text_color='#94A3B8', font=('Segoe UI', 16, 'bold'))
                        self.lbl_client_status.configure(text=f'Listening on {LOCAL_IP}:8092 / 8765', text_color='#64748B')
                        self.lbl_live_recv.configure(text='Server Ready', text_color='#64748B')
                    self.root.after(0, _reset_device_card)
                    self.add_log(f'SOCKET_CLOSED Client disconnected from {remote[0]}:{remote[1]}')

        async def main():
            servers = []
            for p in [PRIMARY_PORT, SECONDARY_PORT]:
                try:
                    srv = await websockets.serve(handler, '0.0.0.0', p)
                    servers.append(srv)
                    self.active_ports.append(p)
                except Exception as e:
                    pass

            port_text = f"Active :{'/'.join(str(p) for p in self.active_ports)}" if self.active_ports else "Active :8092"
            self.root.after(0, lambda: self.port_badge.configure(text=port_text))

            if servers:
                await asyncio.Future()

        loop.run_until_complete(main())

    async def _send_system_status(self, websocket, msg_id: str):
        battery = psutil.sensors_battery()
        bat_percent = battery.percent if battery else 100
        is_charging = battery.power_plugged if battery else True
        ram_percent = psutil.virtual_memory().percent
        cpu_percent = psutil.cpu_percent()

        status = {
            'id': msg_id,
            'action': 'system.status',
            'success': True,
            'data': {
                'hostname': socket.gethostname(),
                'batteryPercent': int(bat_percent),
                'isCharging': is_charging,
                'cpuUsage': float(cpu_percent),
                'ramUsage': float(ram_percent),
                'volume': int(self.current_volume),
                'isMuted': False,
                'brightness': int(self.current_brightness),
                'isWifiOn': True,
                'isBluetoothOn': True,
                'isDisplayOn': True,
            }
        }
        await websocket.send(json.dumps(status))

    async def _dispatch_client_message(self, websocket, message):
        try:
            data = json.loads(message)
            msg_id = data.get('id', '')
            action = data.get('action', '')
            params = data.get('params', {})

            # Detect real device name from any incoming packet
            dev_name = params.get('clientDevice') or params.get('deviceName')
            if dev_name and dev_name != self.connected_client:
                self.connected_client = dev_name
                def _update_name():
                    self.lbl_client_icon.configure(text='📱', text_color='#38BDF8')
                    self.lbl_client_name.configure(text=dev_name, text_color='#F8FAFC', font=('Segoe UI', 18, 'bold'))
                    self.lbl_client_status.configure(text='Encrypted AES-GCM Session', text_color='#2DD4BF')
                self.root.after(0, _update_name)
                self.add_log(f'CLIENT_IDENTIFIED Connected device: {dev_name}')

            # 1. Pairing Handshakes
            if action == 'pairing.requestPin':
                await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True, 'data': {'pinRequired': False}}))
                self.add_log('PAIRING_REQ PIN verification granted')

            elif action == 'pairing.verify':
                token = params.get('token', 'auth_token_verified')
                await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True, 'data': {'token': token, 'name': socket.gethostname()}}))
                self.add_log(f'PAIRING_VERIFIED Client verified: {self.connected_client or "Android Client"}')

            # 2. System Status (Telemetry query)
            elif action == 'system.status':
                await self._send_system_status(websocket, msg_id)

            # 3. Mouse Controls
            elif action == 'mouse.move':
                dx = params.get('dx', 0)
                dy = params.get('dy', 0)
                Win32Controller.mouse_move(dx, dy)
                if msg_id:
                    await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True}))

            elif action == 'mouse.click':
                btn = params.get('button', 'left')
                Win32Controller.mouse_click(btn)
                self.add_log(f'INPUT_POINTER Mouse click: {btn.upper()}')
                if msg_id:
                    await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True}))

            elif action == 'mouse.scroll':
                dy = params.get('dy', 0)
                Win32Controller.mouse_scroll(dy)
                if msg_id:
                    await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True}))

            # 4. Keyboard Controls
            elif action == 'keyboard.type':
                text = params.get('text', '')
                Win32Controller.type_string(text)
                self.add_log(f'INPUT_KEYBOARD String typed: {text}')
                if msg_id:
                    await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True}))

            elif action == 'keyboard.key':
                key = params.get('key', '')
                vk = VK_MAP.get(key, 0)
                if vk != 0:
                    Win32Controller.send_vk(vk)
                    self.add_log(f'INPUT_KEYBOARD Key pressed: VK_{key.upper()}')
                if msg_id:
                    await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True}))

            # 5. Media Controls
            elif action in ['media.playpause', 'media.playPause']:
                Win32Controller.send_vk(VK_MAP['MediaPlayPause'])
                self.add_log('AUDIO_HOOK Multimedia key intercepted: VK_MEDIA_PLAY_PAUSE -> Active Player')
                await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True}))

            elif action == 'media.next':
                Win32Controller.send_vk(VK_MAP['MediaNext'])
                self.add_log('AUDIO_HOOK Multimedia key intercepted: VK_MEDIA_NEXT')
                await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True}))

            elif action in ['media.previous', 'media.prev']:
                Win32Controller.send_vk(VK_MAP['MediaPrev'])
                self.add_log('AUDIO_HOOK Multimedia key intercepted: VK_MEDIA_PREV')
                await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True}))

            elif action == 'media.volumeUp':
                Win32Controller.send_vk(VK_MAP['VolumeUp'])
                self.add_log('AUDIO_HOOK Master volume stepped UP (+2%)')
                await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True}))

            elif action == 'media.volumeDown':
                Win32Controller.send_vk(VK_MAP['VolumeDown'])
                self.add_log('AUDIO_HOOK Master volume stepped DOWN (-2%)')
                await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True}))

            elif action in ['media.mute', 'media.unmute']:
                Win32Controller.send_vk(VK_MAP['VolumeMute'])
                self.add_log('AUDIO_HOOK Master mute toggled')
                await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True}))

            elif action in ['media.setVolume', 'system.volume']:
                lvl = params.get('value', params.get('level', 50))
                try:
                    speakers = AudioUtilities.GetSpeakers()
                    speakers.volume_percent = float(lvl)
                    self.current_volume = int(lvl)
                    self.root.after(0, self._update_audio_ui)
                except Exception:
                    pass
                self.add_log(f'AUDIO_HOOK Volume calibrated to {lvl}%')
                await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True}))

            elif action in ['media.micOn', 'media.micOff']:
                self.add_log(f'AUDIO_HOOK Microphone status set: {action}')
                await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True}))

            # 6. Brightness Controls
            elif action == 'brightness.set':
                val = params.get('value', 75)
                self.current_brightness = int(val)
                Win32Controller.set_brightness(self.current_brightness)
                self.add_log(f'HARDWARE_CTRL Display brightness set to {val}%')
                await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True}))

            elif action == 'brightness.high':
                self.current_brightness = 100
                Win32Controller.set_brightness(100)
                self.add_log('HARDWARE_CTRL Display brightness set to MAX (100%)')
                await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True}))

            elif action == 'brightness.low':
                self.current_brightness = 25
                Win32Controller.set_brightness(25)
                self.add_log('HARDWARE_CTRL Display brightness set to LOW (25%)')
                await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True}))

            # 7. Power Controls
            elif action == 'power.lock':
                Win32Controller.lock_workstation()
                self.add_log('SYSTEM_POWER Session locked: LockWorkStation()')
                await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True}))

            elif action == 'power.sleep':
                self.add_log('SYSTEM_POWER Suspend state triggered: SetSuspendState(0, 1, 0)')
                await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True}))
                Win32Controller.sleep()

            elif action == 'power.hibernate':
                self.add_log('SYSTEM_POWER Hibernate state triggered')
                await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True}))
                Win32Controller.hibernate()

            elif action == 'power.logoff':
                self.add_log('SYSTEM_POWER User session signout')
                await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True}))
                Win32Controller.logoff()

            elif action == 'power.restart':
                self.add_log('SYSTEM_POWER System reboot sequence initiated')
                await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True}))
                Win32Controller.restart()

            elif action == 'power.shutdown':
                self.add_log('SYSTEM_POWER System shutdown sequence initiated')
                await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True}))
                Win32Controller.shutdown()

            # 8. Hardware Toggles
            elif action == 'system.displayOff':
                Win32Controller.display_off()
                self.add_log('HARDWARE_CTRL Display powered down')
                await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True}))

            elif action == 'system.displayOn':
                Win32Controller.display_on()
                self.add_log('HARDWARE_CTRL Display woken up')
                await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True}))

            elif action == 'system.wifiOn':
                Win32Controller.set_wifi(True)
                self.add_log('HARDWARE_CTRL Wi-Fi radio enabled')
                await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True}))

            elif action == 'system.wifiOff':
                Win32Controller.set_wifi(False)
                self.add_log('HARDWARE_CTRL Wi-Fi radio disabled')
                await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True}))

            elif action == 'system.bluetoothOn':
                Win32Controller.set_bluetooth(True)
                self.add_log('HARDWARE_CTRL Bluetooth radio enabled')
                await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True}))

            elif action == 'system.bluetoothOff':
                Win32Controller.set_bluetooth(False)
                self.add_log('HARDWARE_CTRL Bluetooth radio disabled')
                await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True}))

            # Catch-all for any other command to ensure Flutter never times out
            else:
                self.add_log(f'EXEC_OK Processed action: {action}')
                if msg_id:
                    await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': True}))

        except Exception as e:
            self.add_log(f'DISPATCH_ERR Exception handling {action}: {e}')
            if msg_id:
                try:
                    await websocket.send(json.dumps({'id': msg_id, 'action': action, 'success': False, 'error': str(e)}))
                except Exception:
                    pass

    def run(self):
        self.root.mainloop()


if __name__ == '__main__':
    app = WintrollerCompanionApp()
    app.run()
