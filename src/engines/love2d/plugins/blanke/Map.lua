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
						for gid, _tileset in ipairs(self.tilesets) do
							if d >= gid then
								tileset = _tileset
							end
						end

						-- is there a spritebatch for this tileset/layer combo?
						if not self._batches[layer.name][tileset.name] then
							self._batches[layer.name][tileset.name] = love.graphics.newSpriteBatch(self._images[tileset.name])
						end

						-- get tile x/y
						i_d = i_d - 1
						local tile_x = i_d % layer.width * tileset.tileheight
						local tile_y = math.floor(i_d / layer.width) * tileset.tilewidth

						-- get tile frame x/y
						local frame = d - tileset.firstgid
						local columns = tileset.imagewidth / tileset.tilewidth

						local frame_x = frame % columns * tileset.tileheight
						local frame_y = math.floor(frame / columns) * tileset.tilewidth

						local quad = love.graphics.newQuad(frame_x, frame_y, tileset.tilewidth, tileset.tileheight, tileset.imagewidth, tileset.imageheight)
						self._batches[layer.name][tileset.name]:add(quad, tile_x, tile_y, 0, 1, 1, 0, 0)
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