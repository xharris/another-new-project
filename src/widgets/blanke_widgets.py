from Tkinter import Frame, Entry, Text, Button, Label, Scrollbar
from Tkinter import X, Y, TOP, LEFT, RIGHT, BOTTOM, HORIZONTAL, FLAT

def ifndef(d, key, value):
	if not d.has_key(key): d[key] = value

def stylize(d, opts):
	for key, value in opts.iteritems():
		ifndef(d, key, value)

class bFrame(Frame, object):
	def __init__(self, app, frame=None, **kwargs):
		stylize(kwargs,{
			'bg': app.color('frame_bg')
		})
		super(self.__class__, self).__init__(frame, **kwargs)

class bEntry(Entry, object):
	def __init__(self, app, frame=None, **kwargs):
		stylize(kwargs,{
			'bg': app.color('entry_bg'),
			'font': app.font('editable'),
			'bd': 0,
			'bg': app.color('entry_bg'),
			'fg': app.color('entry_text'),
			'insertbackground': app.color('entry_text'),
			'selectbackground': app.color('entry_highlight'),
			'highlightbackground': app.color('entry_bg'),
			'highlightcolor': app.color('focus_outline'),
			'highlightthickness': 1,
			'relief': FLAT
		})
		super(self.__class__, self).__init__(frame, **kwargs)
		
		self.bind('<Control-a>', self.selectAll)

	def selectAll(self, ev=None):
		self.select_range(0, 'end')
		self.icursor('end')

	def set(self, value):
		self.delete(0, "end")
		self.insert(0, value)

class bText(Text, object):
	def __init__(self, app, frame=None, **kwargs):

		self.scrollbarY = Scrollbar(app.frame('workspace'))
		self.scrollbarY.pack(side=RIGHT, fill=Y)

		self.scrollbarX = Scrollbar(app.frame('workspace'), orient=HORIZONTAL)
		self.scrollbarX.pack(side=BOTTOM, fill=X)

		stylize(kwargs,{
			'bg': app.color('entry_bg'),
			'font': app.font('editable'),
			'bd': 0,
			'bg': app.color('entry_bg'),
			'fg': app.color('entry_text'),
			'insertbackground': app.color('entry_text'),
			'selectbackground': app.color('entry_highlight'),
			'highlightcolor': app.color('entry_highlight'),
			'yscrollcommand': self.scrollbarY.set,
			'xscrollcommand': self.scrollbarX.set
		})
		super(self.__class__, self).__init__(frame, **kwargs)

		self.scrollbarY.config(command=self.yview)
		self.scrollbarX.config(command=self.xview) 
		self.tag_config("n", background="yellow", foreground="red")

	def set(self, text):
		self.delete("1.0","end")
		self.insert("1.0", text)

class bButton(Button, object):
	def __init__(self, app, frame=None, **kwargs):
		stylize(kwargs,{
			'bg': app.color('frame_bg'),
			'activebackground': app.color('frame_bg'),
			'fg': app.color('entry_text'),
			'activeforeground': app.color('entry_text'),
			'bd': 0,
			'highlightthickness': 1,
			'highlightbackground': app.color('border'),
			'relief': 'flat'
		})
		super(self.__class__, self).__init__(frame, **kwargs)

class bLabel(Label, object):
	def __init__(self, app, frame=None, **kwargs):
		stylize(kwargs,{
			'bg': app.color('frame_bg'),
			'fg': app.color('entry_text'),
			'bd': 0,
		})
		super(self.__class__, self).__init__(frame, **kwargs)
