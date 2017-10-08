from Tkinter import *
from blanke_widgets import bFrame, bButton
from PIL import ImageTk

class Favorites:
	def __init__(self, app):
		self.app = app
		self.items = []

		self.frame = bFrame(self.app, self.app.frame('searchbar'))
		self.frame.pack(side=RIGHT, padx=(4,0))

	def addKey(self, key):
		self.items.append(FaveItem(self, key))

class FaveItem:
	def __init__(self, favorites, key):
		self.favorites = favorites
		self.app = self.favorites.app
		self.key = key

		if '.' in self.key.icon:
			image = ImageTk.PhotoImage(file=self.app.joinPath("icons",self.key.icon))
			self.button = bButton(self.app, self.favorites.frame, image=image, bd=1, command=self.key.fn_onSelect)
			self.button.image = image
		else:
			self.button = bButton(self.app, self.favorites.frame, text=self.key.icon, bd=1, command=self.key.fn_onSelect)
			
		self.button.pack(side=RIGHT)