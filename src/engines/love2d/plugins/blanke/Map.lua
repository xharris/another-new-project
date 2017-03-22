local assets = require "assets"

Map = Class{
	init = function (self, map_name)
		self.name = map_name
		self.data = require(map_name)

		-- extra drawing properties
		self.color = {['r']=255,['g']=255,['b']=255}

		self._images = {}
		self._batches = {}

		self.tilesets = {} 		-- {firstgid = tileset}
		self.tilelayers = {}	-- {name = layer}
		self.objectgroups = {}	-- {name = layer}
		self.entities = {}

		self._layers = {} 	-- for draw order

		-- load tilesets
		for t, tileset in pairs(self.data.tilesets) do
			-- resize tilesets that don't cover the entire image
			tileset.cutwidth = tileset.imagewidth - (tileset.imagewidth % tileset.tilewidth)
			tileset.cutheight = tileset.imageheight - (tileset.imageheight % tileset.tileheight)

			self.tilesets[tileset.firstgid] = tileset

			self._images[tileset.name] = assets[tileset.name]()
		end

		-- load tile/object layers
		for l, layer in pairs(self.data.layers) do
			local new_layer = {
				name = layer.name,
				type = layer.type
			}
			table.insert(self._layers, new_layer)

			-- TILE LAYER
			if layer.type == "tilelayer" then
				self.tilelayers[layer.name] = layer
				self._batches[layer.name] = {}

				for i_d, d in ipairs(layer.data) do
					if d > 0 then
						-- get tileset that covers this gid
						local tileset
						for gid, _tileset in pairs(self.tilesets) do
							if d >= gid then
								tileset = _tileset
							end
						end

						-- is there a spritebatch for this tileset/layer combo?
						if not self._batches[layer.name][tileset.name] then
							self._batches[layer.name][tileset.name] = love.graphics.newSpriteBatch(self._images[tileset.name])
						end

						-- get tile x/y
						local tile_x = i_d % layer.width * self.data.tilewidth - self.data.tilewidth -- offset, who knows why
						local tile_y = math.floor(i_d / layer.width) * self.data.tileheight

						-- get tile frame x/y
						local frame = d - tileset.firstgid
						local columns = tileset.cutwidth / tileset.tilewidth

						local frame_x = frame % columns * tileset.tilewidth
						local frame_y = math.floor(frame / columns) * tileset.tileheight

						print(d .. " -> " .. frame .. " - " .. frame_x .. ", " .. frame_y .. " (" .. tile_x .. ", " .. tile_y .. ") " .. tileset.name)

						-- offset for tileset smaller than grid
						local offx = 0--(tileset.tilewidth < self.data.tilewidth) and self.data.tilewidth - tileset.tilewidth or 0
						local offy = (tileset.tileheight < self.data.tileheight) and self.data.tileheight - tileset.tileheight or 0

						local quad = love.graphics.newQuad(frame_x, frame_y, tileset.tilewidth, tileset.tileheight, tileset.imagewidth, tileset.imageheight)
						self._batches[layer.name][tileset.name]:add(quad, tile_x + offx, tile_y + offy, 0, 1, 1, tileset.tileoffset.y, tileset.tileoffset.x) -- yes offsetx and y are switched
					end
				end
			end

			-- OBJECT LAYER
			if layer.type == "objectgroup" then
				self.objectgroups[layer.name] = layer

				-- ENTITIES: does not spawn the entity, just stores its data
				if layer.name == "entity" then
					for i_o, object in ipairs(layer.objects) do
						if not self.entities[object.type] then
							self.entities[object.type] = {}
						end

						table.insert(self.entities[object.type], object)
					end
				end

				-- COLLISIONS
				if layer.name == "collision" then
					for i_o, object in ipairs(layer.objects) do

					end
				end
			end
		end
	end,

	getEntity = function (self, type, name) 
		-- only type is given
		if not name then
			return self.entities[type]
		end

		-- return entity with certain type & name
		for i_e, entity in ipairs(self.entities[type]) do
			if entity.name == name then
				return entity
			end
		end
	end,

	update = function (self, dt)

	end,

	draw = function (self)
		for i_l, _layer in ipairs(self._layers) do
			-- TILELAYER
			if _layer.type == "tilelayer" then
				local layer = self.tilelayers[_layer.name]
				local layer_batches = self._batches[_layer.name]

				for tileset_name, batch in pairs(layer_batches) do
					if layer.visible then
						love.graphics.push()

						love.graphics.translate(layer.offsetx, layer.offsety)
						love.graphics.setColor(self.color.r, self.color.g, self.color.b, layer.opacity*255)

						love.graphics.draw(batch, 0, 0)
						love.graphics.pop()
					end
				end
			end

			-- OBJECTGROUP
			if _layer.type == "objectgroup" then
				-- COLLISION BOXES
				if _layer.name == "collision" then
					-- debug drawing only (add later)
				end
			end
		end
	end,
}

return Map