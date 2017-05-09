local _effects = {}
Effect = Class{
	init = function (self, name)
		self._shader = nil
		self._effect_data = nil

		-- load stored effect
		if _effects[name] then
			self._effect_data = _effects[name]

			-- turn options into member variables
			for p, default in pairs(_effects[name].params) do
				self[p] = default
			end	

			-- setup shader
			self._shader = love.graphics.newShader(_effects[name].string)
		end	
	end,

	draw = function (self)
		love.graphics.setShader(self._shader)
		-- send variables
		for p, default in pairs(self._effect_data.params) do
			local var_name = p
			local var_value = default

			if self[p] then
				var_value = self[p]
			end

			self._shader:send(var_name, var_value)
		end
	end,

	clear = function(self)
		love.graphics.setShader()
	end
}

local _love_replacements = {
	["float"] = "number",
	["sampler2D"] = "Image",
	["uniform"] = "extern",
	["texture2D"] = "Texel"
}
EffectManager = Class{
	new = function (name, params, string)
		local new_eff = {}
		new_eff.string = string
		new_eff.params = params

		-- port non-LoVE keywords
		local r
		for old, new in pairs(_love_replacements) do
			new_eff.string, r = new_eff.string:gsub(old, new)
		end

		_effects[name] = new_eff
		return Effect(name)
	end,
}

EffectManager.new(
	'grayscale',
	{['factor']=1},
	[[
        extern number factor;
        
        vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
            vec4 pixel = Texel(texture, texture_coords );
            
            number average = (pixel.r + pixel.b + pixel.g)/3.0;
            
            pixel.r = pixel.r + (average-pixel.r) * factor;
            pixel.g = pixel.g + (average-pixel.g) * factor;
            pixel.b = pixel.b + (average-pixel.b) * factor;
            
            return pixel;
        }
	]]
)

EffectManager.new(
	'chroma shift',
	{['chroma'] = {1, 1}, ['imageSize'] = {20, 20}},
	[[ 
		#ifdef PIXEL
		extern vec2 chroma;
		extern vec2 imageSize;

		vec4 effect(vec4 color, Image tex, vec2 tc, vec2 pc)
		{
			vec2 screenSize = love_ScreenSize.xy;        
			number factor_x = pc.x/screenSize.x;
			number factor_y = pc.y/screenSize.y;
			number factor = (factor_x + factor_y)/2.0;

            vec2 shift = (chroma / imageSize) * factor;
			return vec4(Texel(tex, tc+shift).r, Texel(tex,tc).g, Texel(tex,tc-shift).b, Texel(tex, tc).a);
		}
		#endif
	]]
)

EffectManager.new(
	'ripple',
	{['x'] = 0, ['y'] = 0, ['time'] = 0, ['img'] = nil},
	[[
		extern number time = 0.0;
        extern number x = 0.25;
        extern number y = -0.25;
        extern number size = 32.0;
        extern number strength = 8.0;
        extern vec2 res = vec2(512.0, 512.0);
        uniform sampler2D img;
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
        {
            float tmp = cos(clamp(sqrt(pow((texture_coords.x - x) * size - size / 2.0, 2.0) + pow((texture_coords.y - y) * size - size / 2.0, 2.0)) - time * 16.0, -3.1415, 3.1415));
            vec2 uv         = vec2(
                texture_coords.x - tmp * strength / 1024.0,
                texture_coords.y - tmp * strength / 1024.0
            );
         return vec4(texture2D(img,uv));
        }
	]]
)

--[[
scale with screen position

vec2 screenSize = love_ScreenSize.xy;        
number factor_x = screen_coords.x/screenSize.x;
number factor_y = screen_coords.y/screenSize.y;
number factor = (factor_x + factor_y)/2.0;

]]--

return Effect