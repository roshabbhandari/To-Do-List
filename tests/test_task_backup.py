from features.task_backup import build_backup, verify_backup


def test_backup_verifies():
    backup = build_backup([{"id": 1, "title": "Study"}])
    assert verify_backup(backup) is True


def test_modified_backup_fails():
    backup = build_backup([{"id": 1, "title": "Study"}])
    backup["tasks"][0]["title"] = "Changed"
    assert verify_backup(backup) is False
