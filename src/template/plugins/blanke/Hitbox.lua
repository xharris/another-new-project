Hitbox = Class{
	init = function(self, shape, args, tag, xoffset, yoffset)
		xoffset = ifndef(xoffset, 0)
		yoffset = ifndef(yoffset, 0)

		self.HCShape = nil
		if shape == "rectangle" then
			args[1] = args[1] + xoffset
			args[2] = args[2] + yoffset
			self.HCShape = HC.rectangle(unpack(args))
		elseif shape == "polygon" then
			for a = 1, #args, 2 do
				args[a] = args[a] + xoffset
				args[a+1] = args[a+1] + yoffset
			end
			self.HCShape = HC.polygon(unpack(args))
		elseif shape == "circle" then
			args[1] = args[1] + xoffset
			args[2] = args[2] + yoffset
			self.HCShape = HC.circle(unpack(args))
		elseif shape == "point" then
			args[1] = args[1] + xoffset
			args[2] = args[2] + yoffset
			self.HCShape = HC.point(unpack(args))
		end

		self.HCShape.xoffset = 0--xoffset
		self.HCShape.yoffset = 0--yoffset
		if shape ~= "polygon" then
			self.HCShape.xoffset = (args[1] - xoffset) / 2
			self.HCShape.yoffset = (args[2] - yoffset) / 2
		end

		self.HCShape.tag = tag

		self._enabled = true
		self.color = {255,0,0,255*(.5)}
		self.parent = nil
		self.args = args
		--HC.register(self.HCShape)
		--HC:register(self.HCShape, self.HCShape:bbox())
	end,

	draw = function(self, mode)
		love.graphics.push("all")
			love.graphics.setColor(self.color)
			self.HCShape:draw(ifndef(mode, 'fill'))
		love.graphics.pop()
	end,

	setTag = function(self, new_tag)
		self.HCShape.tag = new_tag
	end,

	getTag = function(self)
		return self.HCShape.tag
	end,

	getHCShape = function(self)
		return self.HCShape
	end,

	move = function(self, x, y)
		self.HCShape:move(x, y)
	end,

	moveTo = function(self, x, y)
		self.HCShape:moveTo(x+self.HCShape.xoffset, y+self.HCShape.yoffset)
	end,

	center = function(self)
		return self.HCShape:center()
	end,	

	pointTest = function(self, x, y)
		return self.HCShape:contains(x,y)
	end,

	enable = function(self)
		if not self._enabled then
			self._enabled = true
			HC.register(self.HCShape)
		end
	end,

	disable = function(self)
		if self._enabled then
			self._enabled = false
			HC.remove(self.HCShape)
		end
	end,

	destroy = function(self)
		self:disable()
		_destroyGameObject('hitbox',self)
    	self = nil
	end,

	setColor = function(self, new_color)
		if type(new_color) == "string" then
			self.color = hex2rgb(new_color)
		else
			self.color = new_color
		end
		self.color[4] = 255/3
	end,

	setParent = function(self, parent)
		self.parent = parent
	end
}

return Hitbox