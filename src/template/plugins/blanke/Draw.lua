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
    
    callDrawFunc = function(shape, args)
		Draw._draw(function()
			love.graphics[shape](unpack(args))
		end)
		return Draw
    end,
    
    point = function(...) Draw.callDrawFunc('points', {...}) end,
    line = function(...) Draw.callDrawFunc('line', {...}) end,
    rect = function(...) Draw.callDrawFunc('rectangle', {...}) end,
    circle = function(...) Draw.callDrawFunc('circle', {...}) end,
    polygon = function(...) Draw.callDrawFunc('polygon', {...}) end,
    text = function(...) Draw.callDrawFunc('print', {...}) end,
}

love.graphics.setDefaultFilter("nearest","nearest")

return Draw