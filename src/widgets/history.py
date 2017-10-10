from Tkinter import *
from blanke_widgets import bButton, bFrame, bLabel

class History:
	def __init__(self, app):
		self.app = app
		self.entries = []
		self.max_entries = 10

		self.app.event.on('ide.ready', self.addSearchKeys)
        
	def addSearchKeys(self):
		el_searchbar = self.app.element('searchbar')
		clearHistory = el_searchbar.addKey(text="clearHistory", category="History", onSelect=self.clear, icon="H")

	def addEntry(self, label, fn_onClick=None, onClickArgs={}):
		if len(self.entries) > 0 and self.entries[-1].label == label:
			return

		new_entry = Entry(self, label, fn_onClick, onClickArgs)
		self.entries.append(new_entry)

		# remove excess entries
		if len(self.entries) > self.max_entries:
			self.entries[0].destroy()
			del self.entries[0]

		# remove duplicate entry
		for e, entry in enumerate(self.entries):
			if entry.label == new_entry.label and e != len(self.entries)-1:
				self.entries[e].destroy()
				del self.entries[e]

		# reload arrows for each entry
		for e, entry in enumerate(self.entries):
			if e == 0:
				entry.setArrow(False)
			else:
				entry.setArrow(True)

	def clear(self):
		for entry in self.entries:
			entry.destroy()
		del self.entries[:]

class Entry:
	def __init__(self, history, label, fn_onClick=None, onClickArgs={}):
		self.history = history
		self.label = label
		self.fn_onClick = fn_onClick
		self.onClickArgs = onClickArgs
		self.has_arrow = True

		self.history.app.font('history_arrow', {'family':'Calibri', 'size':12, 'weight':'bold'})

		self.container = bFrame(self.history.app, self.history.app.frame('history'))
		self.arrow = bLabel(self.history.app, self.container,
			text='>',
			font=self.history.app.font('history_arrow'),
			fg='#263238',
			bd=1
		)
		self.button = bButton(self.history.app, self.container, text=label, command=self.onClick)

		# button events
		self.button.bind('<Button-3>', self.destroy)

		self.button.pack(side=RIGHT)
		self.setArrow(self.has_arrow)

		self.container.pack(side=LEFT)

	def onClick(self, ev=None):
		self.fn_onClick(**self.onClickArgs)

	def setArrow(self, value):
		self.has_arrow = value
		if value:
			self.arrow.pack(side=LEFT, ipady=0)
		else:
			self.arrow.pack_forget()

	def destroy(self, ev=None):
		self.container.destroy()