from Tkinter import Frame, Entry, Text, Button

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
			'highlightcolor': app.color('entry_highlight')
		})
		super(self.__class__, self).__init__(frame, **kwargs)

class bText(Text, object):
	def __init__(self, app, frame=None, **kwargs):
		stylize(kwargs,{
			'bg': app.color('entry_bg'),
			'font': app.font('editable'),
			'bd': 0,
			'bg': app.color('entry_bg'),
			'fg': app.color('entry_text'),
			'insertbackground': app.color('entry_text'),
			'selectbackground': app.color('entry_highlight'),
			'highlightcolor': app.color('entry_highlight')
		})
		super(self.__class__, self).__init__(frame, **kwargs)

class bButton(Button, object):
	def __init__(self, app, frame=None, **kwargs):
		stylize(kwargs,{
			'bg': app.color('frame_bg'),
			'activebackground': app.color('frame_bg'),
			'fg': app.color('entry_text'),
			'activeforeground': app.color('entry_text'),
			'bd': 0,
			'highlightthickness': 1,
			'highlightbackground': app.color('border')
		})
		super(self.__class__, self).__init__(frame, **kwargs)