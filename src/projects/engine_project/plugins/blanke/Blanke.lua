local blanke_path = (...):match("(.-)[^%.]+$")

game = {}
AUTO_UPDATE = true

function _addGameObject(type, obj)
    obj.uuid = uuid()
    if obj.update then obj.auto_update = true end
    game[type] = ifndef(game[type],{})
    table.insert(game[type], obj)

    if BlankE and BlankE._ide_mode then -- (cant access BlankE for some reason)
    	IDE.onAddGameObject(type)
    end
end

function _iterateGameGroup(group, func)
	game[group] = ifndef(game[group], {})
    for i, obj in ipairs(game[group]) do
        func(obj, i)
    end
end

function _destroyGameObject(type, del_obj)
	_iterateGameGroup(type, function(obj, i)
		if obj.uuid == del_obj.uuid then
			del_obj._destroyed = true
			table.remove(game[type],i)
		end
	end)
end	

Signal	= require (blanke_path..'Signal')
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

_err_state = Class{error_msg='NO GAME'}

BlankE = {
	_ide_mode = false,
	_mouse_x = 0,
	_mouse_y = 0,
	_callbacks_replaced = false,
	init = function(first_state)
		first_state = ifndef(first_state, _err_state)
		if not BlankE._callbacks_replaced then
			BlankE._callbacks_replaced = true

			if not BlankE._ide_mode then
				old_love = {}
				for fn_name, func in pairs(BlankE) do
					if type(func) == 'function' and fn_name ~= 'init' then
						old_love[fn_name] = love[fn_name]
						love[fn_name] = function(...)
							if old_love[fn_name] then old_love[fn_name](...) end
							return func(...)
						end
					end
				end
			end
			
			if BlankE._ide_mode then
	    		Gamestate.registerEvents({'update'})
	    	else
	    		Gamestate.registerEvents()
	    	end
		end
	    uuid.randomseed(love.timer.getTime()*10000)
	    
		-- register gamestates
	    updateGlobals(0)
		if first_state then
			Gamestate.switch(first_state)
		end
	end,

	reloadAssets = function()
		require 'assets'
	end,

	getCurrentState = function()
		local state = Gamestate.current()
		if type(state) == "string" then
			return state
		end
		if type(state) == "table" then
			return state.classname
		end
		return state
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
		_iterateGameGroup('scene', function(scene)
			scene._is_active = false
		end)

	    local cur_time = love.timer.getTime()
	    if next_time <= cur_time then
	        next_time = cur_time
	        return
	    end
	    love.timer.sleep(next_time - cur_time)
	end,

	resize = function(w,h)
		if BlankE._ide_mode then
			_iterateGameGroup('scene', function(scene)
				scene:_drawGrid()
			end)
		end
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
	end,

	errhand = function(msg)
		_err_state.error_msg = msg
		_err_state.draw()
	end,
}

local _offset=0
function _err_state:draw()
	local _max_size = math.max(game_width, game_height)
	_offset = _offset + 1
	if _offset >= _max_size then _offset = 0 end

	love.graphics.push('all')
	for _c = 0,_max_size*2,10 do
		local _new_radius = _c-_offset
		local opacity = (_new_radius/_max_size)*300
		love.graphics.setColor(0,(_new_radius)/_max_size*255,0,opacity)
		love.graphics.circle("line", game_width/2, game_height/2, _new_radius)
	end
	local posx = 0
	local posy = game_height/2
	local align = "center"
	if #_err_state.error_msg > 100 then
		align = "left"
		posx = love.window.toPixels(70)
		posy = posx
	end
	love.graphics.setColor(255,255,255,sinusoidal(150,255,0.5))
	love.graphics.printf(_err_state.error_msg,posx,posy,game_width,align)
	love.graphics.pop()
end	

