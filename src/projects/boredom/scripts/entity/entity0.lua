function entity0:init()
	Entity.init(self, 'entity0')
	
	self:addAnimation{
		name = 'stand',
		image = 'player_stand'
	}

	self.sprite_index = 'stand'
end

function entity0:postUpdate(dt)

end	

function entity0:postDraw()

end
