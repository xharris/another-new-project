SYSTEM = {
	os = '',
	cwd = '',
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

	scandir = function(directory, remove_dot_files) 
	    local i, t = 0, {}
	    remove_dot_files = ifndef(remove_dot_files, true)

	    SYSTEM.runCmd(
		    {
		    	win='dir "'..directory..'" /b',
		    	mac='ls -a "'..directory..'"'
		    },
		    function(pfile)
			    for filename in pfile:lines() do
					if not remove_dot_files or (remove_dot_files and not filename:starts('.')) then
				        i = i + 1
				        t[i] = filename
				    end
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

	copy = function(src, dest)
		SYSTEM.mkdir(dirname(dest))
		SYSTEM.runCmd(
			{
				mac='cp -R "'..src..'" "'..dest..'"'
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
	end,

	execute = function(cmd)
		SYSTEM.runCmd(
			{
				mac=cmd,
				win='start \"\" \"'..cmd..'\"'
			}
		)
	end,
}

SYSTEM.runCmd({
	mac='cd',
	win='cd'
},function(pfile)
	print('hi')
	SYSTEM.cwd = pfile:read'*l'
	print('CWD',SYSTEM.cwd)
end)

print('OS: '..SYSTEM.os())