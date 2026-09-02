from datetime import datetime, timedelta


def make_timebox(start, minutes=25):
    if minutes < 1 or minutes > 240:
        raise ValueError("minutes must be between 1 and 240")
    if not isinstance(start, datetime):
        raise TypeError("start must be a datetime")
    end = start + timedelta(minutes=minutes)
    return {"start": start, "end": end, "minutes": minutes}


def split_sessions(total_minutes, session_minutes=25, break_minutes=5):
    if total_minutes < 1:
        raise ValueError("total_minutes must be positive")
    if session_minutes < 1 or break_minutes < 0:
        raise ValueError("session and break lengths are invalid")
    sessions = []
    remaining = total_minutes
    while remaining > 0:
        focus = min(session_minutes, remaining)
        sessions.append({"type": "focus", "minutes": focus})
        remaining -= focus
        if remaining > 0 and break_minutes:
            pause = min(break_minutes, remaining)
            sessions.append({"type": "break", "minutes": pause})
            remaining -= pause
    return sessions
