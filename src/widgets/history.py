from Tkinter import *
from blanke_widgets import bButton, bFrame

class History:
	def __init__(self, app):
		self.app = app
		self.entries = []
		self.max_entries = 10

		def anotherEntry(ev=None):
			self.addEntry("another"+str(len(self.entries)), anotherEntry)
		self.addEntry("test", anotherEntry)

	def addEntry(self, label, fn_onClick=None):
		self.entries.append(Entry(self, label, fn_onClick))

		# remove excess entries
		if len(self.entries) > self.max_entries:
			self.entries[0].destroy()
			del self.entries[0]

		# reload arrows for each entry
		for e, entry in enumerate(self.entries):
			if e == 0:
				entry.setArrow(False)
			else:
				entry.setArrow(True)

class Entry:
	def __init__(self, history, label, fn_onClick=None):
		self.history = history
		self.label = label
		self.fn_onClick = fn_onClick
		self.has_arrow = True

		self.container = bFrame(self.history.app, self.history.app.frame('history'))
		self.arrow = bButton(self.history.app, self.container, text='>')
		self.button = bButton(self.history.app, self.container, text=label)

		# button events
		self.button.bind('<Button-1>', self.fn_onClick)
		self.button.bind('<Button-3>', self.destroy)

		self.button.pack(side=RIGHT)
		self.setArrow(self.has_arrow)

		self.container.pack(side=LEFT)

	def setArrow(self, value):
		self.has_arrow = value
		if value:
			self.arrow.pack(side=LEFT)
		else:
			self.arrow.pack_forget()

	def destroy(self, ev=None):
		self.container.destroy()