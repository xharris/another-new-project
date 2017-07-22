local _btn_place
local _btn_drag
local _last_place = {nil,nil}
local _snap = {32,32}
local _place_type
local _place_obj

local _dragging = false
local _view_initial_pos = {0,0}
local _initial_mouse_pos = {0,0}


Scene = Class{
	init = function(self, name)
		self.load_objects = {}
		self.layers = {}
		self.images = {}
		self.name = name

		if BlankE._ide_mode then
			_btn_place = Input('mouse.1')
			_btn_drag = Input('mouse.3')
			self._fake_view = View()
			self._fake_view.port_width, self._fake_view.port_height = love.window.getDesktopDimensions()
			self._fake_view:moveToPosition(self._fake_view.port_width/2,self._fake_view.port_height/2)
			self._fake_view.motion_type = 'smooth' -- (not working as intended)
		end

		if name and assets[name] then
			self:load(assets[name]())
		end

		self.draw_hitboxes = false
		_addGameObject('scene',self)
	end,

	-- returns json
	export = function(self, path)
		local output = {layers={},load_objects={}}

		for layer, data in pairs(self.layers) do
			output.layers[layer] = {}

			for obj_type, objects in pairs(data) do
				local out_layer = {}
				for o, obj in ipairs(objects) do
					if obj_type == 'entity' and obj._loadedFromFile then
						local ent_data = {
							classname=obj.classname,
							x=obj.x,
							y=obj.y
						}
						table.insert(out_layer, ent_data)
					end

					if obj_type == 'image' then
						local img_data = {

						}
						table.insert(out_layer, img_data)
					end
				end
				output.layers[layer][obj_type] = out_layer
			end
		end

		return json.encode(output)
	end,

	load = function(self, path, compressed)
		scene_string = love.filesystem.read(path)
		scene_data = json.decode(scene_string)

		self.load_objects = scene_data["object"]

		for layer, data in pairs(scene_data["layers"]) do
			self.layers[layer] = {entity={},tile={},hitbox={}}

			if data["entity"] then
				for i_e, entity in ipairs(data["entity"]) do
					Entity.x = entity.x
					Entity.y = entity.y
					local new_entity = _G[entity.classname](entity.x, entity.y)
					new_entity._loadedFromFile = true
					Entity.x = 0
					Entity.y = 0

					self:addEntity(new_entity, layer)
				end
			end

			if data["rect"] then
				for i_r, rect in ipairs(data["rect"]) do
					local uuid = rect.uuid
					local rect_obj = self.load_objects[uuid]

					self:addEntity(rect_obj.name, rect.x, rect.y, layer, rect_obj.width, rect_obj.height)
				end
			end

			if data["image"] then
				for i_i, image in ipairs(data["image"]) do
					local uuid = image.uuid
					local image_obj = self.load_objects[uuid]

					self:addTile(image_obj.name, image.x, image.y, image.crop, layer)
				end
			end

			if data["polygon"] then
				for i_h, hitbox in ipairs(data["polygon"]) do
					local uuid = hitbox.uuid
					local hitbox_obj = self.load_objects[uuid]

					-- turn points into array
					hitbox.points = hitbox.points:split(',')

					self:addHitbox(hitbox_obj.name, hitbox, layer)
				end
			end
		end
	end,

	_checkLayerArg = function(self, layer)
		if layer == nil then
			return self:_checkLayerArg(0)
		end
		if type(layer) == "number" then
			layer = "layer"..tostring(layer)
			self.layers[layer] = ifndef(self.layers[layer],{})
		end
		return layer
	end,

	getList = function(self, obj_type) 
		local obj_list = {}
		for layer, data in pairs(self.layers) do
			obj_list[layer] = data[obj_type]
		end
		return obj_list
	end,

	addEntity = function(self, ...)
		local args = {...}
		if type(args[1]) == "string" then
			self:_addEntityStr(unpack(args))
		end
		if type(args[1]) == "table" then
			self:_addEntityTable(unpack(args))
		end
	end,

	_addEntityTable = function(self, entity, layer) 
		layer = self:_checkLayerArg(layer)
		self.layers[layer]["entity"] = ifndef(self.layers[layer]["entity"], {})
		table.insert(self.layers[layer].entity, entity)
	end,

	_addEntityStr = function(self, ent_name, x, y, layer, width, height, fromFile)
		Entity.x = x
		Entity.y = y
		local new_entity = _G[ent_name](x, y, width, height)
		Entity.x = 0
		Entity.y = 0
		--new_entity.x = x
		--new_entity.y = y
		self:_addEntityTable(new_entity, layer)

		return new_entity
	end,

	addTile = function(self, img_name, x, y, img_info, layer) 
		layer = self:_checkLayerArg(layer)

		-- check if the spritebatch exists yet
		self.layers[layer]["tile"] = ifndef(self.layers[layer]["tile"], {})
		self.images[img_name] = ifndef(self.images[img_name], Image(img_name))
		self.layers[layer].tile[img_name] = ifndef(self.layers[layer].tile[img_name], love.graphics.newSpriteBatch(self.images[img_name]()))

		-- add tile to batch
		local spritebatch = self.layers[layer].tile[img_name]
		return spritebatch:add(love.graphics.newQuad(img_info.x, img_info.y, img_info.width, img_info.height, self.images[img_name].height, self.images[img_name].width), x, y)
	end,

	addHitbox = function(self, hit_name, hit_info, layer) 
		layer = self:_checkLayerArg(layer)

		self.layers[layer]["hitbox"] = ifndef(self.layers[layer]["hitbox"], {})
		local new_hitbox = Hitbox("polygon", hit_info.points, hit_name)
		new_hitbox:setColor(hit_info.color)
		table.insert(self.layers[layer].hitbox, new_hitbox)
	end,

	getEntity = function(self, in_entity, in_layer)
		local entities = {}
		for name, layer in pairs(self.layers) do
			if in_layer == nil or in_layer == layer then
				for i_e, entity in ipairs(layer.entity) do
					if entity.classname == in_entity then
						table.insert(entities, entity)
					end
				end
			end
		end

		if #entities == 1 then
			return entities[1]
		end
			return entities
	end,

	update = function(self, dt) 
		-- update entities
		for name, layer in pairs(self.layers) do
			if layer.entity then
				for i_e, entity in ipairs(layer.entity) do
					if entity._destroyed then
						table.remove(layer.entity, i_e)
					else
						entity:update(dt)
					end
				end
			end

			if layer.hitbox then
				for i_h, hitbox in ipairs(layer.hitbox) do
					-- nothing at the moment
				end
			end
		end
	end,

	_real_draw = function(self)
		self._is_active = true
		for name, layer in pairs(self.layers) do
			if layer.entity then
				for i_e, entity in ipairs(layer.entity) do
					entity:draw()
				end
			end

			if layer.tile then
				for name, tile in pairs(layer.tile) do
					love.graphics.draw(tile)
				end
			end

			if layer.hitbox and self.draw_hitboxes then
				for i_h, hitbox in ipairs(layer.hitbox) do
					hitbox:draw()
				end
			end
		end
	end,

	draw = function(self) 
	    if BlankE._ide_mode then
			function _getMouseXY()
				local cam_x, cam_y
				if not self._fake_view.disabled then
					cam_x, cam_y = self._fake_view.camera:cameraCoords(self._fake_view:mousePosition())
					local cam_pos = {self._fake_view:position()}
					cam_x = cam_x - ((self._fake_view.port_width/2) - cam_pos[1])
					cam_y = cam_y - ((self._fake_view.port_height/2) - cam_pos[2])
				else
					cam_x, cam_y = mouse_x, mouse_y
				end
				local mx, my = cam_x, cam_y
				return {mx-(mx%_snap[1]), my-(my%_snap[2])}
			end

			function _drawGrid()
				love.graphics.push('all')
		    	love.graphics.setLineWidth(1)
		    	love.graphics.setLineStyle("rough")

		    	local g_x, g_y
		    	if not self._fake_view.disabled then
			    	g_x, g_y = self._fake_view:position()
			    	g_x = (self._fake_view.port_width/2) + g_x
			    	g_y = (self._fake_view.port_height/2) + g_y
			    else
			    	g_x, g_y = 0, 0
			    end

		    	local offx, offy = -(g_x%_snap[1]), -(g_y%_snap[2])

		    	local function myStencilFunction()
		    		local conf_w, conf_h = CONF.window.width, CONF.window.height

		    		local rect_x = (game_width/2)-(conf_w/2)
		    		local rect_y = (game_height/2)-(conf_h/2)

				   	love.graphics.rectangle("fill", rect_x, rect_y, conf_w, conf_h)
				end

				local function stencilLine(func)
					-- outside view line
		    		love.graphics.setColor(255,255,255,30)
	    			love.graphics.setLineWidth(1)
	    			func()

	    			-- bold in-view line
		    		love.graphics.setColor(255,255,255,40)
		    		love.graphics.stencil(myStencilFunction, "replace", 1)
				 	love.graphics.setStencilTest("greater", 0)
				 	love.graphics.setLineWidth(1)
				 	func()
		    		love.graphics.setStencilTest()
				end

		    	-- vertical lines
		    	for x = 0,game_width,_snap[1] do
		    		if x+offx == 0 then
						love.graphics.setLineWidth(3)
		    		else
		    			love.graphics.setLineWidth(1)
		    		end

		    		-- regular line
		    		stencilLine(function()
		    			love.graphics.line(x+offx, 0, x+offx, game_height)
		    		end)
		    	end
		    	-- horizontal lines
		    	for y = 0,game_height,_snap[2] do
		    		if y+offy == 0 then
		    			love.graphics.setLineWidth(3)
		    		else
		    			love.graphics.setLineWidth(1)
		    		end

		    		stencilLine(function()
		    			love.graphics.line(0, y+offy,game_width, y+offy)
		    		end)
		    	end
		    	love.graphics.pop()
			end

	    	_drawGrid()
	    	self._fake_view:attach()

	    	local _placeXY = _getMouseXY()
	    	BlankE._mouse_x, BlankE._mouse_y = unpack(_placeXY)
	    	if _btn_place() then
	    		if _placeXY[1] ~= _last_place[1] or _placeXY[2] ~= _last_place[2] then
	    			_last_place = _placeXY

	    			if _place_type == 'entity' then
	    				self:addEntity(_place_obj, _placeXY[1], _placeXY[2])
	    			end
	    		end
	    	end

	    	if not self._fake_view.disabled then
		    	if _btn_drag() then
		    		-- on down
			    	if not _dragging then
			    		_dragging = true
			    		_view_initial_pos = {self._fake_view:position()}
			    		_initial_mouse_pos = {mouse_x, mouse_y}
			    	end
			    	-- on hold
			    	if _dragging then
			    		local _drag_dist = {mouse_x-_initial_mouse_pos[1], mouse_y-_initial_mouse_pos[2]}
			    		self._fake_view:moveToPosition(
			    			_view_initial_pos[1] - _drag_dist[1],
			    			_view_initial_pos[2] - _drag_dist[2]
			    		)
			    	end
			    end
		    	-- on release
		    	if not _btn_drag() and _dragging then
		    		_dragging = false
		    	end
		    end

	    	self:_real_draw()
	    	self._fake_view:detach()
	    else
	    	self:_real_draw()
	    end
	end,

	focusEntity = function(self, ent)
		if self._fake_view then
			-- removing followed entity
			if ent == nil and self._fake_view.follow_entity then
				self._fake_view.follow_entity.show_debug = false
				self._fake_view.offset_x = 0
				self._fake_view.offset_y = 0
			end
			-- following entity
			if ent then
				-- TODO: offset not working as intended
				self._fake_view.offset_x = self._fake_view.port_width - game_width 
				self._fake_view.offset_y = self._fake_view.port_height - game_height
				ent.show_debug = true
			end

			self._fake_view:follow(ent)
		end
	end,

	setPlacer = function(self, type, obj)
		_place_type = type
		_place_obj = obj
	end,
}

return Scene