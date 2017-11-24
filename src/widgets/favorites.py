# app.element('favorites').addKey(key)

from Tkinter import *
from blanke_widgets import bFrame, bButton

class Favorites:
	def __init__(self, app):
		self.app = app
		self.items = []

		self.frame = bFrame(self.app, self.app.frame('searchbar'), width=0)
		self.frame.pack(side=RIGHT, padx=(4,0))

	def addKey(self, key):
		self.items.append(FaveItem(self, key))
		self.removeDeadFaves()

	def addFave(self, fave):
		self.items.append(fave)

	def removeDeadFaves(self):
		self.items = [fave for fave in self.items if not fave.dead]

		if len(self.items) == 0:
			self.frame.pack_forget()
		else:
			self.frame.pack(side=RIGHT, padx=(4,0))

class FaveItem:
	def __init__(self, favorites, key):
		self.favorites = favorites
		self.app = self.favorites.app
		self.dead = False
		self.key = key

		if '.' in self.key.icon:
			self.button = bButton(self.app, self.favorites.frame, image=self.app.joinPath("icons",self.key.icon), bd=1, command=self.onClick)
		elif self.key.icon != '':
			self.button = bButton(self.app, self.favorites.frame, text=self.key.icon, bd=1, command=self.onClick)
		else:		
			self.button = bButton(self.app, self.favorites.frame, text=self.key.text[0], bd=1, command=self.onClick)

		self.button.bind('<ButtonRelease-3>', self.destroy)
		self.button.pack(side=RIGHT)

	def onClick(self, ev=None):
		self.key.fn_onSelect(**self.key.onSelectArgs)

	def destroy(self, ev=None):
		self.dead = True
		self.button.destroy()
		self.favorites.removeDeadFaves()