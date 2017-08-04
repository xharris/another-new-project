-- completely working effects:
-- - chroma shift : angle(rad), radius


local _effects = {}
Effect = Class{
	init = function (self, name)
		self._shader = nil
		self._effect_data = nil
		self.name = name
		self.canvas = {love.graphics.newCanvas(love.window.getDesktopDimensions())}

		-- load stored effect
		assert(_effects[name]~=nil, "Effect '"..name.."' not found")
		if _effects[name] then
			self._effect_data = _effects[name]

			-- turn options into member variables
			for p, default in pairs(_effects[name].params) do
				self[p] = default

				if p == "textureSize" then
					self[p] = {game_width, game_height}
				end
			end	

			-- setup shader
			self._shader = love.graphics.newShader(_effects[name].string)
		end	

		if self.create then self:create() end

		_addGameObject('effect',self)
	end,

	update = function(self, dt)
		if self.time then self.time = self.time + dt end
		if self.dt then self.dt = self.dt + dt end
		if self.screen_size then self.screen_size = {game_width, game_height} end
		if self.inv_screen_size then self.inv_screen_size = {1/game_width, 1/game_height} end
		return self
	end,

	applyCanvas = function(self, func, canvas)
		local curr_canvas = love.graphics.getCanvas()

		love.graphics.setCanvas(canvas)
		love.graphics.clear(255,255,255,0)
		func()
		love.graphics.setCanvas(curr_canvas)
	end,

	applyShader = function(self, func, shader, canvas)
		shader = ifndef(shader, self._shader)
		canvas = ifndef(canvas, self.canvas[1])

		local curr_shader = love.graphics.getShader()
		local curr_color = {love.graphics.getColor()}
		local curr_blend = love.graphics.getBlendMode()

		self:applyCanvas(func, canvas)

		love.graphics.setColor(curr_color)
		love.graphics.setShader(shader)
		love.graphics.setBlendMode('alpha', 'premultiplied')

		love.graphics.draw(canvas, 0 ,0)
		love.graphics.setBlendMode(curr_blend)
		love.graphics.setShader(curr_shader)
		BlankE._drawGrid()
	end,

	applyParams = function(self)
		-- send variables
		for p, default in pairs(self._effect_data.params) do
			local var_name = p
			local var_value = default

			if self[p] then
				var_value = self[p]
				self:send(var_name, var_value)
			end
		end
	end,

	draw = function (self, func)
		if not self._effect_data.extra_draw then
			self:applyParams()

			if func then
				self:applyShader(func, self._shader, self.canvas[1])
			end


		-- call extra draw function
		else
			self._effect_data.extra_draw(self, func)
		end
		return self
	end,

	send = function (self, name, value)
		self._shader:send(name, value)
		return self
	end,
}

local _love_replacements = {
	["float"] = "number",
	["sampler2D"] = "Image",
	["uniform"] = "extern",
	["texture2D"] = "Texel"
}
EffectManager = Class{
	new = function (options)
		local new_eff = {}
		new_eff.string = options.shader
		new_eff.params = options.params
		new_eff.extra_draw = options.draw

		-- port non-LoVE keywords
		local r
		for old, new in pairs(_love_replacements) do
			new_eff.string, r = new_eff.string:gsub(old, new)
		end

		_effects[options.name] = new_eff
		--return Effect(options.name)
	end,

	load = function(file_path)
		love.filesystem.load(file_path)()
	end,

	_render_to_canvas = function(canvas, func)
		local old_canvas = love.graphics.getCanvas()

		love.graphics.setCanvas(canvas)
		love.graphics.clear()
		func()

		love.graphics.setCanvas(old_canvas)
	end
}

-- global shader vals: https://www.love2d.org/wiki/Shader_Variables

EffectManager.new{
	name = 'template',
	params = {['myNum']=1},
	shader = [[
extern number myNum;

#ifdef VERTEX
	vec4 position( mat4 transform_projection, vec4 vertex_position ) {
		return transform_projection * vertex_position;
	}
#endif

#ifdef PIXEL
	// color 			- color set by love.graphics.setColor
	// texture 			- image being drawn
	// texture_coords 	- coordinates of pixel relative to image (x, y)
	// screen_coords 	- coordinates of pixel relative to screen (x, y)

	vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ) {
		// Texel returns a pixel color after taking in a texture and coordinates of pixel relative to texture
		// Texel -> (r, g, b)
		vec4 pixel = Texel(texture, texture_coords );	

		pixel.r = pixel.r * myNum;
		pixel.g = pixel.g * myNum;
		pixel.b = pixel.b * myNum;
		return pixel;
	}
#endif
	]]
}

--[[
scale with screen position

vec2 screenSize = love_ScreenSize.xy;        
number factor_x = screen_coords.x/screenSize.x;
number factor_y = screen_coords.y/screenSize.y;
number factor = (factor_x + factor_y)/2.0;

]]--

return Effect