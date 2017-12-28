do:
	make win

mac:
	clear
	love.app/Contents/MacOS/love src

win:
	cls
	"love2d/lovec.exe" --console "src"

update_folder:
	rm -R -i -f releases/win/src/$(D)
	cp -r src/$(D) releases/win/src/$(D)

update_release:
	make update_folder D="modules"
	make update_folder D="template"
	make update_folder D="plugins"
	make update_folder D="icons"
	make update_folder D="ide"
	make update_folder D="images"
	cp src/helper.exe releases/win/src/helper.exe

build_mac:
	# remove old folder
	rm -R -i releases/mac

	# make .love
	mkdir -p releases/mac
	cd src; zip -9 -r --exclude=*projects* ../releases/mac/BlankE.love .

	# combine love2d with .love
	cp -r love.app releases/mac/BlankE.app
	cd releases/mac; mv BlankE.love BlankE.app/Contents/Resources/BlankE.love

	#cp src/helper.py releases/mac/BlankE.app/Contents/Resources/helper.py

	open releases/mac/BlankE.app

export_src_folder:
	cp -r src/$(F) releases/win/$(F)

export_dll:
	cp love2d/$(D) releases/win/$(D)

# requires Powershell (run: Set-ExecutionPolicy RemoteSigned)
build_win:
	# remove old folder
	rm -R -i -f releases/win
	mkdir -p releases/win

	# make .zip
	#powershell.exe -nologo -noprofile -command "& {Set-ExecutionPolicy RemoteSigned -Scope CurrentUser}"
	#powershell.exe . .\ziplove.ps1

	# mv releases/win/blanke.zip releases/win/blanke.pak
	cp -r src releases/win/src

	# copy other folders to zip folder
	#mkdir -p releases/win/src
	#cp -r src/projects releases/win/projects
	#make export_src_folder F="modules"
	#make export_src_folder F="plugins"
	#make export_src_folder F="template"

	# copy dlls
	cp -r love2d releases/win/love2d
	cp imgui.dll releases/win/imgui.dll
	cp lfs.dll releases/win/lfs.dll
	cp BlankE.exe releases/win/BlankE.exe

	# create exe
	# cmd /k love2exe.bat

	#./releases/win/BlankE.exe