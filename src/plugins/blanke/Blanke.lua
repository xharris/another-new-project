local blanke_path = (...):match("(.-)[^%.]+$")

game = {}
AUTO_UPDATE = true

function _addGameObject(type, obj)
    obj.uuid = uuid()
    if obj.update then obj.auto_update = true end
    game[type] = ifndef(game[type],{})
    table.insert(game[type], obj)
end

function _iterateGameGroup(group, func)
    for i, obj in ipairs(game[group]) do
        func(obj)
    end
end

Draw 	= require (blanke_path..'Draw')
Image 	= require (blanke_path..'Image')
Net 	= require (blanke_path..'Net')
Save 	= require (blanke_path..'Save')
Hitbox 	= require (blanke_path..'Hitbox')
Entity 	= require (blanke_path..'Entity')
Map 	= require (blanke_path..'Map')
View 	= require (blanke_path..'View')
Effect 	= require (blanke_path..'Effect')
Dialog 	= require (blanke_path..'Dialog')
Tween 	= require (blanke_path..'Tween')
Scene 	= require (blanke_path..'Scene')

-- prevents updating while window is being moved (would mess up collisions)
local max_fps = 120
local min_dt = 1/max_fps
local next_time = love.timer.getTime()

BlankE = {
	init = function(first_state)
		for f, func in ipairs(BlankE) do
			if type(func) == 'function' and func ~= 'init' then
				old_love[func] = love[func] or __NULL__
				love[func] = function(...)
					old_love[func](...)
					return BlankE[func](...)
				end
			end
		end

	    uuid.randomseed(love.timer.getTime()*10000)
	    
	    --Gamestate.registerEvents()
		-- register gamestates
	    updateGlobals(0)
		if first_state then
			Gamestate.switch(first_state)
		end
	end,

	update = function(dt)
	    dt = math.min(dt, min_dt)
	    next_time = next_time + min_dt

	    updateGlobals(dt)
	    
	    Net.update(dt, false)
	    
	    for i_arr, arr in pairs(game) do
	        for i_e, e in ipairs(arr) do
	            if e.auto_update then
	                e:update(dt)
	            end
	        end
	    end
	end,

	draw = function()
	    local cur_time = love.timer.getTime()
	    if next_time <= cur_time then
	        next_time = cur_time
	        return
	    end
	    love.timer.sleep(next_time - cur_time)
	end,

	keypressed = function(key)
	    _iterateGameGroup("input", function(input)
	        input:keypressed(key)
	    end)
	end,

	keyreleased = function(key)
	    _iterateGameGroup("input", function(input)
	        input:keyreleased(key)
	    end)
	end,

	mousepressed = function(x, y, button) 
	    _iterateGameGroup("input", function(input)
	        input:mousepressed(x, y, button)
	    end)
	end,

	mousereleased = function(x, y, button) 
	    _iterateGameGroup("input", function(input)
	        input:mousereleased(x, y, button)
	    end)
	end,

	quit = function()
	    Net.disconnect()
	end 
}
