from Tkinter import *
from blanke_widgets import bEntry

class Searchbar:
	def __init__(self, app):
		self.app = app

		# onChange variable
		change_ev = StringVar()
		change_ev.trace("w", lambda name, index, mode, sv=change_ev: self.onChange(change_ev))

		# create Entry input
		self.entry = bEntry(self.app, self.app.frame('searchbar'), textvariable=change_ev)
		self.entry.insert(0, 'Search')
		self.entry.pack(fill=X)

		self.entry.bind('<Control-a>', self.selectAll)

	def onChange(self, ev):
		print ev.get()

	def selectAll(self):
		pass#self.