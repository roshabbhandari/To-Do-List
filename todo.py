import tkinter as tk
from tkinter import ttk, messagebox
import json
import os
from datetime import datetime

DATA_FILE = "tasks.json"


class TodoApp:
    def __init__(self, root):
        self.root = root
        self.root.title("TaskFlow - To-Do Manager")
        self.root.geometry("1000x650")
        self.root.minsize(850, 550)

        self.tasks = []
        self.filtered_tasks = []

        self.load_tasks()
        self.setup_style()
        self.create_ui()
        self.refresh_tasks()

        self.root.bind("<Control-n>", lambda e: self.focus_task_entry())
        self.root.bind("<Delete>", lambda e: self.delete_selected())
        self.root.bind("<Control-s>", lambda e: self.save_tasks())

    def setup_style(self):
        self.bg = "#111827"
        self.card = "#1f2937"
        self.card2 = "#374151"
        self.text = "#f9fafb"
        self.muted = "#9ca3af"
        self.accent = "#6366f1"
        self.success = "#22c55e"
        self.danger = "#ef4444"
        self.warning = "#f59e0b"

        self.root.configure(bg=self.bg)
        style = ttk.Style()
        style.theme_use("clam")
        style.configure("Treeview", background=self.card, foreground=self.text,
                        fieldbackground=self.card, rowheight=38, borderwidth=0,
                        font=("Segoe UI", 10))
        style.configure("Treeview.Heading", background=self.card2,
                        foreground=self.text, font=("Segoe UI", 10, "bold"), padding=10)
        style.map("Treeview", background=[("selected", self.accent)],
                  foreground=[("selected", "white")])

    def create_ui(self):
        header = tk.Frame(self.root, bg=self.bg)
        header.pack(fill="x", padx=25, pady=(20, 10))
        tk.Label(header, text="TaskFlow", font=("Segoe UI", 28, "bold"),
                 bg=self.bg, fg=self.text).pack(side="left")
        tk.Label(header, text="  Personal Task Manager", font=("Segoe UI", 11),
                 bg=self.bg, fg=self.muted).pack(side="left", pady=(12, 0))

        stats = tk.Frame(self.root, bg=self.bg)
        stats.pack(fill="x", padx=25, pady=10)
        self.total_label = self.create_stat_card(stats, "TOTAL", "0")
        self.completed_label = self.create_stat_card(stats, "COMPLETED", "0")
        self.pending_label = self.create_stat_card(stats, "PENDING", "0")
        self.high_label = self.create_stat_card(stats, "HIGH PRIORITY", "0")

        add_frame = tk.Frame(self.root, bg=self.card, padx=15, pady=15)
        add_frame.pack(fill="x", padx=25, pady=10)
        self.task_entry = tk.Entry(add_frame, font=("Segoe UI", 11), bg=self.card2,
                                   fg=self.text, insertbackground=self.text, relief="flat")
        self.task_entry.pack(side="left", fill="x", expand=True, ipady=10)

        self.priority_var = tk.StringVar(value="Medium")
        priority = ttk.Combobox(add_frame, textvariable=self.priority_var,
                                values=["Low", "Medium", "High"], state="readonly", width=10)
        priority.pack(side="left", padx=10)

        self.date_entry = tk.Entry(add_frame, width=12, font=("Segoe UI", 10),
                                   bg=self.card2, fg=self.text,
                                   insertbackground=self.text, relief="flat")
        self.date_entry.insert(0, "YYYY-MM-DD")
        self.date_entry.pack(side="left", padx=5, ipady=9)

        tk.Button(add_frame, text="+ Add Task", command=self.add_task, bg=self.accent,
                  fg="white", activebackground="#4f46e5", activeforeground="white",
                  font=("Segoe UI", 10, "bold"), relief="flat", cursor="hand2",
                  padx=18, pady=8).pack(side="left", padx=(10, 0))
        self.task_entry.bind("<Return>", lambda e: self.add_task())

        toolbar = tk.Frame(self.root, bg=self.bg)
        toolbar.pack(fill="x", padx=25, pady=(5, 10))
        self.search_var = tk.StringVar()
        tk.Entry(toolbar, textvariable=self.search_var, font=("Segoe UI", 10),
                 bg=self.card, fg=self.text, insertbackground=self.text,
                 relief="flat").pack(side="left", fill="x", expand=True, ipady=9)
        self.search_var.trace_add("write", lambda *args: self.refresh_tasks())

        self.filter_var = tk.StringVar(value="All")
        filter_box = ttk.Combobox(toolbar, textvariable=self.filter_var,
                                  values=["All", "Pending", "Completed", "High", "Medium", "Low"],
                                  state="readonly", width=15)
        filter_box.pack(side="left", padx=10)
        filter_box.bind("<<ComboboxSelected>>", lambda e: self.refresh_tasks())

        table_frame = tk.Frame(self.root, bg=self.bg)
        table_frame.pack(fill="both", expand=True, padx=25)
        columns = ("status", "task", "priority", "due", "created")
        self.tree = ttk.Treeview(table_frame, columns=columns, show="headings", selectmode="browse")
        for col, heading in zip(columns, ["STATUS", "TASK", "PRIORITY", "DUE DATE", "CREATED"]):
            self.tree.heading(col, text=heading)
        self.tree.column("status", width=100, anchor="center")
        self.tree.column("task", width=400)
        self.tree.column("priority", width=110, anchor="center")
        self.tree.column("due", width=120, anchor="center")
        self.tree.column("created", width=130, anchor="center")
        self.tree.pack(side="left", fill="both", expand=True)
        scrollbar = ttk.Scrollbar(table_frame, orient="vertical", command=self.tree.yview)
        scrollbar.pack(side="right", fill="y")
        self.tree.configure(yscrollcommand=scrollbar.set)
        self.tree.bind("<Double-1>", lambda e: self.toggle_task())

        buttons = tk.Frame(self.root, bg=self.bg)
        buttons.pack(fill="x", padx=25, pady=15)
        self.make_button(buttons, "✓ Complete", self.toggle_task, self.success).pack(side="left", padx=(0, 8))
        self.make_button(buttons, "✎ Edit", self.edit_task, self.accent).pack(side="left", padx=8)
        self.make_button(buttons, "Delete", self.delete_selected, self.danger).pack(side="left", padx=8)
        self.make_button(buttons, "Clear Completed", self.clear_completed, self.warning).pack(side="right")

    def create_stat_card(self, parent, title, value):
        frame = tk.Frame(parent, bg=self.card, padx=20, pady=12)
        frame.pack(side="left", fill="x", expand=True, padx=5)
        tk.Label(frame, text=title, font=("Segoe UI", 9, "bold"),
                 bg=self.card, fg=self.muted).pack(anchor="w")
        label = tk.Label(frame, text=value, font=("Segoe UI", 20, "bold"),
                         bg=self.card, fg=self.text)
        label.pack(anchor="w")
        return label

    def make_button(self, parent, text, command, color):
        return tk.Button(parent, text=text, command=command, bg=color, fg="white",
                         activebackground=color, activeforeground="white",
                         font=("Segoe UI", 9, "bold"), relief="flat", cursor="hand2",
                         padx=15, pady=7)

    def add_task(self):
        task_text = self.task_entry.get().strip()
        if not task_text:
            messagebox.showwarning("Missing Task", "Please enter a task.")
            return

        due_date = self.date_entry.get().strip()
        if due_date == "YYYY-MM-DD":
            due_date = ""
        if due_date:
            try:
                datetime.strptime(due_date, "%Y-%m-%d")
            except ValueError:
                messagebox.showerror("Invalid Date", "Use YYYY-MM-DD format.")
                return

        self.tasks.append({
            "id": datetime.now().timestamp(),
            "task": task_text,
            "completed": False,
            "priority": self.priority_var.get(),
            "due": due_date,
            "created": datetime.now().strftime("%Y-%m-%d")
        })
        self.save_tasks()
        self.task_entry.delete(0, tk.END)
        self.refresh_tasks()

    def toggle_task(self):
        selected = self.tree.selection()
        if not selected:
            messagebox.showinfo("Select Task", "Please select a task first.")
            return
        task_id = self.tree.item(selected[0])["tags"][0]
        for task in self.tasks:
            if str(task["id"]) == task_id:
                task["completed"] = not task["completed"]
                break
        self.save_tasks()
        self.refresh_tasks()

    def delete_selected(self):
        selected = self.tree.selection()
        if not selected:
            messagebox.showinfo("Select Task", "Please select a task first.")
            return
        task_id = self.tree.item(selected[0])["tags"][0]
        self.tasks = [task for task in self.tasks if str(task["id"]) != task_id]
        self.save_tasks()
        self.refresh_tasks()

    def edit_task(self):
        selected = self.tree.selection()
        if not selected:
            messagebox.showinfo("Select Task", "Please select a task first.")
            return
        task_id = self.tree.item(selected[0])["tags"][0]
        task = next((t for t in self.tasks if str(t["id"]) == task_id), None)
        if not task:
            return

        dialog = tk.Toplevel(self.root)
        dialog.title("Edit Task")
        dialog.geometry("450x250")
        dialog.configure(bg=self.bg)
        dialog.resizable(False, False)
        tk.Label(dialog, text="Edit Task", font=("Segoe UI", 16, "bold"),
                 bg=self.bg, fg=self.text).pack(pady=15)
        entry = tk.Entry(dialog, font=("Segoe UI", 11), bg=self.card2,
                         fg=self.text, insertbackground=self.text, relief="flat")
        entry.insert(0, task["task"])
        entry.pack(fill="x", padx=30, ipady=10)

        def save_edit():
            new_text = entry.get().strip()
            if not new_text:
                messagebox.showwarning("Invalid", "Task cannot be empty.")
                return
            task["task"] = new_text
            self.save_tasks()
            self.refresh_tasks()
            dialog.destroy()

        tk.Button(dialog, text="Save Changes", command=save_edit, bg=self.accent,
                  fg="white", relief="flat", font=("Segoe UI", 10, "bold"),
                  padx=20, pady=8).pack(pady=20)
        entry.focus()

    def clear_completed(self):
        count = sum(1 for task in self.tasks if task["completed"])
        if count == 0:
            messagebox.showinfo("Nothing to Clear", "There are no completed tasks.")
            return
        if messagebox.askyesno("Clear Completed", f"Delete {count} completed task(s)?"):
            self.tasks = [task for task in self.tasks if not task["completed"]]
            self.save_tasks()
            self.refresh_tasks()

    def refresh_tasks(self):
        for item in self.tree.get_children():
            self.tree.delete(item)
        search_text = self.search_var.get().lower()
        filter_type = self.filter_var.get()
        filtered = []
        for task in self.tasks:
            if search_text not in task["task"].lower():
                continue
            if filter_type == "Pending" and task["completed"]:
                continue
            if filter_type == "Completed" and not task["completed"]:
                continue
            if filter_type in ["High", "Medium", "Low"] and task["priority"] != filter_type:
                continue
            filtered.append(task)
        self.filtered_tasks = filtered
        for task in filtered:
            self.tree.insert("", "end", values=(
                "✓ Done" if task["completed"] else "○ Pending",
                task["task"], task["priority"], task["due"] or "-", task["created"]
            ), tags=(str(task["id"]),))
        self.update_statistics()

    def update_statistics(self):
        total = len(self.tasks)
        completed = sum(1 for task in self.tasks if task["completed"])
        pending = total - completed
        high = sum(1 for task in self.tasks if task["priority"] == "High" and not task["completed"])
        self.total_label.config(text=str(total))
        self.completed_label.config(text=str(completed))
        self.pending_label.config(text=str(pending))
        self.high_label.config(text=str(high))

    def save_tasks(self):
        try:
            with open(DATA_FILE, "w", encoding="utf-8") as file:
                json.dump(self.tasks, file, indent=4, ensure_ascii=False)
        except Exception as error:
            messagebox.showerror("Save Error", f"Could not save tasks:\n{error}")

    def load_tasks(self):
        if not os.path.exists(DATA_FILE):
            self.tasks = []
            return
        try:
            with open(DATA_FILE, "r", encoding="utf-8") as file:
                self.tasks = json.load(file)
        except (json.JSONDecodeError, OSError):
            self.tasks = []

    def focus_task_entry(self):
        self.task_entry.focus_set()


if __name__ == "__main__":
    root = tk.Tk()
    app = TodoApp(root)
    root.mainloop()
