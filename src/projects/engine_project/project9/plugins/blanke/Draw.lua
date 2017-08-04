Draw = Class{
	color = {0,0,0,255},

	setColor = function(r,g,b,a)
		color = r
		if (type(color) == "string") then
			color = hex2rgb(color)
		end

		if (type(color) == "number") then
			color = {r,g,b,a}
		end
		Draw.color = color
		return Draw
	end,

	resetColor = function()
		Draw.color = {0,0,0,255}
		return Draw
	end,

	_draw = function(func)
		love.graphics.push('all')
		love.graphics.setColor(Draw.color)
		func()
		love.graphics.pop()
		return Draw
	end,

	rect = function(...)
		local args = {...}
		Draw._draw(function()
			love.graphics.rectangle(unpack(args))
		end)
		return Draw
	end,

	circle = function(...)
		local args = {...}
		Draw._draw(function()
			love.graphics.circle(unpack(args))
		end)
		return Draw
	end,
}

return Draw