from Tkinter import *
from PIL import ImageTk

def ifndef(d, key, value):
	if not d.has_key(key): d[key] = value

def stylize(d, opts):
	for key, value in opts.iteritems():
		ifndef(d, key, value)

class bDragWindow(Frame, object):
	def __init__(self, app, frame=None, **kwargs):
		stylize(kwargs,{
			'bg': app.color('frame_bg'),
			'width': 100,
			'height': 100
		})
		super(self.__class__, self).__init__(frame, **kwargs)


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
		self.select_range(0, END)
		self.icursor(END)
		return 'break'

	def set(self, value):
		self.delete(0, "end")
		self.insert(0, value)

	def onCommand(self):
		if self.onChange:
			self.onChange(self.get())

class bText(Text, object):
	def __init__(self, app, frame=None, **kwargs):
		self.scrollbarY = Scrollbar(app.frame('workspace'))
		self.scrollbarY.pack(side=RIGHT, fill=Y, pady=(0,18))

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
			'xscrollcommand': self.scrollbarX.set,
			'undo': True
		})
		super(self.__class__, self).__init__(frame, **kwargs)

		self.scrollbarY.config(command=self.yview)
		self.scrollbarX.config(command=self.xview) 
		self.tag_config("n", background="yellow", foreground="red")

	def set(self, text):
		self.delete("1.0","end")
		self.insert("1.0", text)
		self.edit_reset()

class bButton(Button, object):
	def __init__(self, app, frame=None, **kwargs):
		if 'image' in kwargs:
			kwargs['image'] = ImageTk.PhotoImage(file=kwargs['image'])

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

		if 'image' in kwargs:
			self.image = kwargs['image']

class bLabel(Label, object):
	def __init__(self, app, frame=None, **kwargs):
		self.string_var = StringVar()
		stylize(kwargs,{
			'bg': app.color('frame_bg'),
			'fg': app.color('entry_text'),
			'bd': 0,
			'textvariable':self.string_var
		})
		if 'text' in kwargs:
			self.set(kwargs['text'])
		super(self.__class__, self).__init__(frame, **kwargs)

	def set(self, new_value):
		self.string_var.set(new_value)

class bSpinbox(Spinbox, object):
	def __init__(self, app, frame=None, **kwargs):
		stylize(kwargs,{
			'bg': app.color('entry_bg'),
			'font': app.font('editable'),
			'bd': 0,
			'bg': app.color('entry_bg'),
			'fg': app.color('entry_text'),
			'highlightcolor': app.color('entry_highlight'),
		})
		super(self.__class__,self).__init__(frame, **kwargs)

	def set(self, value):

		self.delete(0,'end')
		self.insert(0, value)

class bCheckbutton(Checkbutton, object):
	def __init__(self, app, frame=None, **kwargs):
		self.var = BooleanVar()
		stylize(kwargs, {
			'variable': self.var,
			'bg': app.color('frame_bg'),
			'highlightbackground': app.color('frame_bg'),
			'activebackground': app.color('frame_bg'),
			'selectcolor': app.color('entry_highlight'),
			'foreground': app.color('focus_outline'),
			'activeforeground': app.color('focus_outline'),
			'bd': 0
		})
		super(self.__class__, self).__init__(frame, **kwargs)

	def set(self, value):
		if value == True:
			self.select()
		else:
			self.deselect()

	def get(self):
		return self.var.get()

class bForm(object):
	def __init__(self, app, frame=None, setting_manager=None, onSave=None):
		self.app = app
		self.setting_manager = setting_manager
		self.inputs = setting_manager.getInputs()
		self.elements = []
		self.frame_all = bFrame(app, frame, highlightthickness=1, padx=2, pady=2)
		self.fn_onSave = onSave

		# save/cancel buttons
		self.btn_frame = bFrame(self.app, self.frame_all)
		self.btn_save = bButton(self.app, self.btn_frame, image=self.app.joinPath("icons","checkmark.png"), bd=1, command=self.onSave)
		self.btn_reset = bButton(self.app, self.btn_frame, image=self.app.joinPath("icons","x.png"), bd=1, command=self.onReset)

		self.btn_save.pack(side=LEFT)
		self.btn_reset.pack(side=LEFT)

		if not self.app.font('form_label'):
			self.app.font('form_label', {'family':'Lucida Console', 'size':7, 'weight':'normal'})

		for i, inp in enumerate(self.inputs):
			inp_type = inp['type']
			new_frame = bFrame(app, self.frame_all)

			# get default input value
			inp_value = inp['value']

			# create label for input
			inp_label = inp['name']
			if 'label' in inp:
				inp_label = inp['label']
			new_label = bLabel(app, new_frame, font=self.app.font('form_label'), text=inp_label)

			# ALL : default, name, [label]

			# NUMBER : from, to
			new_input = None
			new_input_kwargs = {}
			pack_side = TOP
			if inp_type == 'number':
				from_val = None
				to_val = None
				if 'from' in inp:
					from_val = inp['from']
				if 'to' in inp:
					to_val = inp['to']

				new_input = bSpinbox(app, new_frame, from_=from_val, to=to_val, width=5)

				new_input.set(inp_value)

			# STRING (single line)
			elif inp_type == 'string':
				new_input = bEntry(app, new_frame)
				new_input.set(inp_value)

			# CHECKBOX 
			elif inp_type == 'checkbox':
				pack_side = LEFT
				new_label = bLabel(app, new_frame, text=inp_label)
				new_input = bCheckbutton(app, new_frame, padx=2)
				new_input.set(inp_value)

			new_input.name = inp['name']
			self.elements.append(new_input)

			bottom_pad = 4
			if i == len(self.inputs)-1:
				bottom_pad = 0

			if new_label: new_label.pack(side=pack_side, anchor=W)
			if new_input: new_input.pack(side=pack_side, anchor=W, fill=X, pady=(0,bottom_pad), **new_input_kwargs)

			new_frame.pack(anchor=W)
			self.btn_frame.place(relx=1, rely=0, anchor=NE)

			self.frame_all.pack(side=TOP, anchor=W, fill=BOTH, expand=True)

	def onSave(self, ev=None):
		self.setting_manager.disable_onSet = True
		for el in self.elements:
			self.setting_manager[el.name] = el.get()
		self.setting_manager.disable_onSet = False
		if self.fn_onSave:
			self.fn_onSave(self.setting_manager)

	def onReset(self, ev=None):
		default_values = self.setting_manager.getDefaults()
		for el in self.elements:
			el.set(default_values[el.name])

	def destroy(self):
		del self