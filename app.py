import csv
import os
import tkinter as tk
from tkinter import ttk, messagebox, filedialog
from datetime import datetime
from database import Database


class TaskFlowPro:
    def __init__(self, root):
        self.root = root
        self.db = Database()
        self.dark = True
        self.root.title("TaskFlow Pro")
        self.root.geometry("1180x760")
        self.root.minsize(950, 620)
        self.setup_colors()
        self.build()
        self.refresh()
        self.root.bind("<Control-n>", lambda e: self.open_editor())
        self.root.bind("<Control-f>", lambda e: self.search.focus_set())
        self.root.bind("<Delete>", lambda e: self.delete_selected())
        self.root.bind("<Control-e>", lambda e: self.export_csv())
        self.root.after(60000, self.reminder_check)

    def setup_colors(self):
        if self.dark:
            self.bg,self.card,self.input,self.text,self.muted,self.accent = "#0f172a","#1e293b","#334155","#f8fafc","#94a3b8","#6366f1"
        else:
            self.bg,self.card,self.input,self.text,self.muted,self.accent = "#f1f5f9","#ffffff","#e2e8f0","#0f172a","#64748b","#4f46e5"
        self.root.configure(bg=self.bg)

    def style(self):
        s=ttk.Style(); s.theme_use("clam")
        s.configure("Treeview",background=self.card,foreground=self.text,fieldbackground=self.card,rowheight=38,font=("Segoe UI",10),borderwidth=0)
        s.configure("Treeview.Heading",background=self.input,foreground=self.text,font=("Segoe UI",9,"bold"),padding=9)
        s.map("Treeview",background=[("selected",self.accent)],foreground=[("selected","white")])
        s.configure("TCombobox",fieldbackground=self.input,background=self.input,foreground=self.text)

    def build(self):
        self.style()
        top=tk.Frame(self.root,bg=self.bg); top.pack(fill="x",padx=24,pady=(18,10))
        tk.Label(top,text="TaskFlow Pro",font=("Segoe UI",28,"bold"),bg=self.bg,fg=self.text).pack(side="left")
        tk.Label(top,text="  Advanced Productivity Manager",font=("Segoe UI",11),bg=self.bg,fg=self.muted).pack(side="left",pady=(12,0))
        tk.Button(top,text="☾ Theme",command=self.toggle_theme,bg=self.card,fg=self.text,relief="flat",padx=14,pady=7).pack(side="right")
        tk.Button(top,text="⚙ Settings",command=self.show_shortcuts,bg=self.card,fg=self.text,relief="flat",padx=14,pady=7).pack(side="right",padx=8)

        self.stats_frame=tk.Frame(self.root,bg=self.bg); self.stats_frame.pack(fill="x",padx=24,pady=7)
        self.stat_labels={}
        for key,label in [("total","TOTAL"),("completed","DONE"),("pending","PENDING"),("high","HIGH"),("favorite","FAVORITES"),("overdue","OVERDUE")]:
            self.stat_card(key,label)

        add=tk.Frame(self.root,bg=self.card,padx=14,pady=14); add.pack(fill="x",padx=24,pady=10)
        self.title_entry=self.entry(add,"New task title..."); self.title_entry.pack(side="left",fill="x",expand=True,ipady=9)
        self.priority=tk.StringVar(value="Medium"); self.combo(add,self.priority,["Low","Medium","High"],10).pack(side="left",padx=7)
        self.category=tk.StringVar(value="Personal"); self.combo(add,self.category,["Personal","Work","Study","Shopping","Health","Project"],11).pack(side="left",padx=7)
        self.due=tk.StringVar(); de=self.entry(add,"YYYY-MM-DD"); de.configure(textvariable=self.due); de.pack(side="left",width=115,ipady=9,padx=7)
        tk.Button(add,text="＋ Add Task",command=self.add_task,bg=self.accent,fg="white",relief="flat",font=("Segoe UI",10,"bold"),padx=16,pady=8).pack(side="left")
        self.title_entry.bind("<Return>",lambda e:self.add_task())

        tools=tk.Frame(self.root,bg=self.bg); tools.pack(fill="x",padx=24,pady=(4,10))
        self.search=self.entry(tools,"Search title, description or tags..."); self.search.pack(side="left",fill="x",expand=True,ipady=8); self.search.bind("<KeyRelease>",lambda e:self.refresh())
        self.status=tk.StringVar(value="All"); self.combo(tools,self.status,["All","Pending","Completed"],12).pack(side="left",padx=6)
        self.cat_filter=tk.StringVar(value="All"); self.combo(tools,self.cat_filter,["All","Personal","Work","Study","Shopping","Health","Project"],12).pack(side="left",padx=6)
        self.pri_filter=tk.StringVar(value="All"); self.combo(tools,self.pri_filter,["All","High","Medium","Low"],9).pack(side="left",padx=6)
        self.sort=tk.StringVar(value="created_at DESC"); self.combo(tools,self.sort,["created_at DESC","due_date ASC","priority","title"],15).pack(side="left",padx=6)
        self.favorites=tk.BooleanVar(value=False); tk.Checkbutton(tools,text="★ Favorites",variable=self.favorites,command=self.refresh,bg=self.bg,fg=self.text,selectcolor=self.card,activebackground=self.bg,activeforeground=self.text).pack(side="left")

        table=tk.Frame(self.root,bg=self.bg); table.pack(fill="both",expand=True,padx=24)
        cols=("id","done","favorite","title","category","priority","due","tags")
        self.tree=ttk.Treeview(table,columns=cols,show="headings",selectmode="extended")
        heads={"id":"#","done":"STATUS","favorite":"★","title":"TASK","category":"CATEGORY","priority":"PRIORITY","due":"DUE","tags":"TAGS"}
        widths={"id":45,"done":90,"favorite":45,"title":390,"category":110,"priority":90,"due":105,"tags":170}
        for c in cols:self.tree.heading(c,text=heads[c]);self.tree.column(c,width=widths[c],anchor="center" if c in ("id","done","favorite","priority","due") else "w")
        self.tree.pack(side="left",fill="both",expand=True); sb=ttk.Scrollbar(table,orient="vertical",command=self.tree.yview); sb.pack(side="right",fill="y"); self.tree.configure(yscrollcommand=sb.set)
        self.tree.bind("<Double-1>",lambda e:self.edit_selected())

        bottom=tk.Frame(self.root,bg=self.bg); bottom.pack(fill="x",padx=24,pady=14)
        for text,cmd,color in [("✓ Complete",self.complete_selected,"#16a34a"),("✎ Edit",self.edit_selected,self.accent),("★ Favorite",self.favorite_selected,"#d97706"),("Delete",self.delete_selected,"#dc2626"),("Clear Done",self.clear_completed,"#7c3aed")]:
            tk.Button(bottom,text=text,command=cmd,bg=color,fg="white",relief="flat",font=("Segoe UI",9,"bold"),padx=12,pady=7).pack(side="left",padx=4)
        tk.Button(bottom,text="Import CSV",command=self.import_csv,bg=self.card,fg=self.text,relief="flat",padx=12,pady=7).pack(side="right",padx=4)
        tk.Button(bottom,text="Export CSV",command=self.export_csv,bg=self.card,fg=self.text,relief="flat",padx=12,pady=7).pack(side="right",padx=4)

    def stat_card(self,key,title):
        f=tk.Frame(self.stats_frame,bg=self.card,padx=16,pady=10); f.pack(side="left",fill="x",expand=True,padx=4)
        tk.Label(f,text=title,font=("Segoe UI",8,"bold"),bg=self.card,fg=self.muted).pack(anchor="w")
        l=tk.Label(f,text="0",font=("Segoe UI",18,"bold"),bg=self.card,fg=self.text); l.pack(anchor="w"); self.stat_labels[key]=l

    def entry(self,parent,placeholder=""):
        e=tk.Entry(parent,font=("Segoe UI",10),bg=self.input,fg=self.text,insertbackground=self.text,relief="flat")
        if placeholder:e.insert(0,placeholder); e.bind("<FocusIn>",lambda ev,p=placeholder:self.clear_placeholder(ev,p)); e.bind("<FocusOut>",lambda ev,p=placeholder:self.restore_placeholder(ev,p))
        return e

    def clear_placeholder(self,e,p):
        if e.get()==p:e.delete(0,"end")
    def restore_placeholder(self,e,p):
        if not e.get():e.insert(0,p)
    def combo(self,parent,var,values,width): return ttk.Combobox(parent,textvariable=var,values=values,state="readonly",width=width)

    def add_task(self):
        title=self.title_entry.get().strip()
        if title=="New task title...": title=""
        if not title: messagebox.showwarning("Missing title","Enter a task title."); return
        due=self.due.get().strip()
        if due and due!="YYYY-MM-DD":
            try: datetime.strptime(due,"%Y-%m-%d")
            except ValueError: messagebox.showerror("Invalid date","Use YYYY-MM-DD."); return
        else: due=""
        self.db.add_task(title,"",self.category.get(),"",self.priority.get(),due); self.title_entry.delete(0,"end"); self.refresh()

    def selected_ids(self): return [int(self.tree.item(i)["values"][0]) for i in self.tree.selection()]
    def complete_selected(self):
        ids=self.selected_ids()
        if ids:self.db.bulk_complete(ids); self.refresh()
    def favorite_selected(self):
        for i in self.selected_ids():self.db.toggle_favorite(i)
        self.refresh()
    def delete_selected(self):
        ids=self.selected_ids()
        if ids and messagebox.askyesno("Delete","Delete selected task(s)?"):self.db.bulk_delete(ids);self.refresh()
    def clear_completed(self):
        if messagebox.askyesno("Clear","Delete every completed task?"):self.db.clear_completed();self.refresh()

    def edit_selected(self):
        ids=self.selected_ids()
        if len(ids)!=1: messagebox.showinfo("Edit","Select exactly one task."); return
        t=self.db.get_task(ids[0]); d=tk.Toplevel(self.root);d.title("Edit Task");d.geometry("520x430");d.configure(bg=self.bg);d.resizable(False,False)
        fields={}
        for label,key in [("Title","title"),("Description","description"),("Category","category"),("Tags","tags"),("Priority","priority"),("Due date","due_date")]:
            tk.Label(d,text=label,bg=self.bg,fg=self.text,font=("Segoe UI",9,"bold")).pack(anchor="w",padx=28,pady=(10,2))
            if key=="description":
                w=tk.Text(d,height=4,bg=self.input,fg=self.text,insertbackground=self.text,relief="flat");w.pack(fill="x",padx=28);w.insert("1.0",t[key])
            elif key in ("category","priority"):
                var=tk.StringVar(value=t[key]);w=self.combo(d,var,["Personal","Work","Study","Shopping","Health","Project"] if key=="category" else ["Low","Medium","High"],15);w.pack(anchor="w",padx=28);fields[key]=(w,var)
            else:
                w=self.entry(d);w.pack(fill="x",padx=28,ipady=7);w.insert(0,t[key]);fields[key]=w
        def save():
            title=fields["title"].get().strip()
            if not title: messagebox.showwarning("Invalid","Title is required.");return
            desc=d.winfo_children()[0] if False else None
            # description is the Text widget directly above the category label
            widgets=[x for x in d.winfo_children() if isinstance(x,tk.Text)]
            description=widgets[0].get("1.0","end-1c") if widgets else ""
            category=fields["category"][1].get(); priority=fields["priority"][1].get(); tags=fields["tags"].get().strip(); due=fields["due_date"].get().strip()
            self.db.update_task(t["id"],title,description,category,tags,priority,due);d.destroy();self.refresh()
        tk.Button(d,text="Save Changes",command=save,bg=self.accent,fg="white",relief="flat",font=("Segoe UI",10,"bold"),padx=20,pady=8).pack(pady=18)

    def refresh(self):
        for i in self.tree.get_children():self.tree.delete(i)
        rows=self.db.get_tasks(self.search.get() if hasattr(self,"search") else "",self.status.get() if hasattr(self,"status") else "All",self.cat_filter.get() if hasattr(self,"cat_filter") else "All",self.pri_filter.get() if hasattr(self,"pri_filter") else "All",self.favorites.get() if hasattr(self,"favorites") else False,self.sort.get() if hasattr(self,"sort") else "created_at DESC")
        for t in rows:self.tree.insert("","end",values=(t["id"],"✓ Done" if t["completed"] else "○ Pending","★" if t["favorite"] else "",t["title"],t["category"],t["priority"],t["due_date"] or "-",t["tags"]))
        s=self.db.stats(); keys=["total","completed","pending","high","favorite","overdue"]
        for k,v in zip(keys,s):self.stat_labels[k].config(text=str(v))

    def toggle_theme(self):
        self.dark=not self.dark; self.setup_colors();
        for w in self.root.winfo_children(): self.recolor(w)
        self.style();self.refresh()
    def recolor(self,w):
        try:
            if isinstance(w,(tk.Frame,tk.Label,tk.Checkbutton)):w.configure(bg=self.bg); 
            if isinstance(w,tk.Label):w.configure(fg=self.text)
        except tk.TclError:pass
        for c in w.winfo_children():self.recolor(c)

    def export_csv(self):
        path=filedialog.asksaveasfilename(defaultextension=".csv",filetypes=[("CSV","*.csv")],initialfile="taskflow_tasks.csv")
        if not path:return
        rows=self.db.export_rows();
        with open(path,"w",newline="",encoding="utf-8") as f:
            writer=csv.writer(f);writer.writerow(rows[0].keys() if rows else ["title"]);writer.writerows([tuple(r) for r in rows])
        messagebox.showinfo("Export complete",f"Saved {len(rows)} tasks.")
    def import_csv(self):
        path=filedialog.askopenfilename(filetypes=[("CSV","*.csv")]);
        if not path:return
        with open(path,newline="",encoding="utf-8") as f:
            for row in csv.DictReader(f):
                title=row.get("title","").strip()
                if title:self.db.add_task(title,row.get("description", ""),row.get("category","Personal"),row.get("tags",""),row.get("priority","Medium"),row.get("due_date",""))
        self.refresh();messagebox.showinfo("Import complete","Tasks imported successfully.")
    def show_shortcuts(self):
        messagebox.showinfo("TaskFlow Pro","Ctrl+N  New task\nCtrl+F  Focus search\nDelete  Delete selected\nCtrl+E  Export CSV\nDouble-click  Edit task\n\nSQLite database is stored locally as taskflow.db.")
    def reminder_check(self):
        try:
            overdue=self.db.stats()[-1]
            if overdue: self.root.title(f"TaskFlow Pro • {overdue} overdue task(s)")
        finally:self.root.after(60000,self.reminder_check)


if __name__ == "__main__":
    root=tk.Tk(); app=TaskFlowPro(root); root.mainloop()
