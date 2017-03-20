local assets = require "assets"

Map = Class{
	init = function (self, map_name)
		self.name = map_name
		self.data = require(map_name)
	end,

	update = function (self)

	end,

	draw = function (self)

	end,
}

return Map