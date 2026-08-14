import csv
import tkinter as tk
from tkinter import ttk, messagebox, filedialog
from datetime import datetime
from database import Database

try:
    import winsound
except ImportError:
    winsound = None


class TaskFlowPro:
    def __init__(self, root):
        self.root = root
        self.db = Database()
        self.dark = True
        self.root.title("Roshab Tasks")
        self.root.geometry("1280x820")
        self.root.minsize(1000, 680)
        self.setup_colors()
        self.build()
        self.refresh()
        self.root.bind("<Control-n>", lambda e: self.open_editor())
        self.root.bind("<Control-f>", lambda e: self.search.focus_set())
        self.root.bind("<Delete>", lambda e: self.delete_selected())
        self.root.bind("<Control-e>", lambda e: self.export_csv())
        self.root.after(10000, self.reminder_check)

    def setup_colors(self):
        if self.dark:
            self.bg = "#080d1a"
            self.card = "#111827"
            self.card_alt = "#172033"
            self.input = "#1e293b"
            self.text = "#f8fafc"
            self.muted = "#94a3b8"
            self.accent = "#7c3aed"
            self.accent_hover = "#8b5cf6"
            self.border = "#273449"
            self.success = "#22c55e"
            self.warning = "#f59e0b"
            self.danger = "#ef4444"
        else:
            self.bg = "#eef2ff"
            self.card = "#ffffff"
            self.card_alt = "#f8fafc"
            self.input = "#e2e8f0"
            self.text = "#0f172a"
            self.muted = "#64748b"
            self.accent = "#6d28d9"
            self.accent_hover = "#7c3aed"
            self.border = "#cbd5e1"
            self.success = "#16a34a"
            self.warning = "#d97706"
            self.danger = "#dc2626"
        self.root.configure(bg=self.bg)

    def style(self):
        s = ttk.Style()
        s.theme_use("clam")
        s.configure("Treeview", background=self.card, foreground=self.text, fieldbackground=self.card, rowheight=42, font=("Segoe UI", 10), borderwidth=0, relief="flat")
        s.configure("Treeview.Heading", background=self.card_alt, foreground=self.muted, font=("Segoe UI", 9, "bold"), padding=11, relief="flat")
        s.map("Treeview", background=[("selected", self.accent)], foreground=[("selected", "white")])
        s.configure("TCombobox", fieldbackground=self.input, background=self.input, foreground=self.text, arrowcolor=self.muted, borderwidth=0, padding=6)
        s.map("TCombobox", fieldbackground=[("readonly", self.input)])

    def button(self, parent, text, command, bg=None):
        bg = bg or self.card
        return tk.Button(parent, text=text, command=command, bg=bg, fg="white" if bg != self.card else self.text, activebackground=self.accent_hover if bg != self.card else self.input, activeforeground="white" if bg != self.card else self.text, relief="flat", bd=0, font=("Segoe UI", 9, "bold"), padx=13, pady=8, cursor="hand2")

    def build(self):
        self.style()
        top = tk.Frame(self.root, bg=self.bg)
        top.pack(fill="x", padx=24, pady=(20, 12))
        title_box = tk.Frame(top, bg=self.bg)
        title_box.pack(side="left")
        tk.Label(title_box, text="Roshab Tasks", font=("Segoe UI", 28, "bold"), bg=self.bg, fg=self.text).pack(anchor="w")
        tk.Label(title_box, text="A modern local productivity workspace", font=("Segoe UI", 10), bg=self.bg, fg=self.muted).pack(anchor="w", pady=(2, 0))
        controls = tk.Frame(top, bg=self.bg)
        controls.pack(side="right", anchor="n")
        self.button(controls, "☾ Theme", self.toggle_theme).pack(side="left", padx=4)
        self.button(controls, "⚙ Settings", self.show_shortcuts).pack(side="left", padx=4)

        self.stats_frame = tk.Frame(self.root, bg=self.bg)
        self.stats_frame.pack(fill="x", padx=24, pady=7)
        self.stat_labels = {}
        for key, label in [("total", "TOTAL"), ("completed", "DONE"), ("pending", "PENDING"), ("high", "HIGH"), ("favorite", "FAVORITES"), ("overdue", "OVERDUE"), ("reminders", "ALARMS")]:
            self.stat_card(key, label)

        add = tk.Frame(self.root, bg=self.card, highlightthickness=1, highlightbackground=self.border, padx=14, pady=14)
        add.pack(fill="x", padx=24, pady=10)
        self.title_entry = self.entry(add, "New task title...")
        self.title_entry.pack(side="left", fill="x", expand=True, ipady=10)
        self.priority = tk.StringVar(value="Medium")
        self.combo(add, self.priority, ["Low", "Medium", "High"], 10).pack(side="left", padx=7)
        self.category = tk.StringVar(value="Personal")
        self.combo(add, self.category, ["Personal", "Work", "Study", "Shopping", "Health", "Project"], 11).pack(side="left", padx=7)
        self.due = tk.StringVar()
        de = self.entry(add, "Due YYYY-MM-DD")
        de.configure(textvariable=self.due)
        de.pack(side="left", width=118, ipady=10, padx=7)
        self.reminder_at = tk.StringVar()
        re = self.entry(add, "Alarm YYYY-MM-DD HH:MM")
        re.configure(textvariable=self.reminder_at)
        re.pack(side="left", width=175, ipady=10, padx=7)
        self.reminder_enabled = tk.BooleanVar(value=False)
        tk.Checkbutton(add, text="⏰", variable=self.reminder_enabled, bg=self.card, fg=self.text, selectcolor=self.input, activebackground=self.card, activeforeground=self.text, font=("Segoe UI", 10, "bold")).pack(side="left", padx=3)
        self.button(add, "＋ Add Task", self.add_task, self.accent).pack(side="left", padx=(4, 0))
        self.title_entry.bind("<Return>", lambda e: self.add_task())

        tools = tk.Frame(self.root, bg=self.bg)
        tools.pack(fill="x", padx=24, pady=(4, 10))
        self.search = self.entry(tools, "Search title, description or tags...")
        self.search.pack(side="left", fill="x", expand=True, ipady=9)
        self.search.bind("<KeyRelease>", lambda e: self.refresh())
        self.status = tk.StringVar(value="All")
        self.combo(tools, self.status, ["All", "Pending", "Completed"], 12).pack(side="left", padx=6)
        self.cat_filter = tk.StringVar(value="All")
        self.combo(tools, self.cat_filter, ["All", "Personal", "Work", "Study", "Shopping", "Health", "Project"], 12).pack(side="left", padx=6)
        self.pri_filter = tk.StringVar(value="All")
        self.combo(tools, self.pri_filter, ["All", "High", "Medium", "Low"], 9).pack(side="left", padx=6)
        self.sort = tk.StringVar(value="created_at DESC")
        self.combo(tools, self.sort, ["created_at DESC", "due_date ASC", "priority", "title"], 15).pack(side="left", padx=6)
        self.favorites = tk.BooleanVar(value=False)
        tk.Checkbutton(tools, text="★ Favorites", variable=self.favorites, command=self.refresh, bg=self.bg, fg=self.text, selectcolor=self.card, activebackground=self.bg, activeforeground=self.text, font=("Segoe UI", 9, "bold")).pack(side="left")

        table = tk.Frame(self.root, bg=self.card, highlightthickness=1, highlightbackground=self.border)
        table.pack(fill="both", expand=True, padx=24)
        cols = ("id", "done", "favorite", "title", "category", "priority", "due", "reminder", "tags")
        self.tree = ttk.Treeview(table, columns=cols, show="headings", selectmode="extended")
        heads = {"id": "#", "done": "STATUS", "favorite": "★", "title": "TASK", "category": "CATEGORY", "priority": "PRIORITY", "due": "DUE", "reminder": "ALARM", "tags": "TAGS"}
        widths = {"id": 40, "done": 90, "favorite": 42, "title": 320, "category": 105, "priority": 85, "due": 100, "reminder": 145, "tags": 145}
        for c in cols:
            self.tree.heading(c, text=heads[c])
            self.tree.column(c, width=widths[c], anchor="center" if c in ("id", "done", "favorite", "priority", "due", "reminder") else "w")
        self.tree.tag_configure("completed", foreground=self.muted)
        self.tree.tag_configure("high", foreground=self.danger)
        self.tree.tag_configure("medium", foreground=self.warning)
        self.tree.tag_configure("low", foreground=self.success)
        self.tree.tag_configure("alarm", background="#2a183d")
        self.tree.pack(side="left", fill="both", expand=True)
        sb = ttk.Scrollbar(table, orient="vertical", command=self.tree.yview)
        sb.pack(side="right", fill="y")
        self.tree.configure(yscrollcommand=sb.set)
        self.tree.bind("<Double-1>", lambda e: self.edit_selected())

        bottom = tk.Frame(self.root, bg=self.bg)
        bottom.pack(fill="x", padx=24, pady=14)
        for text, cmd, color in [("✓ Complete", self.complete_selected, self.success), ("✎ Edit", self.edit_selected, self.accent), ("★ Favorite", self.favorite_selected, self.warning), ("Delete", self.delete_selected, self.danger), ("Clear Done", self.clear_completed, "#7c3aed")]:
            self.button(bottom, text, cmd, color).pack(side="left", padx=4)
        self.button(bottom, "Import CSV", self.import_csv).pack(side="right", padx=4)
        self.button(bottom, "Export CSV", self.export_csv).pack(side="right", padx=4)
        tk.Label(bottom, text="Developed by Roshab Bhandari", font=("Segoe UI", 9), bg=self.bg, fg=self.muted).pack(side="right", padx=14)

    def stat_card(self, key, title):
        f = tk.Frame(self.stats_frame, bg=self.card, highlightthickness=1, highlightbackground=self.border, padx=16, pady=10)
        f.pack(side="left", fill="x", expand=True, padx=4)
        tk.Label(f, text=title, font=("Segoe UI", 8, "bold"), bg=self.card, fg=self.muted).pack(anchor="w")
        l = tk.Label(f, text="0", font=("Segoe UI", 18, "bold"), bg=self.card, fg=self.text)
        l.pack(anchor="w")
        self.stat_labels[key] = l

    def entry(self, parent, placeholder=""):
        e = tk.Entry(parent, font=("Segoe UI", 10), bg=self.input, fg=self.text, insertbackground=self.text, relief="flat", bd=0)
        if placeholder:
            e.insert(0, placeholder)
            e.bind("<FocusIn>", lambda ev, p=placeholder: self.clear_placeholder(ev, p))
            e.bind("<FocusOut>", lambda ev, p=placeholder: self.restore_placeholder(ev, p))
        return e

    def clear_placeholder(self, e, p):
        if e.get() == p:
            e.delete(0, "end")

    def restore_placeholder(self, e, p):
        if not e.get():
            e.insert(0, p)

    def combo(self, parent, var, values, width):
        return ttk.Combobox(parent, textvariable=var, values=values, state="readonly", width=width)

    def valid_date(self, value, include_time=False):
        try:
            datetime.strptime(value, "%Y-%m-%d %H:%M" if include_time else "%Y-%m-%d")
            return True
        except ValueError:
            return False

    def add_task(self):
        title = self.title_entry.get().strip()
        if title == "New task title...":
            title = ""
        if not title:
            messagebox.showwarning("Missing title", "Enter a task title.")
            return
        due = self.due.get().strip()
        if due == "Due YYYY-MM-DD":
            due = ""
        if due and not self.valid_date(due):
            messagebox.showerror("Invalid date", "Use YYYY-MM-DD for the due date.")
            return
        reminder = self.reminder_at.get().strip()
        if reminder == "Alarm YYYY-MM-DD HH:MM":
            reminder = ""
        enabled = self.reminder_enabled.get()
        if enabled and not reminder:
            messagebox.showwarning("Alarm time missing", "Enter a reminder date and time.")
            return
        if reminder and not self.valid_date(reminder, True):
            messagebox.showerror("Invalid alarm", "Use YYYY-MM-DD HH:MM for the alarm.")
            return
        if enabled and datetime.strptime(reminder, "%Y-%m-%d %H:%M") <= datetime.now():
            messagebox.showwarning("Alarm time", "Choose a future reminder time.")
            return
        self.db.add_task(title, "", self.category.get(), "", self.priority.get(), due, reminder, enabled)
        self.title_entry.delete(0, "end")
        self.due.set("")
        self.reminder_at.set("")
        self.reminder_enabled.set(False)
        self.refresh()

    def selected_ids(self):
        return [int(self.tree.item(i)["values"][0]) for i in self.tree.selection()]

    def complete_selected(self):
        ids = self.selected_ids()
        if ids:
            self.db.bulk_complete(ids)
            self.refresh()

    def favorite_selected(self):
        for i in self.selected_ids():
            self.db.toggle_favorite(i)
        self.refresh()

    def delete_selected(self):
        ids = self.selected_ids()
        if ids and messagebox.askyesno("Delete", "Delete selected task(s)?"):
            self.db.bulk_delete(ids)
            self.refresh()

    def clear_completed(self):
        if messagebox.askyesno("Clear", "Delete every completed task?"):
            self.db.clear_completed()
            self.refresh()

    def edit_selected(self):
        ids = self.selected_ids()
        if len(ids) != 1:
            messagebox.showinfo("Edit", "Select exactly one task.")
            return
        t = self.db.get_task(ids[0])
        d = tk.Toplevel(self.root)
        d.title("Edit Task")
        d.geometry("560x620")
        d.configure(bg=self.bg)
        d.resizable(False, False)
        fields = {}
        for label, key in [("Title", "title"), ("Description", "description"), ("Category", "category"), ("Tags", "tags"), ("Priority", "priority"), ("Due date", "due_date"), ("Reminder", "reminder_at")]:
            tk.Label(d, text=label, bg=self.bg, fg=self.text, font=("Segoe UI", 9, "bold")).pack(anchor="w", padx=28, pady=(10, 2))
            if key == "description":
                w = tk.Text(d, height=4, bg=self.input, fg=self.text, insertbackground=self.text, relief="flat")
                w.pack(fill="x", padx=28)
                w.insert("1.0", t[key] or "")
            elif key in ("category", "priority"):
                var = tk.StringVar(value=t[key])
                values = ["Personal", "Work", "Study", "Shopping", "Health", "Project"] if key == "category" else ["Low", "Medium", "High"]
                w = self.combo(d, var, values, 15)
                w.pack(anchor="w", padx=28)
                fields[key] = (w, var)
            else:
                w = self.entry(d)
                w.pack(fill="x", padx=28, ipady=7)
                w.insert(0, t[key] or "")
                fields[key] = w
        enabled = tk.BooleanVar(value=bool(t["reminder_enabled"]))
        tk.Checkbutton(d, text="Enable alarm reminder", variable=enabled, bg=self.bg, fg=self.text, selectcolor=self.input, activebackground=self.bg, activeforeground=self.text, font=("Segoe UI", 9, "bold")).pack(anchor="w", padx=28, pady=10)

        def save():
            title = fields["title"].get().strip()
            if not title:
                messagebox.showwarning("Invalid", "Title is required.")
                return
            description_widgets = [x for x in d.winfo_children() if isinstance(x, tk.Text)]
            description = description_widgets[0].get("1.0", "end-1c") if description_widgets else ""
            category = fields["category"][1].get()
            priority = fields["priority"][1].get()
            tags = fields["tags"].get().strip()
            due = fields["due_date"].get().strip()
            reminder = fields["reminder_at"].get().strip()
            if due and not self.valid_date(due):
                messagebox.showerror("Invalid date", "Use YYYY-MM-DD for the due date.")
                return
            if enabled.get() and (not reminder or not self.valid_date(reminder, True)):
                messagebox.showerror("Invalid alarm", "Use YYYY-MM-DD HH:MM for the alarm.")
                return
            if enabled.get() and datetime.strptime(reminder, "%Y-%m-%d %H:%M") <= datetime.now():
                messagebox.showwarning("Alarm time", "Choose a future reminder time.")
                return
            self.db.update_task(t["id"], title, description, category, tags, priority, due, reminder, enabled.get())
            d.destroy()
            self.refresh()

        self.button(d, "Save Changes", save, self.accent).pack(pady=18)

    def refresh(self):
        for i in self.tree.get_children():
            self.tree.delete(i)
        rows = self.db.get_tasks(self.search.get() if hasattr(self, "search") else "", self.status.get() if hasattr(self, "status") else "All", self.cat_filter.get() if hasattr(self, "cat_filter") else "All", self.pri_filter.get() if hasattr(self, "pri_filter") else "All", self.favorites.get() if hasattr(self, "favorites") else False, self.sort.get() if hasattr(self, "sort") else "created_at DESC")
        for t in rows:
            tags = ["completed"] if t["completed"] else [t["priority"].lower()]
            if t["reminder_enabled"] and t["reminder_at"]:
                tags.append("alarm")
            self.tree.insert("", "end", values=(t["id"], "✓ Done" if t["completed"] else "○ Pending", "★" if t["favorite"] else "", t["title"], t["category"], t["priority"], t["due_date"] or "-", t["reminder_at"] or "-", t["tags"]), tags=tuple(tags))
        s = self.db.stats()
        keys = ["total", "completed", "pending", "high", "favorite", "overdue", "reminders"]
        for k, v in zip(keys, s):
            self.stat_labels[k].config(text=str(v))

    def toggle_theme(self):
        self.dark = not self.dark
        self.setup_colors()
        self.style()
        for widget in self.root.winfo_children():
            self.recolor(widget)
        self.refresh()

    def recolor(self, w):
        try:
            if isinstance(w, (tk.Frame, tk.Label, tk.Checkbutton)):
                w.configure(bg=self.bg)
            if isinstance(w, tk.Label):
                w.configure(fg=self.text)
            if isinstance(w, tk.Checkbutton):
                w.configure(fg=self.text, selectcolor=self.card, activebackground=self.bg, activeforeground=self.text)
            if isinstance(w, tk.Button):
                current = w.cget("bg")
                if current in ("#111827", "#ffffff", self.card):
                    w.configure(bg=self.card, fg=self.text, activebackground=self.input, activeforeground=self.text)
        except tk.TclError:
            pass
        for c in w.winfo_children():
            self.recolor(c)

    def export_csv(self):
        path = filedialog.asksaveasfilename(defaultextension=".csv", filetypes=[("CSV", "*.csv")], initialfile="roshab_tasks.csv")
        if not path:
            return
        rows = self.db.export_rows()
        with open(path, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow(rows[0].keys() if rows else ["title"])
            writer.writerows([tuple(r) for r in rows])
        messagebox.showinfo("Export complete", f"Saved {len(rows)} tasks.")

    def import_csv(self):
        path = filedialog.askopenfilename(filetypes=[("CSV", "*.csv")])
        if not path:
            return
        with open(path, newline="", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                title = row.get("title", "").strip()
                if title:
                    self.db.add_task(title, row.get("description", ""), row.get("category", "Personal"), row.get("tags", ""), row.get("priority", "Medium"), row.get("due_date", ""), row.get("reminder_at", ""), row.get("reminder_enabled", "0") in ("1", "true", "True"))
        self.refresh()
        messagebox.showinfo("Import complete", "Tasks imported successfully.")

    def show_shortcuts(self):
        messagebox.showinfo("Roshab Tasks", "Ctrl+N  New task\nCtrl+F  Focus search\nDelete  Delete selected\nCtrl+E  Export CSV\nDouble-click  Edit task\n\nReminder format: YYYY-MM-DD HH:MM\n\nDeveloped by Roshab Bhandari\nLocal SQLite storage — no cloud account required.")

    def open_editor(self):
        self.title_entry.focus_set()

    def play_alarm(self):
        if winsound:
            for _ in range(2):
                winsound.MessageBeep(winsound.MB_ICONEXCLAMATION)

    def reminder_check(self):
        try:
            due = self.db.due_reminders()
            for task in due:
                self.db.mark_reminder_sent(task["id"])
                self.play_alarm()
                self.root.bell()
                messagebox.showwarning("⏰ Roshab Tasks Reminder", f"{task['title']}\n\nScheduled for {task['reminder_at']}")
            overdue = self.db.stats()[5]
            reminders = self.db.stats()[6]
            self.root.title(f"Roshab Tasks • {overdue} overdue • {reminders} alarms")
        finally:
            self.root.after(10000, self.reminder_check)


if __name__ == "__main__":
    root = tk.Tk()
    app = TaskFlowPro(root)
    root.mainloop()
