local _btn_place
local _last_place = {0,0}
local _snap = {32,32}
local _place_type
local _place_obj

Scene = Class{
	init = function(self, name)
		self.load_objects = {}
		self.layers = {}
		self.images = {}
		self.name = name

		if BlankE._ide_mode then
			_btn_place = Input('mouse.1')
			self._fake_view = View()
			self._fake_view:moveToPosition(game_width/2, game_height/2)
		end

		if name and assets[name] then
			self:load(assets[name]())
		end

		self.draw_hitboxes = false
		_addGameObject('scene',self)
	end,

	-- returns json
	export = function(self)
		local template = {
			object=self.load_objects,
			layer=self.layers
		}
		print(encode(template))
	end,

	load = function(self, path, compressed)
		scene_string = love.filesystem.read(path)
		scene_data = json.decode(scene_string)

		self.load_objects = scene_data["object"]

		--[[
			image -> tile
			rect -> entity
			polygon -> hitbox
		]]
		for layer, data in pairs(scene_data["layer"]) do
			self.layers[layer] = {entity={},tile={},hitbox={}}

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

	_addEntityStr = function(self, ent_name, x, y, layer, width, height)
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
					entity:update(dt)
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
				local mx, my = mouse_x, mouse_y
				return {mx-(mx%_snap[1]), my-(my%_snap[2])}
			end

			if CONF then
				print('doin it')
	    		love.graphics.push('all')
	    		love.graphics.setColor(UI.getColor('love2d'))
	    		print(CONF.window.width, CONF.window.height)
	    		love.graphics.rectangle('line',1,1,CONF.window.width,CONF.window.height)--self.port_x+1,self.port_y+2,self.port_width-2,self.port_height-2)
	    		love.graphics.pop()
	    	end

	    	self._fake_view:attach()
	    	love.graphics.push('all')
	    	love.graphics.setLineWidth(1)
	    	love.graphics.setLineStyle("rough")
	    	love.graphics.setColor(255,255,255,40)

	    	-- vertical lines
	    	local g_x = 0--self._fake_view.port_x
	    	local g_y = 0--self._fake_view.port_y
	    	local g_width = self._fake_view.port_width
	    	local g_height = self._fake_view.port_height
	    	for x = g_x,g_width,_snap[1] do
	    		love.graphics.line(x, g_y, x, g_height)
	    	end
	    	for y = g_y,g_height,_snap[2] do
	    		love.graphics.line(g_x, y,g_width, y)
	    	end
	    	love.graphics.pop()

	    	local _placeXY = _getMouseXY()
	    	BlankE._mouse_x, BlankE._mouse_y = unpack(_placeXY)
	    	if _btn_place() then
	    		if _placeXY[1] ~= _last_place[1] or _placeXY[2] ~= _last_place[2] then
	    			_last_place = _placeXY

	    			if _place_type == 'entity' then
	    				self:addEntity(_place_obj, _placeXY[1], _placeXY[2])--,0,0,0)
	    			end
	    		end
	    	end

	    	self:_real_draw()
	    	self._fake_view:detach()
	    else
	    	self:_real_draw()
	    end
	end,

	setPlacer = function(self, type, obj)
		_place_type = type
		_place_obj = obj
	end,
}

return Scene