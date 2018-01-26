BlankE.addClassType("Ground", "Entity")


function Ground:init()
	self:addShape("ground", "rectangle", {32, 32, 32, 32}, "ground")
end

function Ground:update(dt)

end
