from hashlib import sha256
import json
from datetime import datetime, timezone


def build_backup(tasks):
    payload = {
        "version": 1,
        "created_at": datetime.now(timezone.utc).isoformat(),
        "tasks": [dict(task) for task in tasks],
    }
    raw = json.dumps(payload, sort_keys=True, default=str).encode("utf-8")
    payload["checksum"] = sha256(raw).hexdigest()
    return payload


def verify_backup(backup):
    if not isinstance(backup, dict) or "checksum" not in backup:
        return False
    expected = backup["checksum"]
    payload = {k: v for k, v in backup.items() if k != "checksum"}
    raw = json.dumps(payload, sort_keys=True, default=str).encode("utf-8")
    return expected == sha256(raw).hexdigest()
