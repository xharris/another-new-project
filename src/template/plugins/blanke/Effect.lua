--[[
completely working effects:
 - chroma shift : angle(rad), radius
 - crt : lineSize(vec2) opacity, scanlines(bool), distortion, inputGamma, outputGamma
 - 
]]
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
			_effects[name].params = ifndef(_effects[name].params, {})
			for p, default in pairs(_effects[name].params) do
				self[p] = default

				if p == "textureSize" or p == "texSize" then
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
	end,

	applyParams = function(self)
		-- send variables
		for p, default in pairs(self._effect_data.params) do
			local var_name = p
			local var_value = default

			if self[p] ~= nil then
				var_value = self[p]
				self:send(var_name, var_value)
			end
		end
	end,

	draw = function (self, func)
		if self.pause then
			func()
		elseif not self._effect_data.extra_draw then
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
		if type(value) == 'boolean' then
			if value then value = 1 
			else value = 0 end
		end
		self._shader:send(name, value)
		return self
	end
	--[[
	-- bug: self is not passed
	__newindex = function (self, key, value)
		print_r(self)
		print(key, value)
		if self._effect_data.params[key] ~= nil then
			print(key, value)
			self._effect_data.params[key] = value
		else return self[key] end
	end
	]]
}

local _love_replacements = {
	["float"] = "number",
	["sampler2D"] = "Image",
	["uniform"] = "extern",
	["texture2D"] = "Texel",
	["gl_FragColor"] = "pixel",
	["gl_FragCoord.xy"] = "screen_coords"
}
EffectManager = Class{
	new = function (options)
		local new_eff = {}
		new_eff.string = ifndef(options.shader,'')
		new_eff.params = options.params
		new_eff.extra_draw = options.draw

		-- add helper funcs
		if new_eff.string == '' then
			for var_name, value in pairs(options.params) do
				if type(value) == 'table' then
					new_eff.string = new_eff.string .. "uniform vec"..tostring(#value).." "..var_name..";\n"
				end
				if type(value) == 'number' then
					new_eff.string = new_eff.string .. "uniform float "..var_name..";\n"
				end
			end
			new_eff.string = new_eff.string.. 
[[
/* From glfx.js : https://github.com/evanw/glfx.js */
float random(vec2 scale, vec2 gl_FragCoord, float seed) {
	/* use the fragment position for a different seed per-pixel */
	return fract(sin(dot(gl_FragCoord + seed, scale)) * 43758.5453 + seed);
}

#ifdef VERTEX
	vec4 position(mat4 transform_projection, vec4 vertex_position) {
]]
..ifndef(options.vertex, '')..
[[
		return transform_projection * vertex_position;
	}
#endif

#ifdef PIXEL
	vec4 effect(vec4 in_color, Image texture, vec2 texCoord, vec2 screen_coords){
		vec4 pixel = Texel(texture, texCoord);
]]
..ifndef(options.effect, '')..
[[
		return pixel * in_color;
	}
#endif
]]
			-- port non-LoVE keywords
			local r
			for old, new in pairs(_love_replacements) do
				new_eff.string, r = new_eff.string:gsub(old, new)
			end
		end
		_effects[options.name] = new_eff
		--return Effect(options.name)
	end,

	-- doesn't seem to work
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

EffectManager.new{
	name = 'bloom',
	params = {['screen_size']={0,0}, ['samples']=5, ['quality']=1},
	shader = [[
// adapted from http://www.youtube.com/watch?v=qNM0k522R7o

extern vec2 screen_size;
extern int samples; // pixels per axis; higher = bigger glow, worse performance
extern float quality; // lower = smaller glow, better quality

vec4 effect(vec4 colour, Image tex, vec2 tc, vec2 sc)
{
  vec4 source = Texel(tex, tc);
  vec4 sum = vec4(0);
  int diff = (samples - 1) / 2;
  vec2 sizeFactor = vec2(1) / screen_size * quality;
  
  for (int x = -diff; x <= diff; x++)
  {
    for (int y = -diff; y <= diff; y++)
    {
      vec2 offset = vec2(x, y) * sizeFactor;
      sum += Texel(tex, tc + offset);
    }
  }
  
  return ((sum / (samples * samples)) + source) * colour;
}
	]]
}

EffectManager.new{
	name = 'chroma shift',
	params = {['angle']=0,['radius']=4,['direction']={0,0}},--['strength'] = {1, 1}, ['size'] = {20, 20}},
	shader = [[ 
		#ifdef PIXEL
		extern vec2 direction;

		vec4 effect(vec4 color, Image texture, vec2 tc, vec2 _)
		{
			return color * vec4(
				Texel(texture, tc - direction).r,
				Texel(texture, tc).g,
				Texel(texture, tc + direction).b,
				1.0);
		}
		#endif
	]],
	draw = function(self, draw) 
		local dx = math.cos(self.angle) * self.radius / love.graphics.getWidth()
		local dy = math.sin(self.angle) * self.radius / love.graphics.getHeight()
		self:send("direction", {dx,dy})
		
		self:applyShader(draw)
	end,
}

EffectManager.new{
	name = 'zoom_blur',
	params = {
	['center']={0,0},['strength']=0.3,
	['texSize']={game_width,game_height}, 
	},
	effect =
[[
	    vec4 color = vec4(0.0);
	    float total = 0.0;
	    vec2 toCenter = center - texCoord * texSize;
	    
	    /* randomize the lookup values to hide the fixed number of samples */
	    float offset = random(vec2(12.9898, 78.233), screen_coords, 0.0);
	    
	    for (float t = 0.0; t <= 40.0; t++) {
	        float percent = (t + offset) / 40.0;
	        float weight = 4.0 * (percent - percent * percent);
	        vec4 sample = texture2D(texture, texCoord + toCenter * percent * strength / texSize);
	        
	        /* switch to pre-multiplied alpha to correctly blur transparent images */
	        sample.rgb *= sample.a;
	        
	        color += sample * weight;
	        total += weight;
	    }
	    
	    gl_FragColor = color / total;
	    
	    /* switch back from pre-multiplied alpha */
	    gl_FragColor.rgb /= gl_FragColor.a + 0.00001;
]]
	}

return Effect