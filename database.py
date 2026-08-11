import sqlite3
from datetime import datetime

DB_FILE = "taskflow.db"

class Database:
    def __init__(self, path=DB_FILE):
        self.path = path
        self.init_db()

    def connect(self):
        conn = sqlite3.connect(self.path)
        conn.row_factory = sqlite3.Row
        return conn

    def init_db(self):
        with self.connect() as conn:
            conn.execute("""CREATE TABLE IF NOT EXISTS tasks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                title TEXT NOT NULL,
                description TEXT DEFAULT '',
                category TEXT DEFAULT 'Personal',
                tags TEXT DEFAULT '',
                priority TEXT DEFAULT 'Medium',
                due_date TEXT DEFAULT '',
                completed INTEGER DEFAULT 0,
                favorite INTEGER DEFAULT 0,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL)""")

    def add_task(self, title, description, category, tags, priority, due_date):
        now = datetime.now().isoformat(timespec="seconds")
        with self.connect() as conn:
            cur = conn.execute("INSERT INTO tasks (title,description,category,tags,priority,due_date,created_at,updated_at) VALUES (?,?,?,?,?,?,?,?)",
                (title,description,category,tags,priority,due_date,now,now))
            return cur.lastrowid

    def get_tasks(self, search="", status="All", category="All", priority="All", favorites=False, sort="created_at DESC"):
        sorts = {"created_at DESC":"created_at DESC", "due_date ASC":"CASE WHEN due_date='' THEN 1 ELSE 0 END, due_date ASC", "priority":"CASE priority WHEN 'High' THEN 1 WHEN 'Medium' THEN 2 ELSE 3 END", "title":"title COLLATE NOCASE ASC"}
        clauses, params = [], []
        if search:
            clauses.append("(title LIKE ? OR description LIKE ? OR tags LIKE ?)"); v=f"%{search}%"; params += [v,v,v]
        if status == "Pending": clauses.append("completed=0")
        elif status == "Completed": clauses.append("completed=1")
        if category != "All": clauses.append("category=?"); params.append(category)
        if priority != "All": clauses.append("priority=?"); params.append(priority)
        if favorites: clauses.append("favorite=1")
        where = " WHERE " + " AND ".join(clauses) if clauses else ""
        with self.connect() as conn:
            return conn.execute(f"SELECT * FROM tasks{where} ORDER BY {sorts.get(sort,'created_at DESC')}", params).fetchall()

    def get_task(self, task_id):
        with self.connect() as conn:
            return conn.execute("SELECT * FROM tasks WHERE id=?", (task_id,)).fetchone()

    def update_task(self, task_id, title, description, category, tags, priority, due_date):
        with self.connect() as conn:
            conn.execute("UPDATE tasks SET title=?,description=?,category=?,tags=?,priority=?,due_date=?,updated_at=? WHERE id=?",
                (title,description,category,tags,priority,due_date,datetime.now().isoformat(timespec="seconds"),task_id))

    def toggle_complete(self, task_id):
        with self.connect() as conn:
            conn.execute("UPDATE tasks SET completed=1-completed,updated_at=? WHERE id=?", (datetime.now().isoformat(timespec="seconds"),task_id))

    def toggle_favorite(self, task_id):
        with self.connect() as conn:
            conn.execute("UPDATE tasks SET favorite=1-favorite,updated_at=? WHERE id=?", (datetime.now().isoformat(timespec="seconds"),task_id))

    def delete_task(self, task_id):
        with self.connect() as conn: conn.execute("DELETE FROM tasks WHERE id=?", (task_id,))

    def bulk_complete(self, ids):
        with self.connect() as conn: conn.executemany("UPDATE tasks SET completed=1 WHERE id=?", [(i,) for i in ids])

    def bulk_delete(self, ids):
        with self.connect() as conn: conn.executemany("DELETE FROM tasks WHERE id=?", [(i,) for i in ids])

    def clear_completed(self):
        with self.connect() as conn: conn.execute("DELETE FROM tasks WHERE completed=1")

    def stats(self):
        with self.connect() as conn:
            total=conn.execute("SELECT COUNT(*) FROM tasks").fetchone()[0]
            completed=conn.execute("SELECT COUNT(*) FROM tasks WHERE completed=1").fetchone()[0]
            high=conn.execute("SELECT COUNT(*) FROM tasks WHERE priority='High' AND completed=0").fetchone()[0]
            favorites=conn.execute("SELECT COUNT(*) FROM tasks WHERE favorite=1").fetchone()[0]
            overdue=conn.execute("SELECT COUNT(*) FROM tasks WHERE completed=0 AND due_date<>'' AND due_date < date('now')").fetchone()[0]
            return total,completed,total-completed,high,favorites,overdue

    def categories(self):
        with self.connect() as conn:
            return [r[0] for r in conn.execute("SELECT DISTINCT category FROM tasks WHERE category<>'' ORDER BY category")]

    def export_rows(self):
        with self.connect() as conn: return conn.execute("SELECT * FROM tasks ORDER BY created_at DESC").fetchall()
