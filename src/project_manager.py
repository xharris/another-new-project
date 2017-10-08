from tkinter.filedialog import askopenfilename, asksaveasfilename, askdirectory

from os import getcwd, makedirs, walk
from os.path import isdir, join, dirname

from widgets.code import Code

class ProjectManager:
	def __init__(self, app):
		self.app = app
		self.proj_path = ""

		self.app.event.on('ide.ready', self.addSearchKeys)

	def addSearchKeys(self):
		el_searchbar = self.app.element('searchbar')
		el_searchbar.addKey(text="newProject", tooltip="make a new folder for a project", category="ProjectManager", onSelect=self.newProject)
		el_searchbar.addKey(text="openProject", category="ProjectManager", onSelect=self.openProject)
		runProject = el_searchbar.addKey(text="run", category="ProjectManager", icon="play.png", onSelect=self.run)
		self.openProject("C:/Users/XHH/Documents/PROJECTS/blanke4/src/projects/myproject")

		el_favorites = self.app.element('favorites')
		el_favorites.addKey(runProject)

	def isProjectOpen(self):
		return (self.proj_path == "")

	# show save file dialog, save folder name
	def newProject(self):
		proj_dir = asksaveasfilename(
			initialfile="myproject",
			initialdir=join(getcwd(),"src","projects"),
			title = "New project"
		)

		# does directory exist?
		if isdir(proj_dir):
			self.app.error("directory already exists")
			return
		self.proj_path = proj_dir

		# create dir
		makedirs(proj_dir)

		# add template files

	# show open file dialog
	def openProject(self, filepath=None):
		if not filepath:
			proj_dir = askdirectory(initialdir=getcwd(),
				title = "Open project"
			)
			self.proj_path = proj_dir
		else:
			self.proj_path = filepath.replace("\\","/")
		self.refreshFileSearch()

	def refreshFileSearch(self):
		ignore_folder = ['dist']

		el_searchbar = self.app.element('searchbar')
		for root, dirs, files in walk(self.proj_path):
			for f in ignore_folder:
				if not f in root:
					for file in files:
						# script files
						if file.endswith(".lua"):
							el_searchbar.addKey(text=file[:-4], tooltip=join(file), category="Script", tags=[file[:-4], "script"], onSelect=self.editScript, onSelectArgs={'filename':file})

	def editScript(self, filename):
		self.app.clearWorkspace()
		el_code = Code(self.app).openScript(join(self.proj_path, filename))

	def run(self):
		love2dpath = self.app.setting('love2d_path')
		if self.app.os == "Windows":
			self.app.execute([love2dpath,self.proj_path])
