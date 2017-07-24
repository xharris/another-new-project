run:
	make mac

mac:
	clear
	love.app/Contents/MacOS/love src

win:
	cls
	"love2d-win32/love.exe" --console "src"