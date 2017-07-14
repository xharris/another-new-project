import sys

def newProject(name):
	print('make' + name)

functions = {
	'newProject':newProject 
}

other_args = sys.argv[2:]
functions[sys.argv[1]](*other_args)
