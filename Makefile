do:
	./run_win.bat

mac:
	clear
	love.app/Contents/MacOS/love src

win:
	cls
	"love2d-win32/lovec.exe" --console "src"

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
	cp -r src/$(F) releases/win/src/$(F)

export_dll:
	cp love2d-win32/$(D) releases/win/$(D)

# requires Powershell (run: Set-ExecutionPolicy RemoteSigned)
build_win:
	# remove old folder
	rm -R -i -f releases/win

	# make .zip
	mkdir -p releases/win
	powershell.exe -nologo -noprofile -command "& {Set-ExecutionPolicy RemoteSigned -Scope CurrentUser}"
	powershell.exe . .\ziplove.ps1

	# copy other folders to zip folder
	mkdir -p releases/win/src
	cp -r src/projects releases/win/projects
	make export_src_folder F="modules"
	make export_src_folder F="plugins"
	make export_src_folder F="template"

	# copy dlls
	make export_dll D="love.dll"
	make export_dll D="lua51.dll"
	make export_dll D="mpg123.dll"
	make export_dll D="msvcp120.dll"
	make export_dll D="msvcr120.dll"
	make export_dll D="OpenAL32.dll"
	make export_dll D="SDL2.dll"
	cp imgui.dll releases/win/imgui.dll
	cp lfs.dll releases/win/lfs.dll

	# create exe
	cmd /k love2exe.bat

	./releases/win/BlankE.exe