run:
	make win

mac:
	clear
	love.app/Contents/MacOS/love src

win:
	cls
	"love2d-win32/love.exe" --console "src"

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