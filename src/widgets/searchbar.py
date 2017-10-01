from Tkinter import *
from blanke_widgets import bEntry, bFrame, bLabel

class Searchbar:
	def __init__(self, app):
		self.app = app
		self.results = []

		self.result_container = bFrame(self.app, self.app.frame('main'))
		self.result_container.place(x=0, y=self.app.frame('searchbar')['height'], relwidth=1, anchor=NW)

		self.result_frame = bFrame(self.app, self.result_container)
		self.result_frame.pack(padx=4, fill=BOTH)

		# onChange variable
		change_ev = StringVar()
		change_ev.trace("w", lambda name, index, mode, sv=change_ev: self.onChange(change_ev))

		# create Entry input
		self.entry = bEntry(self.app, self.app.frame('searchbar'), textvariable=change_ev)
		self.entry.insert(0, 'Search')
		self.entry.pack(fill=X)

		def onselect():
			print("hi there")
		self.addResult("run", "run demo", onselect)
		self.addResult("exit", "leave this thang", onselect)

	def onChange(self, ev):
		print ev.get()

	def addResult(self, text, tooltip, fn_onSelect):
		new_result = Result(self, text, tooltip, fn_onSelect)
		self.results.append(new_result)

class Result:
	def __init__(self, searchbar, text, tooltip, fn_onSelect):
		self.searchbar = searchbar
		self.app = self.searchbar.app
		self.text = text
		self.fn_onSelect = fn_onSelect

		result_row = bFrame(self.app, self.searchbar.result_frame) #, bd=1, relief='solid')

		result_text = bLabel(self.app, result_row, text=text, anchor='w')
		result_text.pack(side=LEFT, fill=X, expand=True)
		result_tooltip = bLabel(self.app, result_row, text=tooltip, fg=self.app.color('tooltip'))
		result_tooltip.pack(anchor=E, side=RIGHT)

		result_row.pack(side=TOP, fill=X, expand=True)