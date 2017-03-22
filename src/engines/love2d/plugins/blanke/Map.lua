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

		-- load tilesets
		for t, tileset in pairs(self.data.tilesets) do
			-- resize tilesets that don't cover the entire image
			tileset.cutwidth = tileset.imagewidth - (tileset.imagewidth % tileset.tilewidth)
			tileset.cutheight = tileset.imageheight - (tileset.imageheight % tileset.tileheight)

			print (tileset.name .. " [" .. tileset.cutwidth .. ", " .. tileset.cutheight .. "]")

			self.tilesets[tileset.firstgid] = tileset

			self._images[tileset.name] = assets[tileset.name]()
		end

		-- load tile/object layers
		for l, layer in pairs(self.data.layers) do
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
			end
		end
	end,

	update = function (self)

	end,

	draw = function (self)
		for l_name, layer_batches in pairs(self._batches) do
			local layer = self.tilelayers[l_name]

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
	end,
}

return Map