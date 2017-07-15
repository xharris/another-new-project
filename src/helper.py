import sys,os

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

def newProject(name):
	pass

def newScript(obj_type, project_path, obj_name):
	copyTemplate(
		os.path.join(os.path.dirname(__file__),'template', obj_type+'.lua'),
		os.path.join(project_path,'scripts',obj_type,obj_name+'.lua'),
		{
			'<NAME>':obj_name
		}
	)

def writeAssets(project_path, content):
	open(os.path.join(os.path.normpath(project_path),'assets.lua'),'w').write(content.replace('\\n','\n'))

functions = {
	'newProject':newProject,
	'newScript':newScript,
	'writeAssets':writeAssets
}

other_args = sys.argv[2:]
functions[sys.argv[1]](*other_args)
