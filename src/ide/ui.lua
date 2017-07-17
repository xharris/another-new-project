local default = {0,0,0,222}

UI = {
	color = {
		background = {33,33,33,255},
		_love2d = {
			{244,143,177, 222}, -- pink 200
			{240,98,146, 222}, -- pink 300
			{236,64,122, 222}, -- pink 400
			{144,202,249, 222}, -- blue 200
			{100,181,246, 222}, -- blue 300
			{66,165,245, 222} -- blue 400
		},
		love2d = default,
		love2d_transparent = default,

		love2d_lighter = default,

		love2d_darker = default,
		love2d_darker_transparent = default,

		WindowBg = {0, 0, 0, 230},
		MenuBarBg = {0, 0, 0, 100},

		Text = {245,245,245,255},
		TextDisabled = {158,158,158,255},

		ScrollbarBg = {0,0,0,0},
		ScrollbarGrab = {117,117,117,255},
		ScrollbarGrabHovered = {66,66,66,255},
		ScrollbarGrabActive = {66,66,66,255},
	},

	titlebar = {
		-- FILE
		new_project = false,

		-- DEV
		show_dev_tools = false,
		show_style_editor = false,
	},

	setStyling = function()
		imgui.PushStyleVar('WindowRounding', 3)
		imgui.PushStyleVar('ScrollbarSize', 2)
		imgui.PushStyleVar('ScrollbarRounding', 3)
		imgui.PushStyleVar('GlobalAlpha',1)
		imgui.PushStyleVar('FrameRounding', 3)
		imgui.PushStyleVar('GrabRounding', 2)
		imgui.PushStyleVar('GrabMinSize', 16)

		imgui.PushStyleColor('TitleBg', UI.getColor('love2d_darker'))
		imgui.PushStyleColor('TitleBgActive', UI.getColor('love2d'))
		imgui.PushStyleColor('TitleBgCollapsed', UI.getColor('love2d_transparent'))

		imgui.PushStyleColor('Button', UI.getColor('love2d'))
		imgui.PushStyleColor('ButtonHovered', UI.getColor('love2d_lighter'))
		imgui.PushStyleColor('ButtonActive', UI.getColor('love2d_darker'))

		imgui.PushStyleColor('Header', UI.getColor('love2d_darker'))
		imgui.PushStyleColor('HeaderHovered', UI.getColor('love2d_darker'))
		imgui.PushStyleColor('HeaderActive', UI.getColor('love2d'))

		imgui.PushStyleColor('SliderGrabActive', UI.getColor('love2d_darker'))

		imgui.PushStyleColor('TextSelectedBg', UI.getColor('love2d_darker'))

		imgui.PushStyleColor('FrameBgHovered', UI.getColor('love2d_darker_transparent'))
		imgui.PushStyleColor('FrameBgActive', UI.getColor('love2d_darker'))

		local elements = {
			'Text', 'TextDisabled',
			'WindowBg', 'MenuBarBg',
			'CloseButton','CloseButtonHovered','CloseButtonActive',
			'ScrollbarBg','ScrollbarGrab','ScrollbarGrabHovered','ScrollbarGrabActive'
		}
		for e, el in ipairs(elements) do
			imgui.PushStyleColor(el, UI.getColor(el))
		end
	end,

	resetStyling = function()
        imgui.PopStyleVar()
        imgui.PopStyleColor()
	end,

	randomizeIDEColor = function()
		local new_color = UI.color._love2d[math.random(1,#UI.color._love2d)]
		print('randomized',unpack(new_color))

		UI.color.love2d = new_color
		UI.color.love2d_transparent = table.copy(new_color)
		UI.color.love2d_lighter = table.copy(new_color)
		UI.color.love2d_darker = table.copy(new_color)
		UI.color.love2d_darker_transparent = table.copy(new_color)

		UI.color.love2d_transparent[4] = 50
		UI.color.love2d_darker_transparent[4] = 100
		for c = 1,3 do
			UI.color.love2d_lighter[c] = UI.color.love2d_lighter[c] + 20
			UI.color.love2d_darker[c] = UI.color.love2d_darker[c] - 80
		end

		UI.color.CloseButton = table.copy(new_color)
		UI.color.CloseButton[4] = 0
		UI.color.CloseButtonHovered = UI.color.CloseButton
		UI.color.CloseButtonActive = UI.color.CloseButton

		UI.setStyling()

		return new_color
	end,

	getColor = function(index)
		local ret_color = {}

		for c, color in ipairs(UI.color[index]) do
			ret_color[c] = color/255
		end

		return unpack(ret_color)
	end,
}

UI.randomizeIDEColor()

-- not working atm
checkUI = function(index, func)
	local parts = index:split('.')
	index = UI
	for p, part in ipairs(parts) do
		index = index[part]
	end
	if index then index = func() end
end