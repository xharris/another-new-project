entity0 = Class{__includes=Entity,classname='entity0'}


function entity0:init()
	Entity.init(self, 'entity0')
	
	self:addAnimation{
		name = 'stand',
		image = 'player_stand'
	}

	self:addShape(
		"main",
		"rectangle",
		{0,0,21,32}
	)

	self.sprite_index = 'stand'
end

function entity0:postUpdate(dt)

end	

function entity0:postDraw()

end
               