SYSTEM = {
	os = '',
	os_names = {
		NT='win',
		Darwin='mac'
	},

	runCmd = function(commands, func)
		if commands[SYSTEM.os] then
			local pfile = io.popen(commands[SYSTEM.os])
		    if func then func(pfile) end
		    pfile:close()
		end
	end,

	scandir = function(directory) 
	    local i, t = 0, {}

	    SYSTEM.runCmd(
		    {
		    	win='dir "'..directory..'" /b',
		    	mac='ls -a "'..directory..'"'
		    },
		    function(pfile)
			    for filename in pfile:lines() do
			        i = i + 1
			        t[i] = filename
			    end
		    end
	    )

	    return t
	end,

	mkdir = function(path)
		SYSTEM.runCmd(
			{
				mac="mkdir -p "..path
			}
		)
	end,

	os = function()
		local pfile = io.popen("uname")
		local os_type = pfile:read("*a")
		pfile:close()

		for alias, name in pairs(SYSTEM.os_names) do
			if os_type:match(alias) then
				SYSTEM.os = name
				return name
			end
		end
	end
}

print('OS: '..SYSTEM.os())