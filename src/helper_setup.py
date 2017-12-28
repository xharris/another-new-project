from distutils.core import setup
import py2exe, sys, os, shutil

sys.argv.append('py2exe')

setup(
    options = {'py2exe': {'bundle_files': 1, 'compressed': True}},
    windows = [{'script': "helper.py"}],
    zipfile = None,
)

shutil.rmtree('build')