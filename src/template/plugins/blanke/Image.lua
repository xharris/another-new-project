local _images = {}
 
Image = Class{
	init = function(self, name)
		if type(name) == "string" and assets[name] then
			self.image = assets[name]()
		else
			self.image = love.graphics.newImage(name)
		end

		self.x = 0
		self.y = 0
		self.angle = 0
		self.xscale = 1
		self.yscale = 1
		self.xoffset = 0
		self.yoffset = 0
		self.color = {['r']=255,['g']=255,['b']=255}
		self.alpha = 255

		self.orig_width = self.image:getWidth()
		self.orig_height = self.image:getHeight()
		self.width = self.orig_width
		self.height = self.orig_height
	end,

	-- static: check if an image exists
	exists = function(img_name)
		return (assets[img_name] ~= nil)
	end,

	setWidth = function(self, width)
		self.xscale = width / self.orig_width
		return self
	end,

	setHeight = function(self, height)
		self.yscale = height / self.orig_height
		return self
	end,

	draw = function(self)
		self.width = self.orig_width * self.xscale
		self.height = self.orig_height * self.yscale

		love.graphics.push()
		love.graphics.setColor(self.color.r, self.color.g, self.color.b, self.alpha)	
		love.graphics.draw(self.image, self.x, self.y, math.rad(self.angle), self.xscale, self.yscale, self.xoffset, self.yoffset, self.xshear, self.yshear)
		love.graphics.pop()
		return self
	end,

    __call = function(self)
    	return self.image
	end,

	-- break up image into pieces
	chop = function(self, piece_w, piece_h)

	end,

	crop = function(self, x, y, w, h)
		-- draw quad to canvas (TODO: any hits to performance?)
		local img_canvas = love.graphics.newCanvas(w, h)
		img_canvas:renderTo(function()
			love.graphics.draw(self.image, -x , -y)
		end)

		-- convert canvas to image
		return Image(img_canvas:newImageData())
	end,
}

return Image