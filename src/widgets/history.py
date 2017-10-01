from Tkinter import *
from blanke_widgets import bButton, bFrame, bLabel

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

		self.history.app.font('history_arrow', {'family':'Calibri', 'size':12, 'weight':'bold'})

		self.container = bFrame(self.history.app, self.history.app.frame('history'))
		self.arrow = bLabel(self.history.app, self.container,
			text='>',
			font=self.history.app.font('history_arrow'),
			fg='#263238',
			bd=1
		)
		self.button = bButton(self.history.app, self.container, text=label, command=self.fn_onClick)

		# button events
		self.button.bind('<Button-3>', self.destroy)

		self.button.pack(side=RIGHT)
		self.setArrow(self.has_arrow)

		self.container.pack(side=LEFT)

	def setArrow(self, value):
		self.has_arrow = value
		if value:
			self.arrow.pack(side=LEFT, ipady=0)
		else:
			self.arrow.pack_forget()

	def destroy(self, ev=None):
		self.container.destroy()