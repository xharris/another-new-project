SYSTEM = {
	os = '',
	cwd = '',
	os_names = {
		NT='win',
		Darwin='mac'
	},

	winPath = function(path)
		return path:gsub("(\\)","\\\\"):gsub("(/)","\\\\")
	end,

	-- cleans up slashes
	cleanPath = function(path)
		return path:gsub("(\\)","/"):gsub("(\\\\)","/")
	end,

	runCmd = function(commands, func)
		if commands[SYSTEM.os] then
			print(commands[SYSTEM.os])
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

	exists = function(path)
	   return love.filesystem.exists(path)
	   --local f=io.open(path,"r")
	   --if f~=nil then io.close(f) return true else return false end
	end,

	mkdir = function(path)
		if not SYSTEM.exists(path) then
			lfs.mkdir(path)
			--[[
			SYSTEM.runCmd(
				{
					mac="mkdir -p \""..path.."\"",
					win="mkdir \""..path.."\""
				}
			)]]
		end
	end,

	copy = function(src, dest)
		SYSTEM.mkdir(dirname(dest))
		SYSTEM.runCmd(
			{
				win='cp -R "'..src..'" "'..dest..'"',
				mac='cp -R "'..src..'" "'..dest..'"'
			}
		)
	end,

	rename = function(src, dest)
		SYSTEM.mkdir(dirname(dest))
		SYSTEM.runCmd(
			{
				win='mv "'..src..'" "'..dest..'"',
				mac='mv "'..src..'" "'..dest..'"'
			}
		)
	end,

	remove = function(path)
		lfs.rmdir(path)
		--[[
		SYSTEM.runCmd(
			{
				win='rm -r "'..path..'"',
				mac='rm -rf "'..path..'"'
			}
		)]]
	end,

	getOS = function()
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

	edit = function(path)
		SYSTEM.runCmd(
			{
				mac='open \"'..path..'\"',
				win='start \"\" \"'..path..'\"'
			}
		)	
	end,

	explore = function(path)
		love.system.openURL("file://"..path)
	end,

	execute = function(cmd)
		SYSTEM.runCmd(
			{
				mac="echo "..cmd.." > blanke.command; chmod +x blanke.command; open blanke.command",
				win='start \"\" \"'..cmd..'\"'
			}
		)
	end,
}

print('OS: '..SYSTEM.getOS())

SYSTEM.runCmd({
	mac='pwd',
	win='echo %cd%'
},function(pfile)
	SYSTEM.cwd = pfile:read'*l'
	print('CWD',SYSTEM.cwd)
end)
