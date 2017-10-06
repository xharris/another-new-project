from Tkinter import *
from blanke_widgets import bEntry, bFrame, bLabel

PLACEHOLDER = "Search"

class Searchbar:
	def __init__(self, app):
		self.app = app
		self.result_container = None
		self.results = []
		self.keys = []
		self.selected_result = -1
		self.has_focus = False

		# onChange variable
		change_ev = StringVar()
		change_ev.trace("w", lambda name, index, mode, sv=change_ev: self.onChange(change_ev))

		# create Entry input
		self.entry = bEntry(self.app, self.app.frame('searchbar'), textvariable=change_ev)
		self.entry.insert(0, 'Search')
		self.entry.pack(fill=X)

		self.entry.bind('<Up>', self.moveSelectionUp)
		self.entry.bind('<Down>', self.moveSelectionDown)
		self.entry.bind('<Return>', self.clickSelectedResult)
		self.entry.bind('<FocusIn>', self.focus)

		self.recreateContainer()

	def focus(self, ev=None):
		# remove placeholder if nec.
		if self.entry.get() == PLACEHOLDER:
			self.entry.set("")

		if self.has_focus:
			self.clearResults()
			self.result_container.destroy()

		self.has_focus = True
		self.recreateContainer()

	def recreateContainer(self):
		if self.result_container:
			self.result_container.destroy()
		# create container
		self.result_container = bFrame(self.app, self.app.frame('main'))
		self.result_container.place(x=0, y=self.app.frame('searchbar')['height'], relwidth=1, anchor=NW)

		self.result_frame = bFrame(self.app, self.result_container)
		self.result_frame.pack(padx=4, fill=BOTH)

	def unfocus(self, ev=None):
		self.has_focus = False
		self.clearResults()

		# reset placeholder if no text in box
		if self.entry.get().strip() == "":
			self.entry.set(PLACEHOLDER)

	def onChange(self, ev):
		text = ev.get()
		self.clearResults()
		if text != PLACEHOLDER and text != "":
			for key in self.keys:
				if text in key.searchText:
					self.addResult(key)

	def addKey(self, **args):
		new_key = Key(**args)
		self.keys.append(new_key)
		return new_key

	def clearKey(self, category=None):
		if not category:
			# remove all keys
			del self.keys[:]

		else:
			# remove only keys associated with category
			self.keys = [key for key in self.keys if not key.isCategory(category)]

	def addResult(self, key):
		new_result = Result(self, key)
		self.results.append(new_result)
		return new_result

	def clearResults(self):
		for result in self.results:
			result.destroy()
		del self.results[:]
		self.results = []
		self.selected_result = -1

		self.recreateContainer()

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
		return 'break'

	def moveSelectionDown(self, ev=None):
		''' for Tab
		if ev and ev.state == 9:
			self.moveSelectionUp()
		else:
		'''
		self.selected_result += 1
		self.moveSelection()

	def moveSelectionUp(self, ev=None):
		self.selected_result -= 1
		self.moveSelection()

	def clickSelectedResult(self, ev=None):
		for r, result in enumerate(self.results):
			result.select()
		self.clearResults()

class Result:
	def __init__(self, searchbar, key):
		self.searchbar = searchbar
		self.app = self.searchbar.app
		self.key = key
		self.focused = False

		# setup result widgets
		self.result_row = bFrame(self.app, self.searchbar.result_frame, relief='solid', padx=1, pady=1)
		self.result_padding = bFrame(self.app, self.result_row, relief='solid')
		self.result_padding.pack(fill=BOTH, expand=True)

		self.result_text = bLabel(self.app, self.result_padding, text=self.key.text, anchor='w')
		self.result_text.pack(side=LEFT, fill=X, expand=True)
		self.result_tooltip = bLabel(self.app, self.result_padding, text=self.key.tooltip, fg=self.app.color('tooltip'))
		self.result_tooltip.pack(anchor=E, side=RIGHT)

		self.result_row.pack(side=TOP, fill=X, expand=True)

		# events
		self.result_row.bind('<Up>', self.searchbar.moveSelectionUp)
		self.result_row.bind('<Down>', self.searchbar.moveSelectionDown)
		self.result_row.bind("<Enter>", self.focus)
		self.result_row.bind("<Leave>", self.unfocus)
		self.result_text.bind('<ButtonRelease-1>', self.select)
		self.result_row.bind('<Return>', self.select)
		self.result_tooltip.bind('<ButtonRelease-1>', self.select)

		self.result_row.bind('<Tab>', self.searchbar.moveSelectionDown)

	def focus(self, ev=None):
		self.focused = True
		self.result_row.config(bg='black')
		self.result_row.focus_set()

	def unfocus(self, ev=None):
		self.focused = False
		self.result_row.config(bg=self.app.color('frame_bg'))

	def select(self, ev=None):
		if self.key.fn_onSelect and self.focused:
			self.key.fn_onSelect()
		self.searchbar.clearResults()

	def destroy(self):
		self.result_row.destroy()

class Key:
	def __init__(self, text="", tooltip="", onSelect=None, category=""):
		self.text = text
		self.searchText = text.replace(" ","").lower()
		self.tooltip = tooltip
		self.fn_onSelect = onSelect
		self.category = category

	def isCategory(self, cat):
		return self.category == cat