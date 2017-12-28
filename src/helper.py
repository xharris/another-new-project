import os,zipfile,sys

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

if len(sys.argv) == 3:
	zipDir(sys.argv[1], sys.argv[2])