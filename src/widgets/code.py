from Tkinter import *
from blanke_widgets import bText

class Code:
	def __init__(self, app):
		self.app = app
		workspace = self.app.frame('workspace')
		self.text = bText(self.app, workspace, width=workspace.winfo_width(), height=workspace.winfo_height())
		self.text.pack(fill=BOTH, expand=True)