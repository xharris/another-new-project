CONSOLE = {
	_last_print = nil,
	_repeat_print_count = 1,
	log = {},
	print = function(...) 
		local print_str = ''
		for a, argument in ipairs({...}) do
			print_str = print_str..tostring(argument)..' '
		end

		local info_num = 1
		local info = debug.getinfo(info_num)
		while info.short_src:contains("console.lua") or info.short_src:contains("Debug.lua") do
			info_num = info_num + 1
			info = debug.getinfo(info_num)
		end

		if print_str == CONSOLE._last_print and #CONSOLE.log > 0 then
			CONSOLE._repeat_print_count = CONSOLE._repeat_print_count + 1
			CONSOLE.log[1] = print_str..' ('..basename(info.short_src)..':'..info.currentline..') ('..CONSOLE._repeat_print_count..')'
		else
			CONSOLE._last_print = print_str
			table.insert(CONSOLE.log, 1, print_str..' ('..basename(info.short_src)..':'..info.currentline..')')	
		end
	end,

	draw = function()
	    if UI.titlebar.show_console and IDE.isProjectOpen() then
	    	local margin = 10
	    	local height = UI.getSetting("console_height").value

	    	imgui.SetNextWindowPos(margin, love.graphics.getHeight()-height-margin, "Always")
	    	imgui.SetNextWindowSize(love.graphics.getWidth()-(margin*2), height)
	    	state, UI.titlebar.show_console = imgui.Begin("Console", UI.titlebar.show_console, {"NoResize", "NoMove", "NoCollapse", "NoTitleBar"})

	    	for l, log in ipairs(CONSOLE.log) do
	    		imgui.Text(log)
	    	end

	    	imgui.End()
	    end
	end,

	clear = function() 
		CONSOLE.log = {}
		CONSOLE._last_print = nil
		CONSOLE._repeat_print_count = 1
	end
}

old_print = print
print = function(...) 
    CONSOLE.print(...)
    old_print(...)
end
