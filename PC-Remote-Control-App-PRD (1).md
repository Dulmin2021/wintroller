# PC Remote Control — PRD, Stitch Screens & Antigravity Prompt

---

## 0. First: Do you need PC-side software too?

**Yes — you need a companion app/server running on the Windows PC.** This isn't optional, and it's the single most important architectural decision in this project. Here's why:

- Windows has **no built-in remote API** that a random Android app can call over the internet or LAN. Actions like shutdown, brightness, mouse movement, and keystroke injection require either:
  - **Win32 API calls** (`SetSuspendState`, `SetSystemPowerState`, `mouse_event`/`SendInput`, `WlanSetInterface`, WMI for brightness on laptops, `nircmd`/Core Audio API for mute/volume), or
  - **Local admin-level scripting** (PowerShell, `shutdown.exe`, `rundll32.exe powrprof.dll,SetSuspendState`, WMI queries).
- These can only be triggered from **code running on that PC** — there is no cloud service that can reach into a private Windows machine and do this. So the Android app needs something to talk to on the LAN (or over the internet via your own relay, later).
- This is exactly how existing tools like **Unified Remote**, **Mobile Mouse**, and **AnyDesk's quick-actions panel** work: a lightweight server/agent on the PC + a mobile client.

**So the real product is two apps:**
1. **Android app** (the one you're designing in Stitch) — the remote/client.
2. **Windows companion app** — a small background service/tray app that:
   - Listens on the LAN (WebSocket or raw TCP/UDP, e.g. via a local Python/Node/C# server) on a fixed port.
   - Authenticates the phone (pairing via QR code or 6-digit PIN shown on the PC, plus a saved token afterward).
   - Executes the actual OS commands when it receives a command from the phone.
   - Optionally runs a small system-tray icon so the user can see connection status, revoke devices, and start/stop the service.

**Recommended stack for the PC side** (updated for your choice of Flutter for the Android app):
- **Option A — Flutter for both sides (recommended given your choice):** Flutter has stable **Windows desktop app support**, so the companion app can be a second Flutter app (Dart) — a system-tray-style Windows app using packages like `tray_manager`/`window_manager`, with `win32` (Dart FFI bindings to the Win32 API) for the actual OS actions (shutdown/lock/brightness/volume/mouse-keyboard injection), and `web_socket_channel` or `shelf` for the local server. This lets you reuse Dart knowledge, share model/protocol code (the JSON command schema) between both apps via a shared Dart package, and avoid context-switching languages.
- **Option B — C# (.NET, WPF/WinForms + WebSocket server)** — still the deepest native Win32 access and the most mature tray-app patterns, if you'd rather keep the PC side native and only use Flutter for the phone.
- Communication either way: **WebSocket over LAN** (mDNS/Bonjour or a simple broadcast-and-discover step so the phone can auto-find the PC on the same Wi-Fi), with a pairing token stored after first pairing. For remote access outside the LAN, that's a v2 feature (would need a relay server or Tailscale-style VPN — don't design for this in v1).

Below is the full plan assuming this two-app architecture.

---

## 1. Product Requirements Document (PRD)

### 1.1 Product name (placeholder)
**PCRemote** *(swap in your own name/branding later)*

### 1.2 Problem statement
Users often want to control their Windows PC from across the room — pausing media, adjusting volume, locking the screen before leaving the desk, browsing files, or using their phone as a wireless mouse/keyboard — without buying dedicated hardware or juggling multiple single-purpose remote apps.

### 1.3 Goals
- One Android app that replaces the need for separate remote-mouse, remote-keyboard, media-remote, and power-control apps.
- Fast local pairing (LAN-only for v1) with low latency for mouse/keyboard input.
- Simple, glanceable UI — most actions are single-tap.
- Secure by default: no unauthenticated device can control the PC.

### 1.4 Non-goals (v1)
- Remote access over the internet (outside local Wi-Fi).
- Multi-PC simultaneous control (v1 = one paired PC at a time, switchable).
- iOS app (Android only per your ask).
- Screen mirroring / full remote desktop (this is control-only, not screen-viewing — that's a much bigger scope, akin to rebuilding AnyDesk).

### 1.5 Target users
Students/professionals with a Windows laptop/desktop who use their phone as a second-screen utility — presenters, people who use their PC as a media/HTPC box, and power users who want quick system actions without walking to the keyboard.

### 1.6 Core feature set

| Module | Actions |
|---|---|
| **Power Control** | Shutdown, Restart, Sleep, Hibernate, Log off, Lock screen |
| **Media Control** | Play/Pause, Next/Previous track, Volume Up/Down, Mute/Unmute, Mic On/Off |
| **Brightness Control** | Increase, Decrease, preset High/Low, (stretch: slider for exact %) |
| **File Manager** | Browse PC drives/folders, view file list, download file to phone, upload/push file to PC, delete/rename (stretch), search |
| **Mouse Control** | Touchpad-style trackpad (drag to move cursor), left/right click, scroll gesture |
| **Keyboard Control** | Full soft keyboard input typed on phone sent as keystrokes to PC, plus quick-access keys (Esc, Tab, Win, Alt+Tab, arrow keys, media keys) |
| **Pairing / Device Management** | QR/PIN pairing, list of paired PCs, connection status, rename PC, forget device |
| **Settings** | Theme, connection timeout, vibration/haptics on tap, auto-reconnect, notification permissions |

### 1.7 Key user flows
1. **First-time pairing**: Install PC companion app → it shows a QR code/PIN → open Android app → scan QR or enter PIN → paired, saved for future auto-connect on same Wi-Fi.
2. **Daily use**: Open app → auto-connects to last-used PC (or shows "PC offline" state) → land on Home/Dashboard with quick-action tiles → tap into Mouse/Keyboard/Files/Media/Power as needed.
3. **Power action**: Tap Power tile → confirmation sheet for destructive actions (Shutdown/Restart/Log off require a confirm tap; Lock/Sleep don't).
4. **File transfer**: Open File Manager → browse PC folders → tap file → Download to phone, or tap "+" → Upload from phone to PC.

### 1.8 Non-functional requirements
- **Latency**: Mouse/keyboard input round-trip under ~50ms on local Wi-Fi.
- **Security**: Pairing token stored encrypted (Android Keystore); PC companion app requires the user to explicitly approve first pairing (no silent auto-accept).
- **Reliability**: Auto-reconnect if Wi-Fi drops briefly; clear "PC Offline" state otherwise.
- **Platform**: Android 8.0+ (API 26+), phone and tablet layouts.

### 1.9 Success metrics (if shipped publicly later)
- Pairing completion rate, daily reconnect success rate, session length for Mouse/Keyboard mode, crash-free sessions.

---

## 2. Google Stitch — Screens to Design

Design these as a single Stitch project/flow so navigation stays consistent. Suggested screen list, in build order:

1. **Splash / Onboarding (3 slides)** — App purpose, "what you can control", permission primer (network access).
2. **Pairing — Discover PC** — Scanning animation, "Looking for PCs on your Wi-Fi", list of found PCs, manual "Enter PIN" fallback button, QR scan button.
3. **Pairing — QR Scan** — Camera viewfinder overlay with scan frame, manual PIN entry link.
4. **Pairing — Enter PIN** — 6-digit PIN input, "Pairing..." loading state.
5. **Pairing Success** — Checkmark confirmation, PC name/icon, "Continue" CTA.
6. **Home / Dashboard** — Connected PC status card (name, battery if laptop, connection strength), grid of quick-action tiles (Power, Mouse, Keyboard, Media, Files, Brightness), bottom nav or FAB for switching PCs.
7. **Power Control Sheet/Screen** — Icon buttons for Shutdown, Restart, Sleep, Hibernate, Log off, Lock — with a confirmation modal variant for destructive actions.
8. **Media Control Screen** — Large Play/Pause button, Previous/Next, volume slider + mute toggle, mic on/off toggle, now-playing info (optional, if reading PC media session).
9. **Brightness Control Screen** — Slider + High/Low quick presets, live preview value.
10. **Mouse / Trackpad Screen** — Full-screen touchpad surface, left-click/right-click zones or buttons at bottom, two-finger-scroll hint, sensitivity settings icon.
11. **Keyboard Control Screen** — Text input field feeding keystrokes live, quick-key row (Esc, Tab, Win, Ctrl, Alt, Del, Arrow keys), toggle for "send as you type" vs "send on submit."
12. **File Manager — Browser View** — Breadcrumb path, folder/file list with icons and size/date, search bar, FAB for upload.
13. **File Manager — File Detail / Actions Sheet** — File preview icon, Download / Delete / Rename / Share actions.
14. **File Transfer Progress** — Upload/download progress bar, cancel action.
15. **Device Management Screen** — List of paired PCs, connection status per PC, "Forget device" swipe action, "Add new PC" button.
16. **Settings Screen** — Theme (light/dark/system), haptics toggle, auto-reconnect toggle, about/version, disconnect current PC.
17. **PC Offline / Error State** — Friendly illustration, "Can't reach [PC name]", Retry button, "Switch PC" link.

**Design direction notes for Stitch:**
- Keep it utility-first: high contrast, large tap targets (this app gets used one-handed, often glanced at quickly).
- Use a consistent icon set for the 6 module tiles (Power, Mouse, Keyboard, Media, Files, Brightness) — they should be instantly recognizable from the Home grid.
- Mouse/Keyboard screens should be near-fullscreen with minimal chrome — these are "gesture surfaces," not content screens.
- Use a persistent small "connected to [PC name]" indicator across all main screens so the user always knows what they're controlling.

---

## 3. Google Antigravity — Build Prompt

Paste this into Antigravity as your project brief:

```
Build a Flutter app called "PCRemote" — a remote control app for Windows PCs/laptops over the local network.

ARCHITECTURE:
- Flutter client app (Dart, Material 3) targeting Android, that connects to a
  Windows companion app over a local WebSocket connection.
- Assume a Windows companion service already exists (or scaffold a minimal
  Flutter Windows-desktop app as a separate module, using the `win32` package
  for OS actions and `shelf`/`web_socket_channel` for the local server)
  exposing these commands as JSON messages: power.shutdown, power.restart,
  power.sleep, power.hibernate, power.logoff, power.lock, media.playpause,
  media.next, media.previous, media.volumeUp, media.volumeDown, media.mute,
  media.unmute, media.micOn, media.micOff, brightness.set(value),
  brightness.high, brightness.low, mouse.move(dx,dy), mouse.click(button),
  mouse.scroll(dy), keyboard.type(text), keyboard.key(keycode),
  files.list(path), files.download(path), files.upload(path, data),
  pairing.requestPin, pairing.verify(pin/qr).

FEATURES TO IMPLEMENT:
1. Pairing flow: discover PCs on LAN (multicast_dns / bonsoir package for
   mDNS discovery), QR code scan (mobile_scanner package), and manual PIN
   entry fallback. Store the paired PC's IP + auth token securely
   (flutter_secure_storage).
2. Home dashboard: connection status card + a grid of 6 module tiles
   (Power, Mouse, Keyboard, Media, Files, Brightness) using Material 3
   widgets (Card, GridView).
3. Power control screen: buttons for Shutdown, Restart, Sleep, Hibernate,
   Log off, Lock — with an AlertDialog confirmation for Shutdown/Restart/Log off.
4. Media control screen: play/pause, next/prev, volume up/down as a Slider,
   mute/unmute toggle, mic on/off toggle — send commands over the WebSocket
   with debounced repeated calls for volume up/down while held.
5. Brightness control screen: Slider (0-100) plus Low/High preset buttons.
6. Mouse trackpad screen: a full-screen surface using GestureDetector
   (onPanUpdate) to capture drag gestures and translate relative deltas into
   mouse.move(dx,dy) calls sent at ~60Hz max, tap = left click, two-finger
   tap = right click, two-finger drag = scroll.
7. Keyboard control screen: a hidden TextField capturing input via the
   system IME (RawKeyboardListener/TextField with autofocus), sending each
   character/keystroke live to keyboard.type/keyboard.key, plus a
   quick-access row of buttons for Esc, Tab, Win, Ctrl, Alt, Del, and
   arrow keys.
8. File manager screen: list files/folders from files.list(path) with
   breadcrumb navigation, tap-to-download, FAB to upload from the phone's
   storage (file_picker package), show transfer progress with a
   LinearProgressIndicator bound to a stream of progress events.
9. Device management screen: list of paired PCs with connection status,
   swipe-to-forget (Dismissible), add-new-PC entry point back into the
   pairing flow.
10. Settings screen: theme (light/dark/system via shared_preferences or
    Provider), haptics toggle, auto-reconnect toggle.
11. Robust connection layer: a single WebSocketService (web_socket_channel)
    with auto-reconnect/backoff, a ConnectionState exposed via Provider/
    Riverpod (Connected/Connecting/Offline), and a repository layer
    abstracting all the JSON commands above into typed Dart methods.

TECH STACK:
- Flutter (Dart), Material 3
- web_socket_channel for WebSocket networking
- mobile_scanner for QR pairing, bonsoir/multicast_dns for LAN discovery
- flutter_secure_storage for pairing tokens, shared_preferences for settings
- Riverpod or Provider for state management, one controller/notifier per
  screen listed above
- file_picker for uploads, path_provider for downloads

NON-FUNCTIONAL:
- Target minSdk 26, compileSdk latest stable
- Handle "PC offline" gracefully everywhere (empty/error states, retry actions)
- Confirm destructive actions (Shutdown/Restart/Log off) before sending
- Keep the Mouse and Keyboard screens near-fullscreen with minimal chrome
  for a responsive gesture-first feel

Use the attached Stitch screen designs (Splash/Onboarding, Pairing—Discover,
Pairing—QR Scan, Pairing—PIN, Pairing Success, Home/Dashboard, Power
Control, Media Control, Brightness Control, Mouse/Trackpad, Keyboard
Control, File Manager Browser, File Detail Sheet, Transfer Progress,
Device Management, Settings, PC Offline state) as the exact UI reference —
match layout, spacing, and component styling from those screens.
```

---

## 4. Suggested build order
1. Companion Windows app first (even a bare-bones version) — you need something to test against.
2. WebSocket connection layer + pairing flow in the Android app.
3. Power + Media + Brightness (simplest, single-command actions) to validate the pipe end-to-end.
4. Mouse + Keyboard (latency-sensitive, needs the most testing).
5. File Manager last (most complex: transfer progress, SAF integration, larger payloads).
