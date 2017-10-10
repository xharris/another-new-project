from tkinter.filedialog import askopenfilename, asksaveasfilename, askdirectory

from shutil import copyfile
from os import getcwd, makedirs, walk, listdir
from os.path import isdir, join, dirname, isfile, basename

from widgets.code import Code

class ProjectManager:
	def __init__(self, app):
		self.app = app
		self.proj_path = ""
		self.obj_dict = {'entity':[], 'state':[], 'image':[]}

		self.app.event.on('ide.ready', self.ideReady)

	def ideReady(self):
		el_searchbar = self.app.element('searchbar')
		el_searchbar.addKey(text="newProject", tooltip="make a new folder for a project", category="ProjectManager", onSelect=self.newProject)
		openProject = el_searchbar.addKey(text="openProject", category="ProjectManager", icon="folder.png", onSelect=self.openProject)
		runProject = el_searchbar.addKey(text="run", category="ProjectManager", icon="play.png", onSelect=self.run)

		el_favorites = self.app.element('favorites')
		el_favorites.addKey(runProject)
		el_favorites.addKey(openProject)

		self.app.root.bind('<Control-b>', self.run)

	def isProjectOpen(self):
		return (self.proj_path == "")

	def getProjectName(self):
		return basename(self.proj_path)

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
		makedirs(self.proj_path)

		# add template files
		ignore_files = ['state.lua', 'entity.lua', 'plugins']
		template_path = self.app.joinPath('template')
		for file in listdir(template_path):
			if file not in ignore_files:
				copyfile(join(template_path, file), join(self.proj_path, file))

		self.refreshFileSearch()

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
		self.app.setTitle(self.getProjectName())
		for cat in self.obj_dict:
			self.obj_dict[cat] = []
		ignore_folder = ['dist']

		el_searchbar = self.app.element('searchbar')
		for root, dirs, files in walk(self.proj_path):
			for f in ignore_folder:
				if not f in root:
					for file in files:
						# script files
						if file.endswith(".lua"):
							tags = [file[:-4], "script"]
							with open(join(root, file),'r') as f_script:
								# determine the category of the script
								for line in f_script:
									if ':enter' in line:
										tags.append('state')
										self.obj_dict['state'].append(join(root, file))
										break
									if 'Entity.init' in line:
										tags.append('entity')
										self.obj_dict['entity'].append(join(root, file))
										break

							el_searchbar.addKey(text=file[:-4], tooltip=join(file), category="Script", tags=tags, onSelect=self.editScript, onSelectArgs={'filepath':join(root,file)})

						# assets: images, sounds
						if "assets" in root:
							tags = [file[:-4], "asset"]
							supported_imgs = ['.png']
							for ext in supported_imgs:
								if file.endswith(ext):
									tags.append('image')
									self.obj_dict['image'].append(join(root, file))

									el_searchbar.addKey(text=file[:-4], tooltip=join(file), category="Asset", tags=tags)#, onSelect=self.editScript, onSelectArgs={'filepath':join(root,file)})
				

	def editScript(self, filepath):
		el_code = Code(self.app).openScript(join(self.proj_path, filepath))

	def run(self, ev=None):
		love2dpath = self.app.setting('love2d_path')

		# inject package.path code
		template_path = join(getcwd(),'src','template').replace('\\','\\\\')

		s_main = ''
		with open(join(self.proj_path,'main.lua'), 'r') as f_main:
	   		s_main = f_main.read()
		f_main.close()

		if not 'INJECTED_CODE_START' in s_main:
			f_main = open(join(self.proj_path,'main.lua'),'w+')
			inject_str = ''+\
			'--INJECTED_CODE_START'+\
			'\npackage.path=package.path..\";'+template_path+'\\\\?.lua\"'+\
			'\npackage.path=package.path..\";'+template_path+'\\\\?\\\\init.lua\"'+\
			'\n--INJECTED_CODE_END\n\n'
			f_main.write(inject_str+s_main)
			f_main.close()

		if self.app.os == "Windows":
			self.app.execute([love2dpath,self.proj_path])
