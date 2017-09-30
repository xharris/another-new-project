Draw = Class{
	color = {0,0,0,255},

	_parseColorArgs = function(r,g,b,a)
		color = r
		if (type(color) == "string") then
			color = hex2rgb(color)
		end

		if (type(color) == "number") then
			color = {r,g,b,a}
		end
		return color
	end,

	setBackgroundColor = function(r,g,b,a)
		love.graphics.setBackgroundColor(Draw._parseColorArgs(r,g,b,a))
		return Draw
	end,

	setColor = function(r,g,b,a)
		Draw.color = Draw._parseColorArgs(r,g,b,a)
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
    
    callDrawFunc = function(shape, args)
		Draw._draw(function()
			love.graphics[shape](unpack(args))
		end)
		return Draw
    end,
    
    point 	= function(...) return Draw.callDrawFunc('points', {...}) end,
    line 	= function(...) return Draw.callDrawFunc('line', {...}) end,
    rect 	= function(...) return Draw.callDrawFunc('rectangle', {...}) end,
    circle 	= function(...) return Draw.callDrawFunc('circle', {...}) end,
    polygon = function(...) return Draw.callDrawFunc('polygon', {...}) end,
    text 	= function(...) return Draw.callDrawFunc('print', {...}) end,
}

love.graphics.setDefaultFilter("nearest","nearest")

return Draw