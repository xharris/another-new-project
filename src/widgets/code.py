from Tkinter import *
from blanke_widgets import bText

from os.path import basename
from pygments import lex
from pygments.lexers import LuaLexer
from pygments.lexer import RegexLexer, include, words
from pygments.token import *

class Code:
	def __init__(self, app):
		self.app = app
		self.filepath = ''
		self.previousContent = ''
		if not self.app.ide_settings['use_external_editor']:
			workspace = self.app.clearWorkspace()
			self.text = bText(self.app, workspace, width=workspace.winfo_width(), height=workspace.winfo_height(), wrap=NONE)
			self.text.pack(fill=BOTH, expand=True)

			lua_colors = {
				"Text": self.app.color("entry_text"),

				"Token.Name.Class": "#ef9a9a", # red200
				"Token.Name.Function": "#FFCC80", # orange200

				"Token.Operator": "#9CCC65",
				"Token.Comment.Single": "#78909C",
				"Token.Comment.Multi": "#78909C",

				"Token.Literal.Number": "#80DEEA", # aqua200
				"Token.Literal.Number.Integer": "#80DEEA",
				"Token.Literal.Number.Float": "#80DEEA", 
				"Token.Literal.Number.Integer.Long": "#80DEEA",
				"Token.Keyword.Constant": "#80DEEA", 

				"Token.Literal.String.Single": "#FFF59D", # yellow200
				"Token.Literal.String.Double": "#FFF59D",
				"Token.Literal.String.Escape": "#FDD835"  # yellow600
			}

			for key, value in lua_colors.iteritems():
				self.text.tag_configure(key, foreground=value)

			self.text.bind('<Control-s>', self.save)
			self.text.bind('<KeyRelease>', self.keyRelease)

	def openScript(self, filepath):
		self.filepath = filepath
		el_history = self.app.element('history')
		el_history.addEntry(basename(filepath), self.app.proj_manager.editScript, {'filepath':filepath})


		if self.app.ide_settings['use_external_editor']:
			if self.app.os == "Windows":
				self.app.execute("start "+filepath)
			else:
				self.app.execute("open "+filepath)

		else:
			text = open(filepath, 'r').read()
			self.text.set(text)
			self.previousContent = ''
			self.keyRelease()

	def save(self, ev=None):
		if self.filepath != '':
			s_code = self.text.get("1.0",END)
			f_code = open(self.filepath,'w+')
			f_code.write(s_code)
			f_code.close()

	# lexing found at https://stackoverflow.com/questions/32058760/improve-pygments-syntax-highlighting-speed-for-tkinter-text
	def keyRelease(self, ev=None):
		self.content = self.text.get("1.0", END)
		self.lines = self.content.split("\n")
		index = self.text.index(INSERT)
		row = index.split('.')[0]
		if not ev:
			row = '1'

		if (self.previousContent != self.content):
			self.text.mark_set("range_start", row + ".0")
			data = None
			if self.previousContent == '':
				data = self.text.get("1.0", END)
			else:
				data = self.text.get(row + ".0", row + "." + str(len(self.lines[int(row) - 1])))

			for token, content in lex(data, BlankeLexer()):
				self.text.mark_set("range_end", "range_start + %dc" % len(content))
				self.text.tag_add(str(token), "range_start", "range_end")
				self.text.mark_set("range_start", "range_end")

		self.previousContent = self.content
		
TOKENS = LuaLexer.tokens
TOKENS.update({
	'bFunction': [
		(r'(?<=[:.])([^({ ]+?)(?=[({])', Name.Function)
	],
})
TOKENS['root'].insert(0, include('bFunction'))

class BlankeLexer(RegexLexer):
	name = 'BlankeLexer'
	aliases = ['blankelexer', 'lua']
	filenames = ['*.lua']

	tokens = TOKENS