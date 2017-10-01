from Tkinter import *
from blanke_widgets import bEntry, bFrame, bLabel

class Searchbar:
	def __init__(self, app):
		self.app = app
		self.results = []
		self.selected_result = -1

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

		self.entry.bind('<Tab>', self.moveSelectionDown)
		self.entry.bind('<Return>', self.clickSelectedResult)

		def onselect():
			print("hi there")
		self.addResult("run", "run demo", onselect)
		self.addResult("exit", "leave this thang", onselect)
		self.addResult("exit", "leave this thang", onselect)
		self.addResult("exit", "leave this thang", onselect)

	def onChange(self, ev):
		print ev.get()

	def addResult(self, text, tooltip, fn_onSelect):
		new_result = Result(self, text, tooltip, fn_onSelect)
		self.results.append(new_result)
		return new_result

	def moveSelection(self):
		# wrap around bounds
		if self.selected_result < 0:
			self.selected_result = len(self.results)-1
		if self.selected_result >= len(self.results):
			self.selected_result = 0

		for r, result in enumerate(self.results):
			if r == self.selected_result:
				result.focus()
			else:
				result.unfocus()
		self.entry.focus_set()

	def moveSelectionDown(self, ev=None):
		if ev and ev.state == 9:
			self.moveSelectionUp()
			return 'break'
		self.selected_result += 1
		self.moveSelection()
		return 'break'

	def moveSelectionUp(self, ev=None):
		self.selected_result -= 1
		self.moveSelection()

	def clickSelectedResult(self, ev=None):
		for r, result in enumerate(self.results):
			result.select()

class Result:
	def __init__(self, searchbar, text, tooltip, fn_onSelect):
		self.searchbar = searchbar
		self.app = self.searchbar.app
		self.text = text
		self.focused = False
		self.fn_onSelect = fn_onSelect

		# setup result widgets
		self.result_row = bFrame(self.app, self.searchbar.result_frame, relief='solid') #, bd=1, )

		self.result_text = bLabel(self.app, self.result_row, text=text, anchor='w')
		self.result_text.pack(side=LEFT, fill=X, expand=True)
		self.result_tooltip = bLabel(self.app, self.result_row, text=tooltip, fg=self.app.color('tooltip'))
		self.result_tooltip.pack(anchor=E, side=RIGHT)

		self.result_row.pack(side=TOP, fill=X, expand=True, padx=1, pady=1)

		# events
		self.result_row.bind("<Enter>", self.focus)
		self.result_row.bind("<Leave>", self.unfocus)
		self.result_text.bind('<ButtonRelease-1>', self.select)
		self.result_tooltip.bind('<ButtonRelease-1>', self.select)
		self.result_row.bind('<Return>', self.select)

		self.result_row.bind('<Tab>', self.searchbar.moveSelectionDown)

	def focus(self, ev=None):
		self.focused = True
		self.result_row.configure(bd=1)
		self.result_row.pack_configure(padx=0, pady=0)
		self.result_row.focus_set()

	def unfocus(self, ev=None):
		self.focused = False
		self.result_row.configure(bd=0)
		self.result_row.pack_configure(padx=1, pady=1)

	def select(self, ev=None):
		if self.fn_onSelect and self.focused:
			self.fn_onSelect()

