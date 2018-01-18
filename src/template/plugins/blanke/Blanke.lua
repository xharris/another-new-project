blanke_path = (...):match("(.-)[^%.]+$")
function blanke_require(import)
	return require(blanke_path..import)
end

blanke_require('Globals')
blanke_require('Util')
blanke_require('Debug')

game = {}
AUTO_UPDATE = true

function _addGameObject(type, obj)
    obj.uuid = uuid()
    obj.nickname = ifndef(obj.nickname,obj.classname)
    obj.pause = ifndef(obj.pause, false)
    obj._destroyed = ifndef(obj._destroyed, false)

    if obj._update or obj.update then obj.auto_update = true end

    obj._destroyed = false
    if not obj.destroy then
    	obj.destroy = function(self)
	    	_destroyGameObject(type,self)
	    	self = nil
	    end
    end

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
			for var_name, value in pairs(del_obj) do
				del_obj[var_name] = nil
			end
			table.remove(game[type],i)
		end
	end)
end	

blanke_require("extra.printr")
blanke_require("extra.json")
uuid 	= blanke_require("extra.uuid")

Class 	= blanke_require('Class')	-- hump.class

anim8 	= blanke_require('extra.anim8')
HC 		= blanke_require('extra.HC')
grease 	= blanke_require('extra.grease')

State	= blanke_require('State')
Input 	= blanke_require('Input')
Timer 	= blanke_require('Timer')
Signal	= blanke_require('Signal')
Draw 	= blanke_require('Draw')
Image 	= blanke_require('Image')
Net 	= blanke_require('Net')
Save 	= blanke_require('Save')
Hitbox 	= blanke_require('Hitbox')
Entity 	= blanke_require('Entity')
Map 	= blanke_require('Map')
View 	= blanke_require('View')
Effect 	= blanke_require('Effect')
Dialog 	= blanke_require('Dialog')
Tween 	= blanke_require('Tween')
Scene 	= blanke_require('Scene')
Camera 	= blanke_require('Camera') 	-- hump.camera cuz it's so brilliant
Canvas  = blanke_require('Canvas')

-- load bundled effects
local eff_path = dirname((...):gsub('[.]','/'))..'effects'
local eff_files = love.filesystem.getDirectoryItems(eff_path)

for i_e, effect in pairs(eff_files) do
	--EffectManager.load(eff_path..'/'..effect)
end

-- prevents updating while window is being moved (would mess up collisions)
local max_fps = 120
local min_dt = 1/max_fps
local next_time = love.timer.getTime()

BlankE = {
	_is_init = false,
	_ide_mode = false,
	show_grid = true,
	snap = {32, 32},
	grid_color = {255,255,255},
	_offx = 0,
	_offy = 0,
	_stencil_offset = 0,
	_mouse_x = 0,
	_mouse_y = 0,
	_callbacks_replaced = false,
	old_love = {},
	pause = false,
	first_state = '_empty_state',
	init = function(first_state, ide_mode)
		BlankE._ide_mode = ifndef(ide_mode, BlankE._ide_mode)

		if not BlankE._callbacks_replaced then
			BlankE._callbacks_replaced = true

			if not BlankE._ide_mode then
				BlankE.injectCallbacks()
			end
		end
	    uuid.randomseed(love.timer.getTime()*10000)
	    
		-- register State events
		--StateManager.injectCallbacks()
	    updateGlobals(0)

	    -- figure out the first state to run
	    if BlankE.first_state and not first_state then
	    	first_state = BlankE.first_state
	    end
		if first_state == nil or first_state == '' then
			first_state = _empty_state
		end
		if type(first_state) == 'string' then
			first_state = _G[first_state]
		end
		State.switch(first_state)
		BlankE._is_init = true
	end,

	injectCallbacks = function()
		BlankE.old_love = {}
		for fn_name, func in pairs(BlankE) do
			if type(func) == 'function' and fn_name ~= 'init' then
				-- save old love function
				BlankE.old_love[fn_name] = love[fn_name]
				-- inject BlankE callback
				love[fn_name] = function(...)
					if BlankE.old_love[fn_name] then BlankE.old_love[fn_name](...) end			
					return func(...)
				end
			end
		end
	end,

	restoreCallbacks = function()
		for fn_name, func in pairs(BlankE.old_love) do
			love[fn_name] = func
		end
	end,

	addClassType = function(in_name, in_type)
		if not _G[in_name] then
			if in_type == 'State' then
				local new_state = Class{__includes=State,
					classname=in_name,
					auto_update = false,
					_loaded = false,
					_off = true
				}
				_G[in_name] = new_state
			end

			if in_type == 'Entity' then			
				_G[in_name] = Class{__includes=Entity,classname=in_name}
			end
		end
	end,

	restart = function()
		-- restart game I guess?
	end,

	reloadAssets = function()
		require 'assets'
	end,

	getCurrentState = function()
		local state = State.current()
		if type(state) == "string" then
			return state
		end
		if type(state) == "table" then
			return state.classname
		end
		return state
	end,

	clearObjects = function(include_persistent)
		local new_game_array = {}
		for key, objects in pairs(game) do
			for o, obj in ipairs(objects) do
				if include_persistent or not obj.persistent then
					--if obj.classname then print('destroy '..obj.classname) end
					obj:destroy()
					game[key][o] = nil
				else
					new_game_array[key] = ifndef(new_game_array[key], {})
					table.insert(new_game_array[key], obj)
				end
			end
		end
		game = new_game_array
	end,

	main_cam = nil,
	snap = {32,32},
	initial_cam_pos = {0,0},

	_gridStencilFunction = function()
		local conf_w, conf_h = CONF.window.width, CONF.window.height --game_width, game_height

		local rect_x = (game_width/2)-(conf_w/2)
		local rect_y = (game_height/2)-(conf_h/2)

		local g_x, g_y
		if BlankE.main_cam and not BlankE.main_cam.disabled then
			g_x, g_y = BlankE.main_cam:position()
		else
			g_x, g_y = 0, 0
		end

	   	love.graphics.rectangle("fill",
	   		rect_x+g_x-(game_width/2)+BlankE._stencil_offset,
	   		rect_y+g_y-(game_height/2)+BlankE._stencil_offset,
	   		conf_w+BlankE._stencil_offset,
	   		conf_h+BlankE._stencil_offset
	   	)
	end,

	_gridStencilLine = function(func)	
		local grid_color = BlankE.grid_color

		-- outside view line
		love.graphics.push('all')
		love.graphics.setColor(grid_color[1], grid_color[2], grid_color[3], 15)
		
		func()

		-- in-view lines
		for o = 0,2,1 do
			BlankE._stencil_offset = -o

    		love.graphics.setColor(grid_color[1], grid_color[2], grid_color[3], 1)
    		love.graphics.stencil(BlankE._gridStencilFunction, "replace", 1)
		 	love.graphics.setStencilTest("greater", 0)
		 	func()
    		love.graphics.setStencilTest()
		end
		love.graphics.pop()
	end,

	_getSnap = function() 
		local zoom_amt = 1
		local snap = ifndef(BlankE.snap, {32,32})
		snap[1] = snap[1] * zoom_amt
		snap[2] = snap[2] * zoom_amt
		return snap
	end,

	_drawGrid = function()
		if not (BlankE.show_grid and BlankE._ide_mode) then return BlankE end

		local grid_color = BlankE.grid_color

		local min_grid_draw = 8
		local snap = BlankE._getSnap()
		local offx = BlankE._offx
		local offy = BlankE._offy

		love.graphics.push('all')
		love.graphics.setLineStyle("rough")
		--love.graphics.setBlendMode('replace')

		-- draw origin
		love.graphics.setLineWidth(3)
		love.graphics.setColor(grid_color[1], grid_color[2], grid_color[3], 15)
		love.graphics.line(0,-offy-(game_height/2)-snap[1],0,game_height) -- vert
		love.graphics.line(-offx-(game_width/2)-snap[2],0,game_width,0)  -- horiz			
		love.graphics.setLineWidth(1)

		local x_arg2 = (-game_height/2)-offy
		local x_arg4 = game_height-offy

		-- vertical lines
		if snap[1] >= min_grid_draw then
			local half_width = -game_width/2
			for x = half_width,game_width,snap[1] do
				love.graphics.line(x-offx, x_arg2, x-offx, x_arg4)
			end
		end

		local y_arg1 = (-game_width/2)-offx
		local y_arg3 = game_width-offx

		-- horizontal lines
		if snap[2] >= min_grid_draw then
			local half_height = -game_height/2
			for y = half_height,game_height,snap[2] do
				love.graphics.line(y_arg1, y-offy, y_arg3, y-offy)
			end
		end
		love.graphics.pop()

		return BlankE
	end,

	setGridSnap = function(snapx, snapy)
		BlankE.snap = {snapx, snapy}
	end,

	setGridCamera = function(camera)
		BlankE.main_cam = camera
		BlankE.initial_cam_pos = camera:position()
	end,

	updateGridColor = function()
		-- make grid color inverse of background color
		local r,g,b,a = love.graphics.getBackgroundColor()
	    r = 255 - r; g = 255 - g; b = 255 - b;
		BlankE.grid_color = {r,g,b}		
	end,

	update = function(dt)
	    dt = math.min(dt, min_dt)
	    next_time = next_time + min_dt

	    BlankE.updateGridColor()

		-- calculate grid offset
		local snap = BlankE._getSnap()

		local g_x, g_y
		if BlankE.main_cam and not BlankE.main_cam.disabled then
			g_x, g_y = BlankE.main_cam:position()
		else
			g_x, g_y = 0, 0
		end

		local scr_w = game_width
		local scr_h = game_height
		if BlankE.main_cam then
			scr_w = BlankE.main_cam.port_width
			scr_h = BlankE.main_cam.port_height
		end
		if scr_w ~= nil and scr_h ~= nil then
			BlankE._offx = -(g_x-(g_x%snap[1]))-(scr_w/2%snap[1]) + snap[1]
			BlankE._offy = -(g_y-(g_y%snap[2]))-(scr_h/2%snap[2]) + snap[2]
		end

	    updateGlobals(dt)
	    
	    if not BlankE._is_init then return end
	    Net.update(dt, false)
				
    	if not BlankE.pause then
			StateManager.iterateStateStack('update', dt)
			
		    for i_arr, arr in pairs(game) do
		        for i_e, e in ipairs(arr) do
		            if e.auto_update and not e.pause then
		                if e._update then
		                	e:_update(dt)
		                else
			                e:update(dt)
			            end
		            end
		        end
		    end
		end

		if BlankE.main_cam and BlankE.pause then
			BlankE.main_cam:update()
		end
	end,

	draw = function()
		StateManager.iterateStateStack('draw')

        -- disable any scenes that aren't being actively drawn
        local active_scenes = 0
		_iterateGameGroup('scene', function(scene)
			if scene._is_active > 0 then 
				active_scenes = active_scenes + 1
				scene._is_active = scene._is_active - 1
			end
		end)
		
		if BlankE._ide_mode and active_scenes > 0 and BlankE.getCurrentState() ~= '_empty_state' then
			if BlankE.main_cam then BlankE.main_cam:attach() end
			BlankE._gridStencilLine(BlankE._drawGrid)
			if BlankE.main_cam then BlankE.main_cam:detach() end
		end

	    local cur_time = love.timer.getTime()
	    if next_time <= cur_time then
	        next_time = cur_time
	        return
	    end
	    love.timer.sleep(next_time - cur_time)
	end,

	resize = function(w,h)
		_iterateGameGroup("effect", function(effect)
			effect:resizeCanvas(w, h)
		end)
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

	wheelmoved = function(x, y)
	    _iterateGameGroup("input", function(input)
	        input:wheelmoved(x, y)
	    end)		
	end,

	quit = function()
	    Net.disconnect()
	    State.switch()
	    BlankE.clearObjects(true)
	    HC.resetHash()
	    BlankE.restoreCallbacks()

	    -- remove globals
	    local globals = {}--'BlankE'}
	    for g, global in ipairs(globals) do
	    	if _G[global] then _G[global] = nil end
	    end
	end,

	errhand = function(msg)
		IDE.errd = true; 
		local trace = debug.traceback()
	 
	    local err = {} 
	 
	    table.insert(err, "Error\n")
	    table.insert(err, msg.."\n\n")
	 
	    for l in string.gmatch(trace, "(.-)\n") do
	        if not string.match(l, "boot.lua") then
	            l = string.gsub(l, "stack traceback:", "Traceback\n")
	            table.insert(err, l)
	        end
	    end
	 
	    local p = table.concat(err, "\n")
	 
	    p = string.gsub(p, "\t", "")
	    msg = string.gsub(p, "%[string \"(.-)\"%]", "%1")

		BlankE.clearObjects(true)
		_err_state.error_msg = msg
		State.switch(_err_state)
	end,
}

BlankE.addClassType('_err_state', 'State')
_err_state.error_msg = 'NO GAME'

local _t = 0
function _err_state:draw()
	love.graphics.setBackgroundColor(0,0,0,255)
	BlankE.updateGridColor()
	game_width = love.graphics.getWidth()
	game_height = love.graphics.getHeight()
	
	local max_size = math.max(game_width, game_height, 500)

	_t = _t + 1
	if _t >= max_size then _t = 0 end -- don't let _t iterate into infinity


	love.graphics.push('all')

	for i = -max_size, max_size, 10 do
		local radius = max_size - _t + i
		if radius > 20 and radius < max_size then
			local opacity = (radius / max_size) * (255*0.6)
			love.graphics.setColor(0,255,0,opacity)
			love.graphics.circle("line", game_width/2, game_height/2, radius)
		end
	end

	-- draw error message
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

	love.graphics.pop('all')
end	

BlankE.addClassType('_empty_state', 'State')

-- Called once, and only once, before entering the state the first time.
function _empty_state:init() end
function _empty_state:leave() end 

-- Called every time when entering the state.
function _empty_state:enter(previous)

end

function _empty_state:update(dt)

end

local _offset=0
function _empty_state:draw()
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
	love.graphics.setColor(255,255,255,sinusoidal(150,255,0.5))
	love.graphics.printf("NO GAME",0,game_height/2,game_width,"center")
	love.graphics.pop()
end	

return BlankE