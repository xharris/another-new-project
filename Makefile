run:
	make win

mac:
	clear
	love.app/Contents/MacOS/love src

win:
	cls
	"love-0.10.2-win32/lovec.exe" --console "src"