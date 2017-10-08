from Tkinter import *
from blanke_widgets import bText

class Code:
	def __init__(self, app):
		self.app = app
		if not self.app.setting('useExternalEditor'):
			workspace = self.app.frame('workspace')
			self.text = bText(self.app, workspace, width=workspace.winfo_width(), height=workspace.winfo_height())
			self.text.pack(fill=BOTH, expand=True)

	def openScript(self, filepath):
		if self.app.setting('useExternalEditor'):
			if self.app.os == "Windows":
				self.app.execute("start "+filepath)
			else:
				self.app.execute("open "+filepath)

		else:
			text = open(filepath, 'r').read()
			self.text.set(text)
