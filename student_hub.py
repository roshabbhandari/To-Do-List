import math
import sqlite3
import time
import tkinter as tk
from tkinter import messagebox, ttk
from datetime import datetime, date

DB_FILE = "taskflow.db"


class StudentHub:
    """Student productivity utilities for Roshab Tasks.

    Includes Pomodoro/focus timer, GPA calculator, attendance calculator,
    exam countdown, quick notes, daily goals, and study timetable storage.
    """

    def __init__(self, root):
        self.root = root
        self.root.title("Roshab Student Hub")
        self.root.geometry("980x700")
        self.root.configure(bg="#080d1a")
        self.dark = True
        self.db = sqlite3.connect(DB_FILE)
        self.db.row_factory = sqlite3.Row
        self.init_db()
        self.timer_seconds = 25 * 60
        self.timer_running = False
        self.timer_job = None
        self.build()
        self.refresh_notes()
        self.refresh_goals()
        self.refresh_schedule()

    def init_db(self):
        with self.db:
            self.db.execute("CREATE TABLE IF NOT EXISTS student_notes (id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, body TEXT DEFAULT '', updated_at TEXT NOT NULL)")
            self.db.execute("CREATE TABLE IF NOT EXISTS student_goals (id INTEGER PRIMARY KEY AUTOINCREMENT, goal TEXT NOT NULL, done INTEGER DEFAULT 0, created_at TEXT NOT NULL)")
            self.db.execute("CREATE TABLE IF NOT EXISTS study_schedule (id INTEGER PRIMARY KEY AUTOINCREMENT, day TEXT NOT NULL, start_time TEXT NOT NULL, subject TEXT NOT NULL, room TEXT DEFAULT '')")
            self.db.execute("CREATE TABLE IF NOT EXISTS exams (id INTEGER PRIMARY KEY AUTOINCREMENT, subject TEXT NOT NULL, exam_date TEXT NOT NULL, notes TEXT DEFAULT '')")

    def frame(self, parent, **kw):
        return tk.Frame(parent, bg="#111827", highlightthickness=1, highlightbackground="#273449", **kw)

    def button(self, parent, text, command, bg="#7c3aed"):
        return tk.Button(parent, text=text, command=command, bg=bg, fg="white", activebackground="#8b5cf6", activeforeground="white", relief="flat", bd=0, font=("Segoe UI", 9, "bold"), padx=12, pady=7, cursor="hand2")

    def build(self):
        header = tk.Frame(self.root, bg="#080d1a")
        header.pack(fill="x", padx=22, pady=18)
        tk.Label(header, text="Roshab Student Hub", bg="#080d1a", fg="#f8fafc", font=("Segoe UI", 26, "bold")).pack(side="left")
        tk.Label(header, text="Study • Plan • Focus • Track", bg="#080d1a", fg="#94a3b8", font=("Segoe UI", 10)).pack(side="left", padx=14, pady=(10, 0))
        tk.Label(header, text="Developed by Roshab Bhandari", bg="#080d1a", fg="#94a3b8", font=("Segoe UI", 9)).pack(side="right", pady=(10, 0))

        tabs = ttk.Notebook(self.root)
        tabs.pack(fill="both", expand=True, padx=22, pady=(0, 20))
        self.build_focus_tab(tabs)
        self.build_academic_tab(tabs)
        self.build_notes_tab(tabs)
        self.build_planner_tab(tabs)

    def build_focus_tab(self, tabs):
        tab = tk.Frame(tabs, bg="#080d1a")
        tabs.add(tab, text="Focus Timer")
        card = self.frame(tab, padx=30, pady=30)
        card.pack(fill="x", padx=20, pady=20)
        self.timer_label = tk.Label(card, text="25:00", bg="#111827", fg="#f8fafc", font=("Segoe UI", 58, "bold"))
        self.timer_label.pack(pady=(10, 6))
        self.timer_mode = tk.StringVar(value="Study")
        ttk.Combobox(card, textvariable=self.timer_mode, state="readonly", values=["Study", "Short Break", "Long Break"], width=18).pack(pady=8)
        controls = tk.Frame(card, bg="#111827")
        controls.pack(pady=12)
        self.button(controls, "▶ Start", self.start_timer, "#16a34a").pack(side="left", padx=5)
        self.button(controls, "⏸ Pause", self.pause_timer, "#d97706").pack(side="left", padx=5)
        self.button(controls, "↻ Reset", self.reset_timer, "#dc2626").pack(side="left", padx=5)
        tk.Label(card, text="25 min focus • 5 min short break • 15 min long break", bg="#111827", fg="#94a3b8", font=("Segoe UI", 9)).pack(pady=(4, 0))

        goals = self.frame(tab, padx=18, pady=18)
        goals.pack(fill="both", expand=True, padx=20, pady=(0, 20))
        tk.Label(goals, text="Today's study goals", bg="#111827", fg="#f8fafc", font=("Segoe UI", 13, "bold")).pack(anchor="w")
        row = tk.Frame(goals, bg="#111827")
        row.pack(fill="x", pady=10)
        self.goal_entry = tk.Entry(row, bg="#1e293b", fg="#f8fafc", insertbackground="#f8fafc", relief="flat")
        self.goal_entry.pack(side="left", fill="x", expand=True, ipady=8)
        self.button(row, "＋ Add Goal", self.add_goal).pack(side="left", padx=8)
        self.goal_list = tk.Listbox(goals, bg="#0f172a", fg="#f8fafc", selectbackground="#7c3aed", relief="flat", height=8)
        self.goal_list.pack(fill="both", expand=True)
        self.button(goals, "✓ Complete Selected", self.complete_goal, "#16a34a").pack(anchor="e", pady=(8, 0))

    def start_timer(self):
        if self.timer_running:
            return
        self.timer_running = True
        self.tick()

    def pause_timer(self):
        self.timer_running = False
        if self.timer_job:
            self.root.after_cancel(self.timer_job)
            self.timer_job = None

    def reset_timer(self):
        self.pause_timer()
        mode = self.timer_mode.get()
        self.timer_seconds = 25 * 60 if mode == "Study" else 5 * 60 if mode == "Short Break" else 15 * 60
        self.update_timer_label()

    def tick(self):
        self.update_timer_label()
        if not self.timer_running:
            return
        if self.timer_seconds <= 0:
            self.timer_running = False
            try:
                import winsound
                winsound.MessageBeep()
            except Exception:
                pass
            messagebox.showinfo("Focus session complete", "Nice work. Take a short break before your next session.")
            self.reset_timer()
            return
        self.timer_seconds -= 1
        self.timer_job = self.root.after(1000, self.tick)

    def update_timer_label(self):
        m, s = divmod(max(0, self.timer_seconds), 60)
        self.timer_label.config(text=f"{m:02d}:{s:02d}")

    def build_academic_tab(self, tabs):
        tab = tk.Frame(tabs, bg="#080d1a")
        tabs.add(tab, text="Academic Tools")
        top = tk.Frame(tab, bg="#080d1a")
        top.pack(fill="both", expand=True, padx=20, pady=20)

        gpa = self.frame(top, padx=18, pady=18)
        gpa.pack(side="left", fill="both", expand=True, padx=(0, 8))
        tk.Label(gpa, text="GPA Calculator", bg="#111827", fg="#f8fafc", font=("Segoe UI", 14, "bold")).pack(anchor="w")
        self.grade_entry = tk.Entry(gpa, bg="#1e293b", fg="#f8fafc", insertbackground="#f8fafc", relief="flat")
        self.grade_entry.insert(0, "3.7, 3.3, 4.0, 3.0")
        self.grade_entry.pack(fill="x", ipady=8, pady=(14, 8))
        tk.Label(gpa, text="Enter grade points separated by commas", bg="#111827", fg="#94a3b8", font=("Segoe UI", 8)).pack(anchor="w")
        self.button(gpa, "Calculate GPA", self.calculate_gpa).pack(anchor="w", pady=12)
        self.gpa_result = tk.Label(gpa, text="GPA: —", bg="#111827", fg="#22c55e", font=("Segoe UI", 20, "bold"))
        self.gpa_result.pack(anchor="w", pady=10)

        att = self.frame(top, padx=18, pady=18)
        att.pack(side="left", fill="both", expand=True, padx=(8, 0))
        tk.Label(att, text="Attendance Calculator", bg="#111827", fg="#f8fafc", font=("Segoe UI", 14, "bold")).pack(anchor="w")
        self.present_entry = tk.Entry(att, bg="#1e293b", fg="#f8fafc", insertbackground="#f8fafc", relief="flat")
        self.present_entry.insert(0, "18")
        self.present_entry.pack(fill="x", ipady=8, pady=(14, 8))
        self.total_entry = tk.Entry(att, bg="#1e293b", fg="#f8fafc", insertbackground="#f8fafc", relief="flat")
        self.total_entry.insert(0, "20")
        self.total_entry.pack(fill="x", ipady=8, pady=8)
        tk.Label(att, text="Present classes / Total classes", bg="#111827", fg="#94a3b8", font=("Segoe UI", 8)).pack(anchor="w")
        self.button(att, "Calculate Attendance", self.calculate_attendance).pack(anchor="w", pady=12)
        self.att_result = tk.Label(att, text="Attendance: —", bg="#111827", fg="#22c55e", font=("Segoe UI", 20, "bold"))
        self.att_result.pack(anchor="w", pady=10)

        exams = self.frame(tab, padx=18, pady=18)
        exams.pack(fill="both", expand=True, padx=20, pady=(0, 20))
        tk.Label(exams, text="Exam Countdown", bg="#111827", fg="#f8fafc", font=("Segoe UI", 14, "bold")).pack(anchor="w")
        form = tk.Frame(exams, bg="#111827")
        form.pack(fill="x", pady=10)
        self.exam_subject = tk.Entry(form, bg="#1e293b", fg="#f8fafc", insertbackground="#f8fafc", relief="flat")
        self.exam_subject.insert(0, "Mathematics")
        self.exam_subject.pack(side="left", fill="x", expand=True, ipady=8)
        self.exam_date = tk.Entry(form, bg="#1e293b", fg="#f8fafc", insertbackground="#f8fafc", relief="flat")
        self.exam_date.insert(0, "2026-09-15")
        self.exam_date.pack(side="left", width=130, ipady=8, padx=8)
        self.button(form, "＋ Save Exam", self.save_exam).pack(side="left")
        self.exam_list = tk.Listbox(exams, bg="#0f172a", fg="#f8fafc", selectbackground="#7c3aed", relief="flat", height=6)
        self.exam_list.pack(fill="both", expand=True)
        self.refresh_exams()

    def calculate_gpa(self):
        try:
            values = [float(x.strip()) for x in self.grade_entry.get().split(",") if x.strip()]
            if not values or any(v < 0 or v > 4 for v in values):
                raise ValueError
            gpa = sum(values) / len(values)
            self.gpa_result.config(text=f"GPA: {gpa:.2f}")
        except ValueError:
            messagebox.showerror("GPA", "Enter valid grade points from 0.0 to 4.0.")

    def calculate_attendance(self):
        try:
            p = int(self.present_entry.get())
            t = int(self.total_entry.get())
            if t <= 0 or p < 0 or p > t:
                raise ValueError
            self.att_result.config(text=f"Attendance: {p / t * 100:.1f}%")
        except ValueError:
            messagebox.showerror("Attendance", "Enter valid present and total class counts.")

    def save_exam(self):
        subject = self.exam_subject.get().strip()
        value = self.exam_date.get().strip()
        try:
            datetime.strptime(value, "%Y-%m-%d")
        except ValueError:
            messagebox.showerror("Exam", "Use YYYY-MM-DD for exam date.")
            return
        if not subject:
            return
        with self.db:
            self.db.execute("INSERT INTO exams(subject,exam_date,notes) VALUES(?,?,?)", (subject, value, ""))
        self.refresh_exams()

    def refresh_exams(self):
        if not hasattr(self, "exam_list"):
            return
        self.exam_list.delete(0, "end")
        rows = self.db.execute("SELECT * FROM exams ORDER BY exam_date ASC").fetchall()
        today = date.today()
        for r in rows:
            d = datetime.strptime(r["exam_date"], "%Y-%m-%d").date()
            days = (d - today).days
            label = "TODAY" if days == 0 else f"{days} days left" if days > 0 else f"{abs(days)} days ago"
            self.exam_list.insert("end", f"{r['subject']} • {r['exam_date']} • {label}")

    def build_notes_tab(self, tabs):
        tab = tk.Frame(tabs, bg="#080d1a")
        tabs.add(tab, text="Quick Notes")
        left = self.frame(tab, padx=16, pady=16)
        left.pack(side="left", fill="both", expand=True, padx=(20, 10), pady=20)
        tk.Label(left, text="Notes", bg="#111827", fg="#f8fafc", font=("Segoe UI", 14, "bold")).pack(anchor="w")
        self.note_title = tk.Entry(left, bg="#1e293b", fg="#f8fafc", insertbackground="#f8fafc", relief="flat")
        self.note_title.pack(fill="x", ipady=8, pady=8)
        self.note_body = tk.Text(left, bg="#0f172a", fg="#f8fafc", insertbackground="#f8fafc", relief="flat", wrap="word")
        self.note_body.pack(fill="both", expand=True)
        self.button(left, "Save Note", self.save_note).pack(anchor="e", pady=8)

        right = self.frame(tab, padx=16, pady=16)
        right.pack(side="left", fill="both", expand=True, padx=(10, 20), pady=20)
        tk.Label(right, text="Saved Notes", bg="#111827", fg="#f8fafc", font=("Segoe UI", 14, "bold")).pack(anchor="w")
        self.notes_list = tk.Listbox(right, bg="#0f172a", fg="#f8fafc", selectbackground="#7c3aed", relief="flat")
        self.notes_list.pack(fill="both", expand=True, pady=8)
        self.notes_list.bind("<Double-1>", self.load_note)
        self.button(right, "Delete Selected", self.delete_note, "#dc2626").pack(anchor="e")

    def save_note(self):
        title = self.note_title.get().strip()
        body = self.note_body.get("1.0", "end-1c")
        if not title or not body.strip():
            messagebox.showwarning("Note", "Add a title and some note content.")
            return
        with self.db:
            self.db.execute("INSERT INTO student_notes(title,body,updated_at) VALUES(?,?,?)", (title, body, datetime.now().isoformat(timespec="seconds")))
        self.note_title.delete(0, "end")
        self.note_body.delete("1.0", "end")
        self.refresh_notes()

    def refresh_notes(self):
        if not hasattr(self, "notes_list"):
            return
        self.notes_list.delete(0, "end")
        self.note_rows = self.db.execute("SELECT * FROM student_notes ORDER BY updated_at DESC").fetchall()
        for r in self.note_rows:
            self.notes_list.insert("end", f"{r['title']}  •  {r['updated_at'][:16]}")

    def load_note(self, _event=None):
        sel = self.notes_list.curselection()
        if not sel:
            return
        r = self.note_rows[sel[0]]
        self.note_title.delete(0, "end")
        self.note_title.insert(0, r["title"])
        self.note_body.delete("1.0", "end")
        self.note_body.insert("1.0", r["body"])

    def delete_note(self):
        sel = self.notes_list.curselection()
        if not sel:
            return
        r = self.note_rows[sel[0]]
        if messagebox.askyesno("Delete note", f"Delete '{r['title']}'?"):
            with self.db:
                self.db.execute("DELETE FROM student_notes WHERE id=?", (r["id"],))
            self.refresh_notes()

    def build_planner_tab(self, tabs):
        tab = tk.Frame(tabs, bg="#080d1a")
        tabs.add(tab, text="Planner")
        form = self.frame(tab, padx=16, pady=16)
        form.pack(fill="x", padx=20, pady=20)
        self.day_var = tk.StringVar(value="Monday")
        self.time_entry = tk.Entry(form, bg="#1e293b", fg="#f8fafc", insertbackground="#f8fafc", relief="flat")
        self.time_entry.insert(0, "09:00")
        self.subject_entry = tk.Entry(form, bg="#1e293b", fg="#f8fafc", insertbackground="#f8fafc", relief="flat")
        self.subject_entry.insert(0, "Mathematics")
        self.room_entry = tk.Entry(form, bg="#1e293b", fg="#f8fafc", insertbackground="#f8fafc", relief="flat")
        self.room_entry.insert(0, "Room 101")
        ttk.Combobox(form, textvariable=self.day_var, state="readonly", values=["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"], width=12).pack(side="left", padx=4)
        for w, width in [(self.time_entry, 8), (self.subject_entry, 20), (self.room_entry, 14)]:
            w.pack(side="left", width=width, ipady=7, padx=4)
        self.button(form, "＋ Add Class", self.add_class).pack(side="left", padx=4)
        self.schedule_list = tk.Listbox(tab, bg="#0f172a", fg="#f8fafc", selectbackground="#7c3aed", relief="flat", height=16)
        self.schedule_list.pack(fill="both", expand=True, padx=20, pady=(0, 20))

    def add_class(self):
        day = self.day_var.get()
        start = self.time_entry.get().strip()
        subject = self.subject_entry.get().strip()
        room = self.room_entry.get().strip()
        try:
            datetime.strptime(start, "%H:%M")
        except ValueError:
            messagebox.showerror("Schedule", "Use HH:MM for class time.")
            return
        if not subject:
            return
        with self.db:
            self.db.execute("INSERT INTO study_schedule(day,start_time,subject,room) VALUES(?,?,?,?)", (day, start, subject, room))
        self.refresh_schedule()

    def refresh_schedule(self):
        if not hasattr(self, "schedule_list"):
            return
        self.schedule_list.delete(0, "end")
        order = {d: i for i, d in enumerate(["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"])}
        rows = self.db.execute("SELECT * FROM study_schedule").fetchall()
        rows = sorted(rows, key=lambda r: (order.get(r["day"], 99), r["start_time"]))
        for r in rows:
            room = f" • {r['room']}" if r["room"] else ""
            self.schedule_list.insert("end", f"{r['day']}  {r['start_time']}  •  {r['subject']}{room}")


if __name__ == "__main__":
    root = tk.Tk()
    StudentHub(root)
    root.mainloop()
