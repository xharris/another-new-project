function basename(str)
	local name = string.gsub(str, "(.*/)(.*)", "%2")
	return name
end

CONSOLE = {
	log = {},
	print = function(...) 
		local print_str = ''
		for a, argument in ipairs({...}) do
			print_str = print_str..tostring(argument)..' '
		end
		local info = debug.getinfo(3)
		table.insert(CONSOLE.log, 1, print_str..' ('..basename(info.short_src)..':'..info.currentline..')')	
	end,

	draw = function()
	    if UI.titlebar.show_console then
	    	local margin = 10
	    	local height = 100

	    	imgui.SetNextWindowPos(margin, love.graphics.getHeight()-height-margin, "Always")
	    	imgui.SetNextWindowSize(love.graphics.getWidth()-(margin*2), height)
	    	state, UI.titlebar.show_console = imgui.Begin("Console", UI.titlebar.show_console, {"NoResize", "NoMove", "NoCollapse", "NoTitleBar"})

	    	for l, log in ipairs(CONSOLE.log) do
	    		imgui.Text(log)
	    	end

	    	imgui.End()
	    end
	end
}

old_print = print
print = function(...) 
    CONSOLE.print(...)
    old_print(...)
end