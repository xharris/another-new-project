local default = {66,66,66,110}

UI = {
	color = {
		background = {33,33,33,255},
		_love2d = {
			--{244,143,177, 222}, -- pink 200
			{240,98,146, 222}, -- pink 300
			{236,64,122, 222}, -- pink 400
			--{144,202,249, 222}, -- blue 200
			{100,181,246, 222}, -- blue 300
			{66,165,245, 222} -- blue 400
		},
		love2d = default,
		love2d_transparent = default,

		love2d_very_light = default,
		love2d_light = default,

		love2d_dark = default,
		love2d_dark_transparent = default,
	},
	elements = {
		WindowBg = {66,66,66,110},
		MenuBarBg = {66,66,66,110},

		Text = {245,245,245,255},

		ScrollbarBg = {0,0,0,0},
		ScrollbarGrab = {66,66,66,255},
		ScrollbarGrabHovered = {66,66,66,255},
		ScrollbarGrabActive = {66,66,66,255},

		ResizeGrip = {66,66,66,100},
		ResizeGripHovered = {66,66,66,100},
		ResizeGripActive = {66,66,66,100},

		TitleBg = 'love2d_dark',
		TitleBgActive = 'love2d',
		TitleBgCollapsed = 'love2d_transparent',

		Button = 'love2d',
		ButtonHovered = 'love2d_light',
		ButtonActive = 'love2d_dark',

		Header = 'love2d_dark',
		HeaderHovered = 'love2d_dark',
		HeaderActive = 'love2d',

		SliderGrabActive = 'love2d_dark',

		TextDisabled = 'love2d_very_light',
		TextSelectedBg = 'love2d_dark',

		FrameBgHovered = 'love2d_dark_transparent',
		FrameBgActive = 'love2d_dark'
	},

	flags = {
		--"ShowBorders"
	},

	titlebar = {
		-- FILE
		new_project = false,

		-- IDE
		show_console = true,
		show_scene_editor = true,

		-- DEV
		show_dev_tools = false,
		show_style_editor = false,
	},

	setting = {
		initial_state = '',
		project_reload_timer = {type='number',value=3,min=0.5,max=60*5}
	},

	setStyling = function()
		imgui.PushStyleVar('WindowRounding', 3)
		imgui.PushStyleVar('ScrollbarSize', 2)
		imgui.PushStyleVar('ScrollbarRounding', 3)
		imgui.PushStyleVar('GlobalAlpha',1)
		imgui.PushStyleVar('FrameRounding', 3)
		imgui.PushStyleVar('GrabRounding', 2)
		imgui.PushStyleVar('GrabMinSize', 16)

		for e, el in pairs(UI.elements) do
			imgui.PushStyleColor(e, UI.getColor(el))
		end
	end,

	resetStyling = function()
        imgui.PopStyleVar()
        imgui.PopStyleColor()
	end,

	randomizeIDEColor = function()
		math.randomseed(os.time())
		local new_color = UI.color._love2d[math.random(1,#UI.color._love2d)]

		UI.color.love2d = new_color
		love2d_colors = {'transparent', 'very_light', 'light', 'dark', 'dark_transparent'}
		for c, color in ipairs(love2d_colors) do
			UI.color['love2d_'..color] = table.copy(new_color)
		end

		UI.color.love2d_transparent[4] = 50
		UI.color.love2d_dark_transparent[4] = 100
		for c = 1,3 do
			UI.color.love2d_very_light[c] = UI.color.love2d_very_light[c] + 40
			UI.color.love2d_light[c] = UI.color.love2d_light[c] + 20
			UI.color.love2d_dark[c] = UI.color.love2d_dark[c] - 80
		end

		UI.elements.CloseButton = table.copy(new_color)
		UI.elements.CloseButton[4] = 0
		UI.elements.CloseButtonHovered = UI.elements.CloseButton
		UI.elements.CloseButtonActive = UI.elements.CloseButton

		UI.setStyling()

		return new_color
	end,

	getColor = function(index)
		local ret_color = {}

		if type(index) == "string" then
			index = UI.color[index]
		end

		for c, color in ipairs(index) do
			ret_color[c] = color/255
		end

		return unpack(ret_color)
	end,

	getSetting = function(index)
		local setting = UI.setting[index]

		if type(setting) == 'table' then
			if setting.type == 'number' then
				return setting
			end
			return UI.setting[index].value
		else
			return setting
		end
	end,

	setSetting = function(index, value)
		local setting = UI.setting[index]

		if setting.type == 'number' then
			if value >= ifndef(setting.min, value) and value <= ifndef(setting.max, value) then
				UI.setting[index].value = value
			end
		else
			UI.setting[index] = value
		end
	end,
}

-- not working atm
checkUI = function(index, func)
	local parts = index:split('.')
	index = UI
	for p, part in ipairs(parts) do
		index = index[part]
	end
	if index then index = func() end
end