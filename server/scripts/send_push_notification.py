#!/usr/bin/env python3
"""
One Tour - FCM Push Notification Dispatcher (Server CLI)
Sends targeted push notifications by Topic (e.g. pe_promocoes, pe_recife, global_ofertas)
or individual tokens with deep linking payloads.
"""

import sys
import os
import json
import argparse
from datetime import datetime, timezone

# Ensure UTF-8 output on Windows consoles
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

def send_push(topic, title, body, image_url=None, action_type="open_city", action_value="recife", dry_run=False):
    payload = {
        "notification": {
            "title": title,
            "body": body,
            "image": image_url
        },
        "data": {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "action_type": action_type,
            "action_value": action_value,
            "topic": topic,
            "timestamp": datetime.now(timezone.utc).isoformat()
        },
        "topic": topic
    }

    print("=" * 60)
    print("[PUSH] ONE TOUR PUSH DISPATCHER")
    print("=" * 60)
    print(f"Target Topic : /topics/{topic}")
    print(f"Title        : {title}")
    print(f"Body         : {body}")
    print(f"Image        : {image_url}")
    print(f"Action Type  : {action_type} -> {action_value}")
    print("-" * 60)

    if dry_run:
        print("[DRY-RUN] Payload formatted successfully:")
        print(json.dumps(payload, indent=2, ensure_ascii=False))
        return True

    creds_path = os.getenv("FIREBASE_CREDENTIALS_PATH")
    if creds_path and os.path.exists(creds_path):
        try:
            import firebase_admin
            from firebase_admin import credentials, messaging

            if not firebase_admin._apps:
                cred = credentials.Certificate(creds_path)
                firebase_admin.initialize_app(cred)

            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                    image=image_url,
                ),
                data={
                    "action_type": action_type,
                    "action_value": action_value,
                    "topic": topic,
                },
                topic=topic,
            )
            response = messaging.send(message)
            print(f"SUCCESS: FCM Message sent. Response ID: {response}")
            return True
        except Exception as e:
            print(f"ERROR sending through Firebase Admin: {e}")
            return False
    else:
        print("[INFO] FIREBASE_CREDENTIALS_PATH not set. Broadcast simulated locally.")
        print("Payload ready for FCM v1 API:")
        print(json.dumps(payload, indent=2, ensure_ascii=False))
        print("SUCCESS: Notification broadcast simulated.")
        return True

def main():
    parser = argparse.ArgumentParser(description="Send One Tour Push Notification via FCM")
    parser.add_argument("--topic", default="pe_promocoes", help="Target topic (e.g. pe_promocoes, pe_recife)")
    parser.add_argument("--title", default="Maré Baixa em Porto de Galinhas!", help="Notification title")
    parser.add_argument("--body", default="Maré baixa às 10h15. Ideal para passeio de jangada.", help="Notification body")
    parser.add_argument("--image", default="https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80", help="Rich push image URL")
    parser.add_argument("--action-type", default="open_city", choices=["open_city", "open_attraction", "open_url", "open_trip"], help="Action type on tap")
    parser.add_argument("--action-value", default="porto_de_galinhas", help="Action value (e.g. slug or URL)")
    parser.add_argument("--dry-run", action="store_true", help="Simulate without external network call")

    args = parser.parse_args()

    send_push(
        topic=args.topic,
        title=args.title,
        body=args.body,
        image_url=args.image,
        action_type=args.action_type,
        action_value=args.action_value,
        dry_run=args.dry_run
    )

if __name__ == "__main__":
    main()
