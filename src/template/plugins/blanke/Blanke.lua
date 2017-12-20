local blanke_path = (...):match("(.-)[^%.]+$")
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

    if obj.update then obj.auto_update = true end

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

State 	= blanke_require('State')	-- hump.gamestate
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
	EffectManager.load(eff_path..'/'..effect)
end

-- prevents updating while window is being moved (would mess up collisions)
local max_fps = 120
local min_dt = 1/max_fps
local next_time = love.timer.getTime()

_err_state = Class{classname='_err_state',error_msg='NO GAME'}

BlankE = {
	_ide_mode = false,
	show_grid = true,
	grid_color = {255,255,255},
	_offx = 0,
	_offy = 0,
	_stencil_offset = 0,
	_mouse_x = 0,
	_mouse_y = 0,
	_callbacks_replaced = false,
	pause = false,
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
	    		State.registerEvents({'update'})
	    	else
	    		State.registerEvents()
	    	end
		end
	    uuid.randomseed(love.timer.getTime()*10000)
	    
		-- register States
	    updateGlobals(0)
		if first_state then
			if first_state == nil or first_state == '' then
				first_state = _empty_state
			end
			if type(first_state) == 'string' then
				first_state = _G[first_state]
			end
			State.switch(first_state)
		end

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
		for key, objects in pairs(game) do
			for o, obj in ipairs(objects) do
				if include_persistent or not obj.persistent then
					obj:destroy()
				end
			end
		end
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

	update = function(dt)
	    dt = math.min(dt, min_dt)
	    next_time = next_time + min_dt

		-- make grid color inverse of background color
		local r,g,b,a = love.graphics.getBackgroundColor()
	    r = 255 - r; g = 255 - g; b = 255 - b;
		BlankE.grid_color = {r,g,b}

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

		BlankE._offx = -(g_x-(g_x%snap[1]))-(scr_w/2%snap[1]) + snap[1]
		BlankE._offy = -(g_y-(g_y%snap[2]))-(scr_h/2%snap[2]) + snap[2]

	    updateGlobals(dt)
	    
	    Net.update(dt, false)

    	if not BlankE.pause then 
		    for i_arr, arr in pairs(game) do
		        for i_e, e in ipairs(arr) do
		            if e.auto_update and not e.pause then
		                e:update(dt)
		            end
		        end
		    end
		end

		if BlankE.main_cam and BlankE.pause then
			BlankE.main_cam:update()
		end
	end,

	draw = function()
		local fake_view = nil
		_iterateGameGroup('scene', function(scene)
			scene._is_active = false
		end)
		
		if BlankE._ide_mode and #game.scene > 0  and BlankE.getCurrentState() ~= '_empty_state' then
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
	    BlankE.clearObjects(true)
	end,

	errhand = function(msg)
		BlankE.clearObjects(true)
		_err_state.error_msg = msg
		_err_state.draw()
	end,
}

local _offset=0
function _err_state:draw()
	love.graphics.setBackgroundColor(0,0,0,255)

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

