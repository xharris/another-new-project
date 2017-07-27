local default = {66,66,66,110}

local scrollbar = {117,117,117,255}

UI = {
	_images = {},
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
		WindowBg = {66,66,66,200},
		MenuBarBg = {66,66,66,110},

		Text = {245,245,245,255},

		ScrollbarBg = {0,0,0,0},
		ScrollbarGrab = scrollbar,
		ScrollbarGrabHovered = scrollbar,
		ScrollbarGrabActive = scrollbar,

		ResizeGrip = {66,66,66,100},
		ResizeGripHovered = {66,66,66,100},
		ResizeGripActive = {66,66,66,100},

		TitleBg = 'love2d_dark',
		TitleBgActive = 'love2d',
		TitleBgCollapsed = 'love2d_transparent',

		CloseButton = {255,255,255,75},
		ClostButtonHovered = {255,255,255,75},
		CloseButtonActive = {255,255,255,75},

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
		secret_stuff = true,

		-- DEV
		show_dev_tools = false,
		show_style_editor = false,
	},

	setting = {
		initial_state = '',
		project_reload_timer = {type='number',value=4,min=0.5,max=60*5},
		console_height = {type='number',value=100,min=0,max=love.graphics.getHeight()/2},
		font = "ProggySquare",
		font_size = {type='number',value=11,min=1,max=100},
		scene_snapx = {type='number',value=32,min=1,max=1000},
		scene_snapy = {type='number',value=32,min=1,max=1000},
	},

	setStyling = function()
		imgui.PushStyleVar('WindowRounding', 6)
		imgui.PushStyleVar('ScrollbarSize', 2)
		imgui.PushStyleVar('ScrollbarRounding', 3)
		imgui.PushStyleVar('GlobalAlpha',1)
		imgui.PushStyleVar('FrameRounding', 3)
		imgui.PushStyleVar('GrabRounding', 2)
		imgui.PushStyleVar('GrabMinSize', 16)
		UI.loadFont()
		for e, el in pairs(UI.elements) do
			imgui.PushStyleColor(e, UI.getColor(el))
		end
	end,

	loadFont = function()
		local font_files = love.filesystem.getDirectoryItems('fonts')
		local font_filename = ''
		local sel_font = UI.getSetting('font')
		for f, file in ipairs(font_files) do
			if file:find(sel_font) then
				font_filename = file
			end
		end

		imgui.SetGlobalFontFromFileTTF("fonts/"..font_filename, 11)
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
--[[
		UI.elements.CloseButton = table.copy(new_color)
		UI.elements.CloseButton[4] = 75
		UI.elements.CloseButtonHovered = UI.elements.CloseButton
		UI.elements.CloseButtonActive = UI.elements.CloseButton
]]
		UI.setStyling()

		return new_color
	end,

	getColor = function(index, dont_divide)
		local ret_color = {}

		if type(index) == "string" then
			index = UI.color[index]
		end

		if not dont_divide then
			for c, color in ipairs(index) do
				table.insert(ret_color, color/255)
			end
		end

		return unpack(ret_color)
	end,

	getElement = function(index, dont_divide)
		local ret_color = {}

		if type(index) == "string" then
			index = UI.elements[index]
		end

		if not dont_divide then
			for c, color in ipairs(index) do
				table.insert(ret_color, color/255)
			end
		end

		return unpack(ret_color)
	end,

	getSetting = function(index)
		local setting = UI.setting[index]

		return setting
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

	loadImage = function(img_path)
		if not UI._images[img_path] then
			UI._images[img_path] = love.graphics.newImage(img_path)
		end
		local img = UI._images[img_path]

		local img_width = img:getWidth()
		local img_height = img:getHeight()

		return img, img_width, img_height
	end,

	drawImage = function(img_path, ...)
		local img, img_width, img_height = UI.loadImage(img_path) 
		return imgui.Image(img, img_width, img_height, ...)
	end,

	drawImageButton = function(img_path, ...)
		local img, img_width, img_height = UI.loadImage(img_path)
		return imgui.ImageButton(img, img_width, img_height, ...)--, 0, 0, 1, 1, 255, 255, 255, 255, UI.getColor('love2d'));
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