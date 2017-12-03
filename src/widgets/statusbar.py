from Tkinter import *
from blanke_widgets import bLabel

class Statusbar:
	def __init__(self, app, frame):
		self.app = app
		self.frame = frame

		self.text = bLabel(self.app, self.frame)
		self.text.pack(side=LEFT)
		self.progress_front = None
		self.progress_back = None

		self.setTooltip('hi')

	def setTooltip(self, value=''):
		self.text.set(value)