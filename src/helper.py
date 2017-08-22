import sys,os,subprocess,shutil,zipfile

BASE_FOLDER = os.path.dirname(__file__)

def newProject(pj_folder, pj_name):
	pj_folder = os.path.normpath(pj_folder)

	# make sure project folder exists
	if not os.path.exists(pj_folder):
		os.makedirs(pj_folder)

	# get name of new project
	pj_list = os.listdir(pj_folder)
	proj_name = pj_name or 'project'+str(len(pj_list))
	while proj_name in pj_list:
		proj_name += '_new'
	proj_path = os.path.join(pj_folder,proj_name)

	# create project folder and transfer files
	shutil.copytree(os.path.join(BASE_FOLDER,'template'),proj_path,ignore=shutil.ignore_patterns('plugins'))

	#remove template files
	rem_files = ['entity.lua','state.lua']
	for f in rem_files:
		file_path = os.path.join(proj_path,f)
		if os.path.exists(file_path):
			os.remove(file_path)

def copyResource(res_type, src, project_path):
	filename = os.path.basename(src)
	dest = os.path.join(project_path,'assets',res_type,filename)

	if not os.path.exists(os.path.dirname(dest)):
		os.makedirs(os.path.dirname(dest))

	shutil.copyfile(src, dest)

def zipDir(src, dest):
    zf = zipfile.ZipFile("%s" % (dest), "w", zipfile.ZIP_DEFLATED)
    abs_src = os.path.abspath(src)
    for dirname, subdirs, files in os.walk(src):
        for filename in files:
        	if filename != os.path.basename(dest):
	            absname = os.path.abspath(os.path.join(dirname, filename))
	            arcname = absname[len(abs_src) + 1:]
	            zf.write(absname, arcname)
    zf.close()

functions = {
	'newProject':newProject,
	#'newScript':newScript,			# deprecated
	#'editFile':editFile,			# deprecated
	'copyResource':copyResource,
	#'makeDirs':makeDirs,			# deprecated
	#'listFiles':listFiles,			# deprecated
	#'isDirectory':isDirectory,		# deprecated
	'zipDir':zipDir
}

other_args = sys.argv[2:]
functions[sys.argv[1]](*other_args)
