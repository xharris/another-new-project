'''
TODO:
* frame('history') - make height 0 when empty
'''

from Tkinter import *
from tkinter import font, ttk
import subprocess, os
from platform import system

from event import Event
from project_manager import ProjectManager
from widgets.blanke_widgets import bFrame

from widgets.searchbar import Searchbar
from widgets.history import History
from widgets.favorites import Favorites

class App:
    def __init__(self, master):
        self.root = root
    	self.master = master
        self.os = system()
    	self.master.minsize(width=400, height=300)
    	self.master.title("editor")
        self.event = Event()
        self.proj_manager = ProjectManager(self)

    	self.colors = {}

    	self.color('entry_bg', '#263238') # dblue900
    	self.color('entry_text','#CFD8DC') # dblue100
    	self.color('entry_highlight', '#37474F') # dblue800
        self.color('focus_outline', '#B2FF59') # greenA200
    	self.color('frame_bg', '#37474F') # dblue800
    	self.color('border', '#546E7A') # dblue600
        self.color('tooltip', '#90A4AE') # dblue300

    	self.fonts = {}
    	self.font('editable', {'family':'Calibri', 'size':11, 'weight':'normal'})

    	self.frames = {}
    	self.frame('main', bFrame(self)).pack(anchor=N, fill=BOTH, expand=True, side=LEFT)
        self.frame('searchbar', bFrame(self, self.frame('main'), height=26, padx=4)).pack(fill=X, pady=(4,0))
        self.frame('history', bFrame(self, self.frame('main'), height=24, padx=4)).pack(fill=X, pady=(4,0))
        self.frame('workspace', bFrame(self, self.frame('main'), padx=4, pady=4)).pack(fill=BOTH, expand=True)

        self.settings = {}
        self.setting('use_external_editor', True)
        self.setting('love2d_path', 'C:/Users/XHH/Documents/PROJECTS/blanke4/love2d-win32/love.exe')

        self.elements = {
            'searchbar': Searchbar(self),
            'history': History(self),
            'favorites': Favorites(self)
        }

        self.frame('workspace').bind('<FocusIn>', self.element("searchbar").unfocus)

        self.event.trigger('ide.ready')

        self.proj_manager.openProject("C:/Users/XHH/Documents/PROJECTS/blanke4/src/projects/myproject")

    def element(self, name, value=None):
        if value:
            self.elements[name] = value
        return self.elements[name]

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

    def setting(self, name, value=None):
        if value != None:
            self.settings[name] = value
        return self.settings[name]

    def clearWorkspace(self):
    	self.frame('workspace').destroy()
    	self.frame('workspace', bFrame(self, self.frame('main'), padx=4, pady=4)).pack(fill=BOTH, expand=True)

    def error(self, msg):
        print("ERR: "+msg)

    def execute(self, stmt):
        try:
            retcode = subprocess.Popen(stmt, shell=True, stdin=None, stdout=None, stderr=None)
            '''
            if retcode < 0:
                print >>sys.stderr, "Child was terminated by signal", -retcode
            else:
                print >>sys.stderr, "Child returned", retcode
            '''
        except OSError, e:
            print >>sys.stderr, "Execution failed:", e

    def joinPath(self, *args):
        return os.path.join(os.path.dirname(sys.argv[0]), *args)

root = Tk()
app = App(root)
root.mainloop()