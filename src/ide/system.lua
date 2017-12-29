SYSTEM = {
	os = '',
	cwd = '',
	exe_mode = false,
	src = '', 		-- turns into src/ if in exe_mode
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
			local pfile = io.popen(commands[SYSTEM.os])
		    if func then func(pfile) end
		    pfile:close()
		end
	end,

	scandir = function(directory, remove_dot_files) 
	    local i, t = 0, {}
	    remove_dot_files = ifndef(remove_dot_files, true)
--[[
	    for file in lfs.dir(directory) do
    		if not remove_dot_files or (remove_dot_files and not file:starts('.')) then
			    table.insert(t, file)
			end
		end
		print(unpack(t))
]]
		--
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

	loveScandir = function(directory)
		return love.filesystem.getDirectoryItems(directory)
	end,

	exists = function(path)
	   return love.filesystem.exists(path)
	   --local f=io.open(path,"r")
	   --if f~=nil then io.close(f) return true else return false end
	end,

	mkdir = function(path)
		if not SYSTEM.exists(path) then
			if not SYSTEM.exists(path) then
				--lfs.mkdir(path)
				
				SYSTEM.runCmd(
					{
						mac="mkdir -p \""..path.."\"",
						win="mkdir \""..path.."\""
					}
				)
			end
			--[[
			path = lfs.normalize(path)
			if lfs.exists(path) then
				return true
			end
			if lfs.dirname(path) == path then
				-- We're being asked to create the root directory!
				return nil,"mkdir: unable to create root directory"
			end
			local r,err = lfs.rmkdir(lfs.dirname(path))
			if not r then
				return nil,err.." (creating "..path..")"
			end
			return lfs.mkdir(path)
			]]
		end
	end,

	copy = function(src, dest)
		SYSTEM.mkdir(dirname(dest))
		
		--local path_parts = string.match(src, "(.-)([^\\]-([^%.]+))$")
		
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
		--[[
		if not lfs.rmdir(path) then -- can't delete non-empty dir
			os.remove(path)
		end	]]
		SYSTEM.runCmd(
			{
				win='rm -r "'..path..'"',
				mac='rm -rf "'..path..'"'
			}
		)
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
				win='start /b \"\" \"'..cmd..'\"'
			}
		)
	end,

	-- TODO: untested
	zip = function(src, dest)
		SYSTEM.runCmd(
			{
				mac="cd \""..src.."\"; zip -9 -r \""..dest.."\" .",
				win=SYSTEM.cwd.."/helper.exe \""..src.."\" \""..dest.."\""
			}
		)
	end
}


SYSTEM.getOS()
--print('OS: '..SYSTEM.os)
SYSTEM.cwd = love.filesystem.getSource()
if string.sub(SYSTEM.cwd,-string.len(".exe"))==".exe" then
	SYSTEM.exe_mode = true
	SYSTEM.cwd = love.filesystem.getSourceBaseDirectory()
	SYSTEM.src = 'src/'
end
--print("CWD: "..SYSTEM.cwd)