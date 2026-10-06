"""
Laptop Guardian — End-to-End System Test Suite
Tests authentication, pairing, heartbeat, commands, location, activity logs, and security checks.
"""
import sys
import os
import json
import unittest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from backend.app import app
from backend.database import get_db


class LaptopGuardianTestSuite(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.client = app.test_client()
        cls.test_email = f"test_user_{os.urandom(4).hex()}@example.com"
        cls.test_password = "SecurePassword123!"
        cls.device_token = None
        cls.device_id = None
        cls.user_id = None

    def test_01_user_registration(self):
        """Test user signup"""
        resp = self.client.post("/api/auth/register", json={
            "email": self.test_email,
            "password": self.test_password,
            "name": "Test User"
        })
        self.assertEqual(resp.status_code, 201)
        data = resp.get_json()
        self.assertTrue(data["success"])
        self.assertIn("user", data)
        self.__class__.user_id = data["user"]["id"]

    def test_02_user_login_and_session(self):
        """Test user login and session cookie"""
        resp = self.client.post("/api/auth/login", json={
            "email": self.test_email,
            "password": self.test_password
        })
        self.assertEqual(resp.status_code, 200)
        data = resp.get_json()
        self.assertTrue(data["success"])

        # Check me
        me_resp = self.client.get("/api/auth/me")
        self.assertEqual(me_resp.status_code, 200)
        me_data = me_resp.get_json()
        self.assertTrue(me_data["success"])
        self.assertEqual(me_data["user"]["email"], self.test_email)

    def test_03_pairing_code_and_device_registration(self):
        """Generate pairing code and register a laptop device"""
        code_resp = self.client.post("/api/devices/pair-code")
        self.assertEqual(code_resp.status_code, 200)
        code_data = code_resp.get_json()
        self.assertTrue(code_data["success"])
        pairing_code = code_data["pairing_code"]
        self.assertEqual(len(pairing_code), 6)

        # Register device via pairing code
        reg_resp = self.client.post("/api/devices/register", json={
            "pairing_code": pairing_code,
            "device_name": "Antigravity Test Laptop",
            "os_name": "Windows",
            "os_version": "11 Pro",
            "mac_address": "00:11:22:33:44:55",
            "manufacturer": "Dell",
            "model": "XPS 15"
        })
        self.assertEqual(reg_resp.status_code, 201)
        reg_data = reg_resp.get_json()
        self.assertTrue(reg_data["success"])
        self.assertIn("device_token", reg_data)
        self.__class__.device_token = reg_data["device_token"]
        self.__class__.device_id = reg_data["device"]["device_id"]

    def test_04_device_heartbeat(self):
        """Send heartbeat from laptop agent with battery & IP"""
        headers = {"Authorization": f"Bearer {self.device_token}"}
        hb_resp = self.client.post("/api/heartbeat", headers=headers, json={
            "battery_level": 88,
            "battery_charging": True,
            "ip_address": "192.168.1.50",
            "timezone": "UTC"
        })
        self.assertEqual(hb_resp.status_code, 200)
        hb_data = hb_resp.get_json()
        self.assertTrue(hb_data["success"])
        self.assertIn("pending_commands", hb_data)

    def test_05_device_status_in_dashboard(self):
        """Verify device status is ONLINE in the user's dashboard"""
        status_resp = self.client.get(f"/api/devices/{self.device_id}/status")
        self.assertEqual(status_resp.status_code, 200)
        status_data = status_resp.get_json()
        self.assertTrue(status_data["success"])
        dev = status_data["device"]
        self.assertEqual(dev["status"], "ONLINE")
        self.assertEqual(dev["battery_level"], 88)
        self.assertTrue(dev["battery_charging"])

    def test_06_location_reporting(self):
        """Send location update from laptop agent and verify in status"""
        headers = {"Authorization": f"Bearer {self.device_token}"}
        loc_resp = self.client.post("/api/location", headers=headers, json={
            "latitude": 37.7749,
            "longitude": -122.4194,
            "city": "San Francisco",
            "region": "California",
            "country": "United States",
            "accuracy_radius_km": 5.0,
            "source": "ip_geolocation"
        })
        self.assertEqual(loc_resp.status_code, 200)
        loc_data = loc_resp.get_json()
        self.assertTrue(loc_data["success"])

        # Check status again to see location returned
        status_resp = self.client.get(f"/api/devices/{self.device_id}/status")
        status_data = status_resp.get_json()
        self.assertIsNotNone(status_data.get("location"))
        self.assertEqual(status_data["location"]["city"], "San Francisco")

    def test_07_remote_command_lifecycle(self):
        """User issues LOCK command -> Agent receives -> Agent reports result"""
        cmd_resp = self.client.post("/api/commands", json={
            "device_id": self.device_id,
            "action": "LOCK"
        })
        self.assertEqual(cmd_resp.status_code, 201)
        cmd_data = cmd_resp.get_json()
        self.assertTrue(cmd_data["success"])
        cmd_id = cmd_data["command_id"]

        # Agent sends heartbeat and receives the pending command
        headers = {"Authorization": f"Bearer {self.device_token}"}
        hb_resp = self.client.post("/api/heartbeat", headers=headers, json={
            "battery_level": 87.0
        })
        hb_data = hb_resp.get_json()
        self.assertTrue(hb_data["success"])
        pending = hb_data["pending_commands"]
        self.assertTrue(len(pending) >= 1)
        self.assertEqual(pending[0]["id"], cmd_id)
        self.assertEqual(pending[0]["action"], "LOCK")

        # Agent reports command executed
        res_resp = self.client.post("/api/commands/result", headers=headers, json={
            "command_id": cmd_id,
            "status": "EXECUTED",
            "result": "Workstation locked successfully."
        })
        self.assertEqual(res_resp.status_code, 200)
        res_data = res_resp.get_json()
        self.assertTrue(res_data["success"])

    def test_08_activity_logs(self):
        """Verify activity logs are recorded for events and commands"""
        act_resp = self.client.get(f"/api/activity?device_id={self.device_id}")
        self.assertEqual(act_resp.status_code, 200)
        act_data = act_resp.get_json()
        self.assertTrue(act_data["success"])
        self.assertTrue(len(act_data["activities"]) > 0)

    def test_09_notifications(self):
        """Verify notifications can be read and acknowledged"""
        notif_resp = self.client.get("/api/notifications/in-app")
        self.assertEqual(notif_resp.status_code, 200)
        notif_data = notif_resp.get_json()
        self.assertTrue(notif_data["success"])

        # Mark all read
        ack_resp = self.client.post("/api/notifications/read", json={"all": True})
        self.assertEqual(ack_resp.status_code, 200)
        ack_data = ack_resp.get_json()
        self.assertTrue(ack_data["success"])

    def test_10_security_unauthenticated_command(self):
        """Verify unauthenticated command request is rejected with 401"""
        anon_client = app.test_client()
        resp = anon_client.post("/api/commands", json={
            "device_id": self.device_id,
            "action": "SHUTDOWN"
        })
        self.assertEqual(resp.status_code, 401)

    def test_11_security_unauthorized_device_access(self):
        """Verify a different user cannot send commands to this device"""
        other_client = app.test_client()
        other_client.post("/api/auth/register", json={
            "email": f"attacker_{os.urandom(4).hex()}@example.com",
            "password": "AttackerPassword123!",
            "name": "Attacker"
        })
        resp = other_client.post("/api/commands", json={
            "device_id": self.device_id,
            "action": "SHUTDOWN"
        })
        self.assertEqual(resp.status_code, 403)
        data = resp.get_json()
        self.assertFalse(data["success"])


    def test_12_cloud_health_probe(self):
        """Verify GET /api/health returns 200 ok for cloud load balancers"""
        resp = self.client.get("/api/health")
        self.assertEqual(resp.status_code, 200)
        data = resp.get_json()
        self.assertEqual(data.get("status"), "ok")

    def test_13_fcm_token_registration(self):
        """Verify POST /api/devices/fcm-token registers token"""
        resp = self.client.post("/api/devices/fcm-token", json={
            "token": "fake_test_fcm_token_abcdef123456",
            "platform": "android",
            "device_id": self.device_id,
        })
        self.assertEqual(resp.status_code, 200)
        data = resp.get_json()
        self.assertTrue(data.get("success"))

    def test_14_reconnect_online_transition(self):
        """Verify device transitioning from OFFLINE back to ONLINE logs an ONLINE notification"""
        # 1. Force status to OFFLINE in database
        conn = get_db()
        cur = conn.cursor()
        cur.execute("UPDATE devices SET status='OFFLINE' WHERE device_id=%s", (self.device_id,))
        conn.commit()
        cur.close()
        conn.close()

        # 2. Send heartbeat to simulate device coming back online
        resp = self.client.post("/api/heartbeat", json={
            "device_id": self.device_id,
            "device_token": self.device_token,
            "battery": 88,
            "charging": True,
        })
        self.assertEqual(resp.status_code, 200)

        # 3. Check notifications for "Laptop Online"
        notif_resp = self.client.get("/api/notifications/in-app")
        data = notif_resp.get_json()
        titles = [n["title"] for n in data.get("notifications", [])]
        self.assertTrue(any("Laptop Online" in t for t in titles))


if __name__ == "__main__":
    unittest.main()
