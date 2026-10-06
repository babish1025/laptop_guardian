"""
Laptop Guardian — Location Resolver for Windows Laptop Agent

Priority order:
1. Windows Location API via native .NET GeoCoordinateWatcher (High-accuracy Wi-Fi/GPS positioning)
2. Windows Runtime Geolocation API via winsdk/winrt (Secondary OS fallback)
3. Reverse geocoding (OpenStreetMap / BigDataCloud) to resolve actual place, district, & state
4. Network/IP-based approximate location fallback (only if OS location is disabled/unavailable)

Accuracy tiers:
- < 500 m  → Exact (GPS/Wi-Fi)
- 500 m – 5000 m → Moderate (Wi-Fi/Cell)
- > 5000 m  → Approximate (coarse cell/IP)
"""
import os
import sys
import logging
import subprocess
import json

log = logging.getLogger("laptop_guardian.agent")

_CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
_PS_SCRIPT = os.path.join(_CURRENT_DIR, "get_location.ps1")


# Accuracy threshold in metres — anything below this is considered "exact"
_EXACT_ACCURACY_THRESHOLD = 5000  # 5 km; coarser than this → approximate


def _apply_accuracy_label(loc: dict) -> dict:
    """Mark a location as approximate if the accuracy radius is too large."""
    acc = loc.get("accuracy")
    if acc is not None and acc >= _EXACT_ACCURACY_THRESHOLD:
        loc["is_approximate"] = True
        loc["source"] = "CELL"  # coarse cell-tower / network triangulation
        log.debug(f"Location accuracy {acc:.0f}m ≥ {_EXACT_ACCURACY_THRESHOLD}m — marked approximate.")
    return loc


def get_location() -> dict | None:
    """
    Try to get the laptop's exact location.
    Returns a dict with: latitude, longitude, accuracy, source,
    city, state, country, is_approximate
    Returns None if location cannot be determined.
    """
    # Attempt 1: Windows Location via native .NET GeoCoordinateWatcher
    loc = _try_windows_watcher_location()
    if loc:
        _apply_accuracy_label(loc)
        # Use immediately if accuracy is usable (any fix is better than IP)
        _enrich_with_reverse_geocode(loc)

    # Attempt 2: Windows Runtime Geolocation API (winsdk / winrt)
    winrt_loc = _try_winsdk_location()
    if winrt_loc:
        _apply_accuracy_label(winrt_loc)
        # Prefer the more accurate of the two OS fixes
        loc_acc = loc.get("accuracy") if loc else None
        winrt_acc = winrt_loc.get("accuracy")
        if loc is None or (
            winrt_acc is not None
            and (loc_acc is None or winrt_acc < loc_acc)
        ):
            _enrich_with_reverse_geocode(winrt_loc)
            loc = winrt_loc

    if loc:
        return loc

    # Attempt 3: IP geolocation fallback (approximate, city/ISP level only)
    ip_loc = _try_ip_geolocation()
    if ip_loc:
        return ip_loc

    log.warning("Location unavailable from all sources.")
    return None


# ---------------------------------------------------------------------------
# Tier 1: Windows .NET GeoCoordinateWatcher (High-Accuracy Wi-Fi Triangulation)
# ---------------------------------------------------------------------------

def _try_windows_watcher_location() -> dict | None:
    """
    Access Windows Location Services via native .NET GeoCoordinateWatcher.
    Uses get_location.ps1 to obtain high-accuracy position from Windows OS.
    """
    if not os.path.exists(_PS_SCRIPT):
        log.warning(f"Location PowerShell script not found at {_PS_SCRIPT}")
        return None

    try:
        proc = subprocess.run(
            ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", _PS_SCRIPT],
            capture_output=True,
            text=True,
            timeout=18,
        )
        out = proc.stdout.strip()
        if not out or out == "{}":
            return None

        data = json.loads(out)
        if data.get("Permission") == "Denied":
            log.warning("Windows Location permission is Denied in Windows Settings -> Privacy -> Location.")
            return None

        if data.get("Lat") is not None and data.get("Lon") is not None:
            lat = float(data["Lat"])
            lon = float(data["Lon"])
            acc = float(data["Acc"]) if data.get("Acc") is not None else None
            if (lat != 0.0 or lon != 0.0) and not (lat != lat or lon != lon):
                is_approx = (acc is None) or (acc >= _EXACT_ACCURACY_THRESHOLD)
                source = "GPS" if not is_approx else "CELL"
                log.info(f"Windows Location (.NET Watcher): lat={lat:.6f}, lon={lon:.6f}, acc={acc}m, approx={is_approx}")
                return {
                    "latitude":       lat,
                    "longitude":      lon,
                    "accuracy":       acc,
                    "source":         source,
                    "city":           None,
                    "state":          None,
                    "country":        None,
                    "is_approximate": is_approx,
                }
    except Exception as e:
        log.debug(f"Windows watcher location attempt failed: {e}")
    return None


# ---------------------------------------------------------------------------
# Tier 2: Windows Runtime Geolocation API (winsdk / winrt)
# ---------------------------------------------------------------------------

def _try_winsdk_location() -> dict | None:
    """Try Windows Location API via winsdk or winrt (Windows 10/11)."""
    wdg = None
    try:
        import winsdk.windows.devices.geolocation as wdg
    except ImportError:
        try:
            import winrt.windows.devices.geolocation as wdg
        except ImportError:
            return None

    try:
        import asyncio

        async def _get():
            locator = wdg.Geolocator()
            locator.desired_accuracy = wdg.PositionAccuracy.HIGH
            pos = await locator.get_geoposition_async()
            coord = pos.coordinate

            lat = getattr(coord, "latitude", None)
            lon = getattr(coord, "longitude", None)
            if (lat is None or lon is None) and hasattr(coord, "point"):
                lat = coord.point.position.latitude
                lon = coord.point.position.longitude

            acc = getattr(coord, "accuracy", None)
            if lat is not None and lon is not None:
                acc_f = float(acc) if acc is not None else None
                is_approx = (acc_f is None) or (acc_f >= _EXACT_ACCURACY_THRESHOLD)
                source = "GPS" if not is_approx else "CELL"
                return {
                    "latitude":       float(lat),
                    "longitude":      float(lon),
                    "accuracy":       acc_f,
                    "source":         source,
                    "city":           None,
                    "state":          None,
                    "country":        None,
                    "is_approximate": is_approx,
                }
            return None

        result = asyncio.run(_get())
        if result and (result["latitude"] != 0.0 or result["longitude"] != 0.0):
            log.info(f"Windows Location (WinRT): lat={result['latitude']:.6f}, lon={result['longitude']:.6f}, acc={result['accuracy']}m")
            return result
    except Exception as e:
        log.debug(f"WinRT Location attempt failed: {e}")
    return None


# ---------------------------------------------------------------------------
# Reverse Geocoding (Converts exact coordinates into actual City/District/State)
# ---------------------------------------------------------------------------

def _enrich_with_reverse_geocode(loc: dict) -> None:
    """Enrich coordinate dict with human-friendly locality details."""
    lat = loc.get("latitude")
    lon = loc.get("longitude")
    if not lat or not lon:
        return

    import requests

    # Service 1: OpenStreetMap Nominatim
    try:
        resp = requests.get(
            "https://nominatim.openstreetmap.org/reverse",
            params={"lat": lat, "lon": lon, "format": "json"},
            headers={"User-Agent": "LaptopGuardianAgent/2.0 (security-monitoring)"},
            timeout=5,
        )
        if resp.status_code == 200:
            data = resp.json()
            addr = data.get("address", {})

            city_part = (
                addr.get("amenity")
                or addr.get("suburb")
                or addr.get("village")
                or addr.get("town")
                or addr.get("city")
            )
            district = addr.get("state_district") or addr.get("county") or addr.get("city")
            if city_part and district and district.lower() not in city_part.lower():
                display_city = f"{city_part}, {district}"
            else:
                display_city = city_part or district

            loc["city"] = display_city or loc.get("city")
            loc["state"] = addr.get("state") or loc.get("state")
            loc["country"] = addr.get("country") or loc.get("country")
            log.info(f"Reverse geocode resolved: {loc['city']}, {loc['state']}, {loc['country']}")
            return
    except Exception as e:
        log.debug(f"Nominatim reverse geocode error: {e}")

    # Service 2: BigDataCloud Reverse Geocoding API (Fast fallback, free, no key)
    try:
        url = f"https://api.bigdatacloud.net/data/reverse-geocode-client?latitude={lat}&longitude={lon}&localityLanguage=en"
        resp = requests.get(url, timeout=5)
        if resp.status_code == 200:
            data = resp.json()
            city = data.get("locality") or data.get("city")
            district = data.get("localityInfo", {}).get("administrative", [{}])[-1].get("name") if data.get("localityInfo") else None
            state = data.get("principalSubdivision")
            country = data.get("countryName")
            if city and district and district.lower() not in city.lower():
                loc["city"] = f"{city}, {district}"
            elif city:
                loc["city"] = city
            elif district:
                loc["city"] = district

            if state:
                loc["state"] = state
            if country:
                loc["country"] = country
            log.info(f"BigDataCloud reverse geocode resolved: {loc.get('city')}, {loc.get('state')}, {loc.get('country')}")
    except Exception as e:
        log.debug(f"BigDataCloud reverse geocode error: {e}")


# ---------------------------------------------------------------------------
# Tier 3: IP Geolocation Fallback (Approximate, City/ISP level only)
# ---------------------------------------------------------------------------

def _try_ip_geolocation() -> dict | None:
    """Use ip-api.com for approximate IP-based geolocation when GPS/Wi-Fi is unavailable."""
    try:
        import requests
        resp = requests.get("http://ip-api.com/json/", timeout=8, params={
            "fields": "status,lat,lon,city,regionName,country,query"
        })
        data = resp.json()

        if data.get("status") != "success":
            log.warning(f"ip-api returned non-success: {data}")
            return None

        city    = data.get("city") or None
        state   = data.get("regionName") or None
        country = data.get("country") or None

        loc = {
            "latitude":       float(data["lat"]),
            "longitude":      float(data["lon"]),
            "accuracy":       None,
            "source":         "IP",
            "city":           city,
            "state":          state,
            "country":        country,
            "is_approximate": True,
        }
        log.info(f"IP Geolocation (approximate fallback): {city}, {state}, {country}")
        return loc

    except Exception as e:
        log.error(f"IP geolocation failed: {e}")
    return None


def format_location_label(loc: dict) -> str:
    """Format a human-readable label from location dict."""
    if not loc:
        return "Location unavailable"
    parts = [p for p in [loc.get("city"), loc.get("state"), loc.get("country")] if p]
    label = ", ".join(parts) if parts else f"{loc['latitude']:.4f}, {loc['longitude']:.4f}"

    acc = loc.get("accuracy")
    source = loc.get("source", "")

    if loc.get("is_approximate"):
        if source == "IP":
            label += " (Approximate - IP)"
        else:
            # Coarse OS fix — show accuracy radius so user knows it's imprecise
            if acc is not None:
                km = acc / 1000
                label += f" (Approximate - ±{km:.0f} km)"
            else:
                label += " (Approximate - Cell/Network)"
    elif source in ("GPS", "WIFI"):
        if acc is not None:
            label += f" (Exact - GPS/Wi-Fi ±{acc:.0f} m)"
        else:
            label += " (Exact - GPS/Wi-Fi)"
    return label
