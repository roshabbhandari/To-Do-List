"""TaskFlow Pro launcher.

Run this file with: python todo.py
"""
import tkinter as tk
from app import TaskFlowPro


if __name__ == "__main__":
    root = tk.Tk()
    TaskFlowPro(root)
    root.mainloop()
