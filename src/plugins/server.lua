local os_list = {'love','win','mac'}--,'web','android','ios'}

local love2d_binary_path = {
	win=dirname(SYSTEM.cwd)..'/love2d',
	mac=SYSTEM.cwd..'/love.app'
}

server = {
	project_plugin = true,

	onMenuDraw = function()
		if imgui.MenuItem("run server") then
			SYSTEM.execute(love2d_binary_path['win'].."/love.exe\" \""..SYSTEM.cleanPath(IDE.getTemplatePath().."/plugins/blanke/extra/netserver").."\"")
		end
	end,
}

return server