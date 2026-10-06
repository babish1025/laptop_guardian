"""
Laptop Guardian — Command Executor
Executes SHUTDOWN, RESTART, LOCK, ALARM, SLEEP, PHOTO, SCREENSHOT, and LOCATION commands.
Reports results and activity back to the backend.
"""
import os
import logging
import subprocess
import requests
import threading

log = logging.getLogger("laptop_guardian.agent")


def execute_command(
    cmd: dict,
    backend_url: str,
    device_id: str,
    device_token: str,
    event_reporter,        # callable: report_event(...)
    location: dict = None,
) -> None:
    """
    Execute a command dict from the backend.
    cmd = {"id": int, "command": str, "created_at": str, "expires_at": str}
    """
    cmd_id   = cmd.get("id")
    command  = (cmd.get("command") or "").upper()
    log.info(f"Executing command: {command} (ID {cmd_id})")

    success = False
    result_text = ""

    try:
        if command == "LOCK":
            _lock_windows()
            success = True
            result_text = "Windows session locked."
            event_reporter("LOCK", "Remote lock executed.", location)

        elif command == "ALARM":
            _play_alarm()
            success = True
            result_text = "Audible alarm played on laptop speakers."
            event_reporter("ALARM", result_text, location)

        elif command in ("PHOTO", "WEBCAM"):
            try:
                rel_url = _capture_webcam()
                success = True
                result_text = f"Webcam photo captured: {rel_url}"
                event_reporter("PHOTO", result_text, location)
            except Exception as e:
                success = False
                result_text = f"Webcam capture failed: {e}"
                log.error(result_text)

        elif command == "SCREENSHOT":
            try:
                rel_url = _capture_screenshot()
                success = True
                result_text = f"Desktop screenshot captured: {rel_url}"
                event_reporter("SCREENSHOT", result_text, location)
            except Exception as e:
                success = False
                result_text = f"Screenshot capture failed: {e}"
                log.error(result_text)

        elif command == "LOCATION":
            loc_label = _refresh_location(backend_url, device_id, device_token)
            success = True
            result_text = f"Location refreshed: {loc_label}"
            event_reporter("LOCATION", result_text, location)

        elif command == "SLEEP":
            event_reporter("SLEEP", "Remote sleep initiated.", location)
            _report_result(backend_url, device_id, device_token, cmd_id,
                           "EXECUTED", "Laptop entered sleep mode.")
            _sleep_windows()
            return

        elif command == "SHUTDOWN":
            event_reporter("SHUTDOWN", "Remote shutdown initiated.", location)
            _shutdown_windows()
            success = True
            result_text = "Shutdown command issued."

        elif command == "RESTART":
            event_reporter("RESTART", "Remote restart initiated.", location)
            _restart_windows()
            success = True
            result_text = "Restart command issued."

        else:
            result_text = f"Unknown command: {command}"
            log.warning(result_text)

    except Exception as e:
        result_text = f"Execution error: {e}"
        log.error(result_text)

    # Report result to backend
    _report_result(backend_url, device_id, device_token, cmd_id,
                   "EXECUTED" if success else "FAILED", result_text)


def _lock_windows():
    """Lock the Windows session using ctypes."""
    import ctypes
    log.info("Locking Windows session...")
    ctypes.windll.user32.LockWorkStation()


def _shutdown_windows():
    """Issue Windows shutdown command (5s delay)."""
    log.info("Issuing Windows shutdown...")
    subprocess.run(["shutdown", "/s", "/t", "5", "/c", "Remote shutdown by Laptop Guardian"], check=False)


def _restart_windows():
    """Issue Windows restart command."""
    log.info("Issuing Windows restart...")
    subprocess.run(["shutdown", "/r", "/t", "5", "/c", "Remote restart by Laptop Guardian"], check=False)


def _sleep_windows():
    """Put Windows into sleep/suspend mode."""
    import ctypes
    log.info("Putting Windows to sleep...")
    ctypes.windll.PowrProf.SetSuspendState(0, 1, 0)


def _play_alarm():
    """Play loud alert tone on speakers in a background thread."""
    import winsound
    import time

    def _siren():
        log.info("Sounding audible alarm on speakers...")
        for _ in range(6):
            for freq in (2200, 1750, 2500, 1500):
                try:
                    winsound.Beep(freq, 220)
                except Exception:
                    pass
            time.sleep(0.05)

    threading.Thread(target=_siren, daemon=True).start()


def _get_captures_dir() -> str:
    """Ensure and return the static captures directory path."""
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    captures_dir = os.path.join(project_root, "frontend", "static", "captures")
    os.makedirs(captures_dir, exist_ok=True)
    return captures_dir


def _capture_webcam() -> str:
    """Capture a photo from webcam using OpenCV with multiple backend probes and clear diagnostics."""
    import cv2
    import datetime

    captures_dir = _get_captures_dir()
    cam = None

    # Probe backends and indices:
    # CAP_DSHOW: DirectShow (standard for Windows USB webcams)
    # CAP_MSMF: Media Foundation (standard for Windows 10/11 internal webcams)
    # CAP_ANY: Default auto-detect
    backends = [cv2.CAP_DSHOW, cv2.CAP_MSMF, cv2.CAP_ANY]
    indices = [0, 1, 2]

    for backend in backends:
        for idx in indices:
            try:
                c = cv2.VideoCapture(idx, backend)
                if c is not None and c.isOpened():
                    # Attempt reading a test frame
                    ret, test_frame = c.read()
                    if ret and test_frame is not None and test_frame.size > 0:
                        cam = c
                        break
                    else:
                        c.release()
            except Exception:
                pass
        if cam is not None:
            break

    if not cam or not cam.isOpened():
        # Check PnP status to provide actionable diagnosis
        msg = "Webcam not detected or unavailable."
        try:
            import subprocess
            out = subprocess.check_output(
                ["powershell", "-NoProfile", "-Command",
                 "Get-PnpDevice -Class Camera -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Problem"],
                creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0
            ).decode("utf-8", errors="ignore").strip()
            if "CM_PROB_PHANTOM" in out or "45" in out:
                msg = (
                    "Webcam hardware is turned OFF. "
                    "On Acer/laptop keyboards, press the Camera toggle key (Fn + F10 or Fn + F6) "
                    "or check the physical privacy shutter slider."
                )
        except Exception:
            pass
        raise RuntimeError(msg)

    try:
        # Flush camera buffer and let auto-exposure adjust
        frame = None
        for _ in range(5):
            ret, frame = cam.read()
        if frame is None:
            raise RuntimeError("Could not capture frame from webcam.")

        ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"webcam_{ts}.jpg"
        filepath = os.path.join(captures_dir, filename)
        cv2.imwrite(filepath, frame)
        log.info(f"Webcam photo saved: {filepath}")
        return f"/static/captures/{filename}"
    finally:
        cam.release()


def _capture_screenshot() -> str:
    """Capture a screenshot of current desktop with robust GDI BitBlt and Pillow fallback."""
    import datetime
    from PIL import Image

    captures_dir = _get_captures_dir()
    ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"screenshot_{ts}.jpg"
    filepath = os.path.join(captures_dir, filename)

    img = None

    # Method 1: Windows GDI BitBlt via ctypes (works with any DPI scaling, multi-monitor, high-DPI Windows 11)
    try:
        import ctypes
        from ctypes import wintypes

        user32 = ctypes.windll.user32
        gdi32 = ctypes.windll.gdi32

        try:
            user32.SetProcessDPIAware()
        except Exception:
            pass

        # Virtual screen metrics (spans all monitors or single display)
        x = user32.GetSystemMetrics(76)  # SM_XVIRTUALSCREEN
        y = user32.GetSystemMetrics(77)  # SM_YVIRTUALSCREEN
        w = user32.GetSystemMetrics(78)  # SM_CXVIRTUALSCREEN
        h = user32.GetSystemMetrics(79)  # SM_CYVIRTUALSCREEN

        if w <= 0 or h <= 0:
            w = user32.GetSystemMetrics(0)  # SM_CXSCREEN
            h = user32.GetSystemMetrics(1)  # SM_CYSCREEN
            x, y = 0, 0

        hdesktop = user32.GetDesktopWindow()
        desktop_dc = user32.GetWindowDC(hdesktop)
        mem_dc = gdi32.CreateCompatibleDC(desktop_dc)
        bitmap = gdi32.CreateCompatibleBitmap(desktop_dc, w, h)
        old_bitmap = gdi32.SelectObject(mem_dc, bitmap)

        # 0x00CC0020 = SRCCOPY, 0x40000000 = CAPTUREBLT (includes layered windows)
        gdi32.BitBlt(mem_dc, 0, 0, w, h, desktop_dc, x, y, 0x00CC0020 | 0x40000000)

        class BITMAPINFOHEADER(ctypes.Structure):
            _fields_ = [
                ('biSize', wintypes.DWORD),
                ('biWidth', wintypes.LONG),
                ('biHeight', wintypes.LONG),
                ('biPlanes', wintypes.WORD),
                ('biBitCount', wintypes.WORD),
                ('biCompression', wintypes.DWORD),
                ('biSizeImage', wintypes.DWORD),
                ('biXPelsPerMeter', wintypes.LONG),
                ('biYPelsPerMeter', wintypes.LONG),
                ('biClrUsed', wintypes.DWORD),
                ('biClrImportant', wintypes.DWORD)
            ]

        bmi = BITMAPINFOHEADER()
        bmi.biSize = ctypes.sizeof(BITMAPINFOHEADER)
        bmi.biWidth = w
        bmi.biHeight = -h  # top-down DIB
        bmi.biPlanes = 1
        bmi.biBitCount = 32
        bmi.biCompression = 0

        buf = ctypes.create_string_buffer(w * h * 4)
        gdi32.GetDIBits(mem_dc, bitmap, 0, h, buf, ctypes.byref(bmi), 0)

        gdi32.SelectObject(mem_dc, old_bitmap)
        gdi32.DeleteObject(bitmap)
        gdi32.DeleteDC(mem_dc)
        user32.ReleaseDC(hdesktop, desktop_dc)

        img = Image.frombuffer('RGBA', (w, h), buf, 'raw', 'BGRA', 0, 1).convert('RGB')
    except Exception as gdi_err:
        log.warning(f"GDI screenshot failed: {gdi_err}, falling back to ImageGrab")

    # Method 2: Pillow ImageGrab fallback
    if img is None:
        from PIL import ImageGrab
        img = ImageGrab.grab(all_screens=True)

    img.save(filepath, "JPEG", quality=85)
    log.info(f"Screenshot saved: {filepath}")
    return f"/static/captures/{filename}"


def _refresh_location(backend_url: str, device_id: str, device_token: str) -> str:
    """Acquire fresh location and post to backend immediately."""
    from laptop_agent.location import get_location, format_location_label
    log.info("Refreshing location on demand...")
    loc = get_location()
    if loc:
        payload = {
            "device_id": device_id,
            "device_token": device_token,
            "latitude": loc.get("latitude"),
            "longitude": loc.get("longitude"),
            "accuracy": loc.get("accuracy"),
            "source": loc.get("source", "IP"),
            "city": loc.get("city"),
            "state": loc.get("state") or loc.get("region"),
            "country": loc.get("country"),
            "is_approximate": loc.get("is_approximate", True),
        }
        try:
            requests.post(f"{backend_url}/api/location", json=payload, timeout=10)
        except Exception as e:
            log.warning(f"Failed to post refreshed location: {e}")
        return format_location_label(loc)
    return "Unable to determine location."


def _report_result(backend_url, device_id, device_token, cmd_id, status, result_text):
    """POST command result back to backend."""
    try:
        payload = {
            "device_id":    device_id,
            "device_token": device_token,
            "status":       status,
            "result":       result_text,
        }
        resp = requests.post(
            f"{backend_url}/api/commands/{cmd_id}/result",
            json=payload,
            timeout=8,
        )
        if resp.status_code == 200:
            log.info(f"Command {cmd_id} result reported: {status}")
        else:
            log.warning(f"Failed to report command result: {resp.text[:200]}")
    except Exception as e:
        log.error(f"Result report error: {e}")
