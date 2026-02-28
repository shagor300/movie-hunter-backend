"""
FlixHub — Send FCM Push Notification Script
Usage: python send_notification.py

Sends a push notification to ALL FlixHub users subscribed to the 'all' topic.
Uses the FCM HTTP v1 API with a service account or the legacy API with server key.

SETUP (one-time):
  1. Go to Firebase Console → Project Settings → Cloud Messaging
  2. Copy the Server Key (Legacy API)
  3. Paste it below as FIREBASE_SERVER_KEY
  
  OR for HTTP v1 API:
  1. Go to Firebase Console → Project Settings → Service Accounts
  2. Click "Generate New Private Key"
  3. Save the JSON file and set its path as SERVICE_ACCOUNT_PATH below
"""

import json
import requests
import sys

# ==========================================
# OPTION 1: Legacy FCM API (Simpler)
# ==========================================
FIREBASE_SERVER_KEY = ""  # Paste your server key here

# ==========================================
# OPTION 2: FCM HTTP v1 API (Recommended)
# ==========================================
SERVICE_ACCOUNT_PATH = ""  # Path to service account JSON
PROJECT_ID = "flixhub-7433c"


def send_via_legacy_api(title: str, body: str, topic: str = "all"):
    """Send notification using Legacy FCM API."""
    if not FIREBASE_SERVER_KEY:
        print("❌ FIREBASE_SERVER_KEY is not set!")
        print("   Go to Firebase Console → Project Settings → Cloud Messaging")
        print("   Copy the Server Key and paste it in this script.")
        return False

    url = "https://fcm.googleapis.com/fcm/send"
    headers = {
        "Authorization": f"key={FIREBASE_SERVER_KEY}",
        "Content-Type": "application/json",
    }
    payload = {
        "to": f"/topics/{topic}",
        "notification": {
            "title": title,
            "body": body,
            "sound": "default",
        },
        "data": {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "type": "test",
        },
    }

    response = requests.post(url, headers=headers, json=payload)

    if response.status_code == 200:
        result = response.json()
        print(f"✅ Notification sent! Message ID: {result.get('message_id', 'N/A')}")
        return True
    else:
        print(f"❌ Failed: {response.status_code} — {response.text}")
        return False


def send_via_v1_api(title: str, body: str, topic: str = "all"):
    """Send notification using FCM HTTP v1 API with service account."""
    if not SERVICE_ACCOUNT_PATH:
        print("❌ SERVICE_ACCOUNT_PATH is not set!")
        print("   Go to Firebase Console → Project Settings → Service Accounts")
        print("   Click 'Generate New Private Key' and set the path in this script.")
        return False

    try:
        from google.oauth2 import service_account
        from google.auth.transport.requests import Request
    except ImportError:
        print("❌ Install google-auth: pip install google-auth requests")
        return False

    # Get OAuth2 token
    credentials = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_PATH,
        scopes=["https://www.googleapis.com/auth/firebase.messaging"],
    )
    credentials.refresh(Request())

    url = f"https://fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send"
    headers = {
        "Authorization": f"Bearer {credentials.token}",
        "Content-Type": "application/json",
    }
    payload = {
        "message": {
            "topic": topic,
            "notification": {
                "title": title,
                "body": body,
            },
            "android": {
                "notification": {
                    "sound": "default",
                    "channel_id": "high_importance_channel",
                }
            },
        }
    }

    response = requests.post(url, headers=headers, json=payload)

    if response.status_code == 200:
        result = response.json()
        print(f"✅ Notification sent! Name: {result.get('name', 'N/A')}")
        return True
    else:
        print(f"❌ Failed: {response.status_code} — {response.text}")
        return False


if __name__ == "__main__":
    title = "Hello FlixHub!"
    body = "Your notification system is now active!"

    # Allow custom title/body from command line
    if len(sys.argv) >= 3:
        title = sys.argv[1]
        body = sys.argv[2]

    print(f"📤 Sending notification to topic 'all'...")
    print(f"   Title: {title}")
    print(f"   Body:  {body}")
    print()

    # Try Legacy API first (simpler setup), then V1
    if FIREBASE_SERVER_KEY:
        send_via_legacy_api(title, body)
    elif SERVICE_ACCOUNT_PATH:
        send_via_v1_api(title, body)
    else:
        print("=" * 50)
        print("⚠️  NO API KEY CONFIGURED!")
        print("=" * 50)
        print()
        print("You need to configure ONE of these:")
        print()
        print("Option A (Easy): Legacy FCM Server Key")
        print("  1. Go to: https://console.firebase.google.com/project/flixhub-7433c/settings/cloudmessaging")
        print("  2. Enable 'Cloud Messaging API (Legacy)'")
        print("  3. Copy the Server Key")
        print("  4. Paste it as FIREBASE_SERVER_KEY in this script")
        print()
        print("Option B (Recommended): Service Account")
        print("  1. Go to: https://console.firebase.google.com/project/flixhub-7433c/settings/serviceaccounts/adminsdk")
        print("  2. Click 'Generate New Private Key'")
        print("  3. Save the JSON file")
        print("  4. Set SERVICE_ACCOUNT_PATH in this script")
        print()
        print("Option C (Easiest — No Script Needed):")
        print("  1. Go to: https://console.firebase.google.com/project/flixhub-7433c/messaging")
        print("  2. Click 'Create your first campaign' → 'Firebase Notification messages'")
        print("  3. Enter title & body → Target topic 'all' → Send!")
