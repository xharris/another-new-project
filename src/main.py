'''
TODO:
* frame('history') - make height 0 when empty?
* work on BlankeLexer (currently using LuaLexer)
* watch project folder and refresh search on changes

BUGS:
(DONE) clicking a file in history does not open the built-in code editor properly
'''

from Tkinter import *
from tkinter import font, ttk
import subprocess, os
from platform import system

from event import Event
from setting_manager import SettingManager
from project_manager import ProjectManager
from widgets.blanke_widgets import bFrame, bForm

from widgets.searchbar import Searchbar
from widgets.history import History
from widgets.favorites import Favorites

class App:
    def __init__(self, master):
        self.root = root
    	self.master = master
        self.os = system()

    	self.master.minsize(width=400, height=300)
        self.setTitle()
        self.root.iconbitmap(self.joinPath("blanke.ico"))

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
    	self.font('editable', {'family':'Lucida Console', 'size':9, 'weight':'normal'})

    	self.frames = {}
    	self.frame('main', bFrame(self)).pack(anchor=N, fill=BOTH, expand=True, side=LEFT)
        self.frame('searchbar', bFrame(self, self.frame('main'), height=26, padx=4)).pack(fill=X, pady=(4,0))
        self.frame('history', bFrame(self, self.frame('main'), height=24, padx=4)).pack(fill=X, pady=(4,0))
        self.frame('workspace', bFrame(self, self.frame('main'), padx=4, pady=4)).pack(fill=BOTH, expand=True)

        self.ide_settings = SettingManager([
            {'type':'checkbox', 'name':'use_external_editor', 'default':False},
            {'type':'string', 'name':'love2d_path', 'default':'C:/Users/XHH/Documents/PROJECTS/blanke4/love2d-win32'}
        ])
        self.ide_settings.read(self.joinPath('ide.cfg'))

        self.elements = {
            'searchbar': Searchbar(self),
            'history': History(self),
            'favorites': Favorites(self)
        }

        self.frame('workspace').bind('<FocusIn>', self.element("searchbar").unfocus)

        test(self)
        self.event.trigger('ide.ready')

        # POST-ide.ready 
        ideSettings = self.element('searchbar').addKey(text="ideSettings", category="IDE", icon="wrench.png", onSelect=self.showIDESettings)


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
        if not name in self.fonts:
            return None
    	return self.fonts[name]

    def frame(self, name, obj_frame=None):
    	if obj_frame:
    		self.frames[name] = obj_frame
    	return self.frames[name]

    def clearWorkspace(self):
    	self.frame('workspace').destroy()
    	self.frame('workspace', bFrame(self, self.frame('main'), padx=4, pady=4)).pack(fill=BOTH, expand=True)
        return self.frame('workspace')

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

    def setTitle(self, value=None):
        if not value:
            self.master.title("BlankE")
        else:
            self.master.title("%s - BlankE"%(value))

    def showIDESettings(self):
        self.clearWorkspace()
        self.element('history').addEntry('ideSettings', self.showIDESettings)
        the_form = bForm(self, self.frame('workspace'), self.ide_settings, self._writeIDESettings)

    def _writeIDESettings(self, values):
        self.ide_settings.write(self.joinPath('ide.cfg'))

 
def test(app):
    app.proj_manager.openProject("C:/Users/XHH/Documents/PROJECTS/blanke4/src/projects/engine_project")


root = Tk()
app = App(root)
root.mainloop()

