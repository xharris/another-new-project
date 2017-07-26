SYSTEM = {
	os = '',

	runCmd = function(commands, func)
		if commands[SYSTEM.os] then
			local pfile = popen(commands[SYSTEM.os])
		    if func then func(pfile) end
		    pfile:close()
		end
	end,

	scandir = function(directory) 
	    local i, t, popen = 0, {}, io.popen

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
		SYSTEM.os = os_type
		return os_type
	end
}

print('OS: '..SYSTEM.os())