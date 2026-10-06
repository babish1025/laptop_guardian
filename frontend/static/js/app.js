/**
 * Laptop Guardian — Dashboard Client JavaScript
 * Manages device status polling, remote commands, notifications, and location display.
 */

let currentDeviceId = null;
let currentDevice = null;
let pendingAction = null;
let statusTimer = null;
let activityTimer = null;
let notifTimer = null;
let mapCoordinates = null;

// ============================================================
// Initialization & Error Display
// ============================================================
document.addEventListener('DOMContentLoaded', init);

function showErrorScreen(title, message, showLogin = true) {
  const loadingScreen = document.getElementById('loading-screen');
  const noDevice = document.getElementById('no-device');
  const dashboard = document.getElementById('device-dashboard');

  if (dashboard) dashboard.classList.add('hidden');
  if (noDevice) noDevice.classList.add('hidden');

  if (loadingScreen) {
    loadingScreen.classList.remove('hidden');
    loadingScreen.innerHTML = `
      <div style="text-align:center;padding:2rem;max-width:360px;margin:0 auto">
        <div style="font-size:2.8rem;margin-bottom:1rem">🔌</div>
        <h3 style="color:#f1f5f9;margin-bottom:0.6rem;font-size:1.15rem;font-weight:600">${escapeHtml(title)}</h3>
        <p style="color:#94a3b8;font-size:0.875rem;line-height:1.5;margin-bottom:1.5rem">${escapeHtml(message)}</p>
        <div style="display:flex;gap:10px;justify-content:center;flex-wrap:wrap">
          <button onclick="location.reload()" style="background:#6c63ff;border:none;color:#fff;padding:0.65rem 1.6rem;border-radius:8px;cursor:pointer;font-weight:600;font-size:0.9rem">Retry</button>
          ${showLogin ? '<a href="/login" style="display:inline-block;background:rgba(255,255,255,0.08);border:1px solid rgba(255,255,255,0.12);color:#cbd5e1;padding:0.65rem 1.4rem;border-radius:8px;text-decoration:none;font-size:0.9rem;font-weight:500">Sign In</a>' : ''}
        </div>
      </div>
    `;
  }
}

async function init() {
  // Safety timeout — if loading takes > 8 seconds, show fallback
  const loadingFallbackTimer = setTimeout(() => {
    const ls = document.getElementById('loading-screen');
    if (ls && !ls.classList.contains('hidden')) {
      showErrorScreen('Server Unreachable', 'The server is taking too long to respond. Make sure the backend service is running and retry.', true);
    }
  }, 8000);

  try {
    // 1. Verify session — safely parse JSON
    let authData;
    try {
      const authRes = await fetch('/api/auth/me', { credentials: 'include' });
      if (authRes.status === 401) {
        clearTimeout(loadingFallbackTimer);
        window.location.href = '/login';
        return;
      }

      const contentType = authRes.headers.get('content-type') || '';
      if (!contentType.includes('application/json')) {
        clearTimeout(loadingFallbackTimer);
        window.location.href = '/login';
        return;
      }

      authData = await authRes.json();
    } catch (fetchErr) {
      clearTimeout(loadingFallbackTimer);
      showErrorScreen('Connection Failed', 'Could not connect to the Laptop Guardian server. Please verify the backend is running.', true);
      return;
    }

    if (!authData || !authData.success) {
      clearTimeout(loadingFallbackTimer);
      window.location.href = '/login';
      return;
    }

    // 2. Fetch user devices
    let devData;
    try {
      const devRes = await fetch('/api/devices', { credentials: 'include' });
      if (devRes.status === 401) {
        clearTimeout(loadingFallbackTimer);
        window.location.href = '/login';
        return;
      }

      devData = await devRes.json();
      if (!devRes.ok || !devData.success) {
        clearTimeout(loadingFallbackTimer);
        showErrorScreen('Dashboard Error', devData.error || 'Failed to load device information from database.', false);
        return;
      }
    } catch (err) {
      clearTimeout(loadingFallbackTimer);
      showErrorScreen('Network Error', 'Failed to retrieve device details from the server.', false);
      return;
    }

    clearTimeout(loadingFallbackTimer);
    const loadingScreen = document.getElementById('loading-screen');
    if (loadingScreen) loadingScreen.classList.add('hidden');

    const devices = devData.devices || [];
    if (devices.length === 0) {
      document.getElementById('no-device')?.classList.remove('hidden');
      return;
    }

    document.getElementById('device-dashboard')?.classList.remove('hidden');
    // Select the first device
    currentDeviceId = devices[0].device_id;
    currentDevice = devices[0];

    // Initial load — isolate each call so one failure cannot blank the page
    await Promise.allSettled([
      loadDeviceStatus(),
      loadRecentActivity(),
      loadNotifications()
    ]);

    // Start polling intervals
    statusTimer = setInterval(loadDeviceStatus, 4000);
    activityTimer = setInterval(loadRecentActivity, 8000);
    notifTimer = setInterval(loadNotifications, 10000);

  } catch (err) {
    clearTimeout(loadingFallbackTimer);
    console.error('Initialization error:', err);
    showErrorScreen('Unexpected Error', err.message || 'An unexpected error occurred while loading the dashboard.', false);
  }
}

// ============================================================
// Device Status & Location
// ============================================================
async function loadDeviceStatus() {
  if (!currentDeviceId) return;

  try {
    const res = await fetch(`/api/devices/${currentDeviceId}/status`, { credentials: 'include' });
    if (res.status === 401) {
      window.location.href = '/login';
      return;
    }
    const data = await res.json();
    if (!data.success) return;

    const dev = data.device;
    currentDevice = dev;

    // Device Info
    const nameEl = document.getElementById('device-name');
    if (nameEl) nameEl.textContent = dev.device_name || 'Laptop';

    const osEl = document.getElementById('device-os');
    if (osEl) osEl.textContent = (dev.os || dev.os_name || 'Windows') + (dev.os_version ? ' • ' + dev.os_version : '');

    // Status Pill
    const pill = document.getElementById('status-pill');
    const label = document.getElementById('status-label');
    const status = (dev.status || 'unknown').toLowerCase();

    if (pill && label) {
      pill.className = 'status-pill';
      if (status === 'online') {
        pill.classList.add('status-online');
        label.textContent = 'ONLINE';
      } else if (status === 'shutdown') {
        pill.classList.add('status-shutdown');
        label.textContent = 'SHUTDOWN';
      } else if (status === 'offline') {
        pill.classList.add('status-offline');
        label.textContent = 'OFFLINE';
      } else {
        pill.classList.add('status-offline');
        label.textContent = status.toUpperCase();
      }
    }

    // Last Seen
    const lastSeenEl = document.getElementById('last-seen');
    if (lastSeenEl) {
      lastSeenEl.textContent = formatRelativeTime(dev.last_seen || dev.updated_at);
      lastSeenEl.title = formatDateTime(dev.last_seen || dev.updated_at);
    }

    // Battery
    const batteryStat = document.getElementById('battery-stat');
    const batteryVal = document.getElementById('battery-val');
    const batteryIcon = document.getElementById('battery-icon');
    if (batteryStat && batteryVal) {
      if (dev.battery_level !== null && dev.battery_level !== undefined) {
        batteryStat.style.display = 'flex';
        const charging = dev.battery_charging ? ' (Charging)' : '';
        batteryVal.textContent = `${Math.round(dev.battery_level)}%${charging}`;
        if (batteryIcon) {
          if (dev.battery_charging) {
            batteryIcon.textContent = '⚡';
          } else if (dev.battery_level <= 20) {
            batteryIcon.textContent = '🪫';
          } else {
            batteryIcon.textContent = '🔋';
          }
        }
      } else {
        batteryStat.style.display = 'none';
      }
    }

    // Location
    const locationCity = document.getElementById('location-city');
    const locationMeta = document.getElementById('location-meta');
    const mapBtn = document.getElementById('map-btn');

    if (data.location && (data.location.city || data.location.latitude)) {
      const loc = data.location;
      const parts = [];
      if (loc.city) parts.push(loc.city);
      if (loc.state) parts.push(loc.state);
      else if (loc.region) parts.push(loc.region);
      if (loc.country) parts.push(loc.country);

      if (locationCity) {
        locationCity.textContent = parts.length > 0 ? parts.join(', ') : 'Approximate Location';
      }

      if (locationMeta) {
        const metaParts = [];
        if (loc.ip_address) metaParts.push(`IP: ${loc.ip_address}`);
        const acc = loc.accuracy || loc.accuracy_radius_km;
        if (acc) {
          if (acc < 1000) {
            metaParts.push(`±${Math.round(acc)} m`);
          } else {
            metaParts.push(`±${(acc / 1000).toFixed(1)} km`);
          }
        }
        if (loc.source) {
          if (loc.source === 'GPS' || loc.source === 'WIFI') {
            metaParts.push('🎯 High Accuracy (GPS/Wi-Fi)');
          } else {
            metaParts.push(`🌐 ${loc.source} (Approximate)`);
          }
        }
        if (loc.created_at) metaParts.push(formatRelativeTime(loc.created_at));
        locationMeta.textContent = metaParts.join(' • ');
      }

      if (loc.latitude && loc.longitude) {
        mapCoordinates = { lat: loc.latitude, lon: loc.longitude };
        if (mapBtn) mapBtn.style.display = 'inline-flex';
      } else {
        mapCoordinates = null;
        if (mapBtn) mapBtn.style.display = 'none';
      }
    } else {
      if (locationCity) locationCity.textContent = 'Location unavailable';
      if (locationMeta) locationMeta.textContent = 'Awaiting location report from agent';
      if (mapBtn) mapBtn.style.display = 'none';
      mapCoordinates = null;
    }

    // Update Control State Note
    const ctrlNote = document.getElementById('ctrl-note');
    if (ctrlNote) {
      if (status === 'shutdown') {
        ctrlNote.textContent = 'Laptop is powered off. Commands will queue until next boot.';
      } else if (status === 'offline') {
        ctrlNote.textContent = 'Laptop is currently offline. Commands will execute when reconnected.';
      } else {
        ctrlNote.textContent = 'Commands will execute instantly on the laptop.';
      }
    }

  } catch (err) {
    console.error('Error fetching status:', err);
  }
}

function openMap() {
  if (mapCoordinates && mapCoordinates.lat && mapCoordinates.lon) {
    const url = `https://www.google.com/maps?q=${mapCoordinates.lat},${mapCoordinates.lon}`;
    window.open(url, '_blank');
  } else {
    showToast('Coordinates not available.', 'error');
  }
}

// ============================================================
// Remote Commands
// ============================================================
function sendCommand(action) {
  if (!currentDeviceId) {
    showToast('No active device selected.', 'error');
    return;
  }

  pendingAction = action;

  const modal = document.getElementById('cmd-modal');
  const title = document.getElementById('modal-title');
  const msg = document.getElementById('modal-msg');
  const icon = document.getElementById('modal-icon');
  const confirmBtn = document.getElementById('modal-confirm-btn');

  if (!modal) return;

  if (action === 'SHUTDOWN') {
    icon.textContent = '🔴';
    title.textContent = 'Shutdown Laptop';
    msg.textContent = 'Are you sure you want to shut down this laptop? Any unsaved work on the laptop may be lost.';
    if (confirmBtn) {
      confirmBtn.className = 'btn btn-danger';
      confirmBtn.textContent = 'Confirm Shutdown';
    }
  } else if (action === 'RESTART') {
    icon.textContent = '🔄';
    title.textContent = 'Restart Laptop';
    msg.textContent = 'Are you sure you want to reboot this laptop now?';
    if (confirmBtn) {
      confirmBtn.className = 'btn btn-primary';
      confirmBtn.textContent = 'Confirm Restart';
    }
  } else if (action === 'LOCK') {
    icon.textContent = '🔒';
    title.textContent = 'Lock Laptop';
    msg.textContent = 'Are you sure you want to lock the Windows session?';
    if (confirmBtn) {
      confirmBtn.className = 'btn btn-primary';
      confirmBtn.textContent = 'Confirm Lock';
    }
  }

  modal.classList.remove('hidden');
}

function closeModal() {
  const modal = document.getElementById('cmd-modal');
  if (modal) modal.classList.add('hidden');
  pendingAction = null;
}

async function confirmCommand() {
  if (!pendingAction || !currentDeviceId) return;

  const action = pendingAction;
  const btn = document.getElementById('modal-confirm-btn');
  if (btn) btn.disabled = true;

  try {
    const res = await fetch('/api/commands', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',
      body: JSON.stringify({
        device_id: currentDeviceId,
        action: action
      })
    });

    const data = await res.json();
    closeModal();

    if (data.success) {
      showToast(`${action} command dispatched successfully!`, 'success');
      loadDeviceStatus();
      loadRecentActivity();
    } else {
      showToast(data.error || 'Failed to dispatch command.', 'error');
    }
  } catch (err) {
    closeModal();
    showToast('Network error while dispatching command.', 'error');
  } finally {
    if (btn) btn.disabled = false;
  }
}

// ============================================================
// Recent Activity Feed
// ============================================================
async function loadRecentActivity() {
  if (!currentDeviceId) return;

  try {
    const res = await fetch(`/api/activity?device_id=${currentDeviceId}&limit=5`, { credentials: 'include' });
    const data = await res.json();
    if (!data.success) return;

    const list = document.getElementById('activity-list');
    if (!list) return;

    const activities = data.activities || [];
    if (activities.length === 0) {
      list.innerHTML = '<p class="empty-msg">No activity recorded yet.</p>';
      return;
    }

    list.innerHTML = activities.map(act => {
      const meta = getActivityMeta(act.event_type, act.action);
      const locStr = act.location_label ? `<p class="act-loc" style="font-size:0.75rem;color:var(--text-muted);margin-top:2px">📍 ${escapeHtml(act.location_label)}</p>` : '';
      let details = (act.event_details && act.event_details !== meta.label) ? `<p class="act-details" style="font-size:0.75rem;color:var(--text-muted);margin-top:2px">${escapeHtml(act.event_details)}</p>` : '';
      if (act.event_details && act.event_details.includes('/static/captures/')) {
        const match = act.event_details.match(/(\/static\/captures\/[^\s'"]+)/);
        if (match) {
          details += `<div style="margin-top:6px"><a href="${match[1]}" target="_blank"><img src="${match[1]}" style="max-width:220px;max-height:120px;border-radius:6px;border:1px solid rgba(255,255,255,0.15);object-fit:cover" alt="Capture"/></a></div>`;
        }
      }
      return `
        <div class="activity-item">
          <span class="act-icon">${meta.icon}</span>
          <div class="act-info">
            <p class="act-label">${meta.label}</p>
            <p class="act-time">${formatDateTime(act.created_at)}</p>
            ${details}
            ${locStr}
          </div>
        </div>
      `;
    }).join('');

  } catch (err) {
    console.error('Error fetching activity:', err);
  }
}

function getActivityMeta(eventType, action) {
  const type = (eventType || '').toUpperCase();
  const act = (action || '').toUpperCase();

  switch (type) {
    case 'STARTUP':
      return { icon: '🟢', label: 'Laptop Started / Powered On' };
    case 'ONLINE':
      return { icon: '🟢', label: 'Laptop Online' };
    case 'SHUTDOWN':
      return { icon: '🔴', label: 'Laptop Shut Down' };
    case 'LOCK':
      return { icon: '🔒', label: 'Laptop Locked' };
    case 'UNLOCK':
      return { icon: '🔓', label: 'Laptop Unlocked' };
    case 'SLEEP':
      return { icon: '💤', label: 'Laptop Went to Sleep' };
    case 'WAKE':
      return { icon: '☀️', label: 'Laptop Woke Up' };
    case 'PHOTO':
      return { icon: '📷', label: 'Webcam Photo Captured' };
    case 'SCREENSHOT':
      return { icon: '📸', label: 'Desktop Screenshot Captured' };
    case 'ALARM':
      return { icon: '🔔', label: 'Audible Alarm Played' };
    case 'COMMAND':
    case 'COMMAND_EXECUTED':
      return { icon: '⚡', label: `Command Executed: ${act || 'ACTION'}` };
    case 'HEARTBEAT':
      return { icon: '💓', label: 'Agent Heartbeat' };
    case 'LOCATION':
      return { icon: '📍', label: 'Location Updated' };
    case 'OFFLINE':
    case 'OFFLINE_DETECTED':
      return { icon: '🟠', label: 'Laptop Went Offline' };
    case 'UNEXPECTED_OFFLINE':
      return { icon: '⚠️', label: 'Unexpected Offline' };
    default:
      return { icon: '📌', label: type || 'Activity Logged' };
  }
}

// ============================================================
// Notifications
// ============================================================
async function loadNotifications() {
  try {
    const res = await fetch('/api/notifications/in-app', { credentials: 'include' });
    const data = await res.json();
    if (!data.success) return;

    const notifs = data.notifications || [];
    const badge = document.getElementById('notif-badge');
    const unreadCount = notifs.filter(n => !n.is_read).length;

    if (badge) {
      if (unreadCount > 0) {
        badge.textContent = unreadCount > 99 ? '99+' : unreadCount;
        badge.classList.remove('hidden');
      } else {
        badge.classList.add('hidden');
      }
    }

    const list = document.getElementById('notif-list');
    if (list) {
      if (notifs.length === 0) {
        list.innerHTML = '<p class="empty-msg">No notifications yet.</p>';
      } else {
        list.innerHTML = notifs.map(n => `
          <div class="notif-item ${n.is_read ? '' : 'unread'}" onclick="markOneRead(${n.id})">
            <p class="notif-title">${escapeHtml(n.title)}</p>
            <p class="notif-msg">${escapeHtml(n.message || n.body || '')}</p>
            <p class="notif-time">${formatRelativeTime(n.created_at)}</p>
          </div>
        `).join('');
      }
    }
  } catch (err) {
    console.error('Error fetching notifications:', err);
  }
}

function toggleNotifPanel() {
  const panel = document.getElementById('notif-panel');
  const overlay = document.getElementById('notif-overlay');
  if (!panel || !overlay) return;

  const isHidden = panel.classList.contains('hidden');
  if (isHidden) {
    panel.classList.remove('hidden');
    overlay.classList.remove('hidden');
  } else {
    panel.classList.add('hidden');
    overlay.classList.add('hidden');
  }
}

async function markAllRead() {
  try {
    const res = await fetch('/api/notifications/read', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',
      body: JSON.stringify({ all: true })
    });
    if (res.ok) {
      loadNotifications();
    }
  } catch (err) {
    console.error('Error marking notifications as read:', err);
  }
}

async function markOneRead(id) {
  try {
    await fetch('/api/notifications/read', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',
      body: JSON.stringify({ id: id })
    });
    loadNotifications();
  } catch (err) {
    console.error('Error marking notification as read:', err);
  }
}

// ============================================================
// Auth Helpers
// ============================================================
async function logout() {
  try {
    await fetch('/api/auth/logout', { method: 'POST', credentials: 'include' });
  } catch {}
  window.location.href = '/login';
}

// ============================================================
// Toast & Helpers
// ============================================================
let toastTimer = null;
function showToast(message, type = 'info') {
  const toast = document.getElementById('toast');
  if (!toast) return;

  toast.textContent = message;
  toast.className = 'toast';
  if (type === 'success') toast.classList.add('toast-success');
  if (type === 'error') toast.classList.add('toast-error');

  toast.classList.remove('hidden');

  if (toastTimer) clearTimeout(toastTimer);
  toastTimer = setTimeout(() => {
    toast.classList.add('hidden');
  }, 3200);
}

function formatDateTime(isoString) {
  if (!isoString) return '—';
  try {
    const d = new Date(isoString);
    if (isNaN(d.getTime())) return isoString;
    return d.toLocaleDateString(undefined, {
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    }) + ' ' + d.toLocaleTimeString(undefined, {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    });
  } catch {
    return isoString;
  }
}

function formatRelativeTime(isoString) {
  if (!isoString) return 'Never';
  try {
    const d = new Date(isoString);
    if (isNaN(d.getTime())) return isoString;
    const diffSec = Math.floor((Date.now() - d.getTime()) / 1000);

    if (diffSec < 10) return 'Just now';
    if (diffSec < 60) return `${diffSec}s ago`;
    const diffMin = Math.floor(diffSec / 60);
    if (diffMin < 60) return `${diffMin}m ago`;
    const diffHour = Math.floor(diffMin / 60);
    if (diffHour < 24) return `${diffHour}h ago`;
    const diffDays = Math.floor(diffHour / 24);
    if (diffDays < 7) return `${diffDays}d ago`;
    return formatDateTime(isoString);
  } catch {
    return isoString;
  }
}

function escapeHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}
