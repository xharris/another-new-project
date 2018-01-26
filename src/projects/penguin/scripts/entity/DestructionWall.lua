BlankE.addClassType("DestructionWall", "Entity")


function DestructionWall:init()
	self.hspeed = 1
end

function DestructionWall:update(dt)

end

function DestructionWall:draw()
	Draw.setColor('black')
	Draw.line(self.x, main_view.y, self.x, main_view.height)
end