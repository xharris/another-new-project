from Tkinter import *
from tkinter import font, ttk

from widgets.blanke_widgets import bFrame

from widgets.searchbar import Searchbar
from widgets.code import Code
from widgets.history import History

class App:
    def __init__(self, master):
    	self.master = master
    	self.master.minsize(width=400, height=300)
    	self.master.title("editor")

    	self.colors = {}
    	self.color('entry_bg', '#263238')
    	self.color('entry_text','#CFD8DC')
    	self.color('entry_highlight', '#37474F')
    	self.color('frame_bg', '#37474F')
    	self.color('border', '#546E7A')

    	self.fonts = {}
    	self.font('editable', {'family':'Calibri', 'size':11, 'weight':'normal'})

    	self.frames = {}
    	self.frame('main', bFrame(self)).pack(anchor=N, fill=BOTH, expand=True, side=LEFT)
        self.frame('searchbar', bFrame(self, self.frame('main'), height=24, padx=4)).pack(fill=X, pady=(4,0))
        self.frame('history', bFrame(self, self.frame('main'), height=24, padx=4)).pack(fill=X, pady=(4,0))
        self.frame('workspace', bFrame(self, self.frame('main'), padx=4, pady=4)).pack(fill=BOTH, expand=True)

        Searchbar(self)
        History(self)
        Code(self)

    def color(self, name, value=None):
    	if value:
    		self.colors[name] = value
    	return self.colors[name]

    def font(self, name, options=None):
    	if options:
    		self.fonts[name] = font.Font(**options)
    	return self.fonts[name]

    def frame(self, name, obj_frame=None):
    	if obj_frame:
    		self.frames[name] = obj_frame
    	return self.frames[name]

    def clearWorkspace(self):
    	self.frame('workspace').destroy()
    	self.frame('workspace', bFrame(self, self.frame('main'), padx=4, pady=4)).pack(fill=BOTH, expand=True)

root = Tk()

app = App(root)

root.mainloop()