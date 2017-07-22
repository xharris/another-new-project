import sys,os,subprocess,shutil

BASE_FOLDER = os.path.dirname(__file__)

def copyTemplate(src, dest, replacements):
	src = os.path.normpath(src)
	dest = os.path.normpath(dest)

	if not os.path.exists(os.path.dirname(dest)):
		os.makedirs(os.path.dirname(dest))

	# read template
	s_template = open(src,"r").read()

	# make replacements
	for r_src in replacements:
		r_dest = replacements[r_src]
		s_template = s_template.replace(r_src, r_dest)

	# write new file
	if not os.path.exists(dest):
		open(dest, "w").write(s_template)

def newProject(pj_folder):
	pj_folder = os.path.normpath(pj_folder)

	# make sure project folder exists
	if not os.path.exists(pj_folder):
		os.makedirs(pj_folder)

	# get name of new project
	pj_list = os.listdir(pj_folder)
	proj_name = 'project'+str(len(pj_list))
	while proj_name in pj_list:
		proj_name += '_new'
	proj_path = os.path.join(pj_folder,proj_name)

	# create project folder and transfer files
	shutil.copytree(os.path.join(BASE_FOLDER,'template'),proj_path)

	#remove template files
	rem_files = ['entity.lua','state.lua']
	for f in rem_files:
		os.remove(os.path.join(proj_path,f))

def newScript(obj_type, project_path, obj_name):
	copyTemplate(
		os.path.join(BASE_FOLDER,'template', obj_type+'.lua'),
		os.path.join(project_path,'scripts',obj_type,obj_name+'.lua'),
		{
			'<NAME>':obj_name
		}
	)

def editFile(path):
	cmd = path
	if sys.platform == "darwin":
		cmd = "open "+path
	subprocess.Popen([cmd], shell=True,stdin=None, stdout=None, stderr=None, close_fds=True)

def copyResource(res_type, src, project_path):
	filename = os.path.basename(src)
	dest = os.path.join(project_path,'assets',res_type,filename)

	if not os.path.exists(os.path.dirname(dest)):
		os.makedirs(os.path.dirname(dest))

	shutil.copyfile(src, dest)

def makeDirs(path):
	path = os.path.normpath(path)
	if os.path.isfile(path):
		path = os.path.dirname(path)
	if not os.path.exists(os.path.dirname(path)):
		os.makedirs(os.path.dirname(path))

functions = {
	'newProject':newProject,
	'newScript':newScript,
	'editFile':editFile,
	'copyResource':copyResource,
	'makeDirs':makeDirs
}

other_args = sys.argv[2:]
functions[sys.argv[1]](*other_args)
