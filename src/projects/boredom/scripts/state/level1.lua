-- other functions: load(), leave()

-- Called every time when entering the state.
local main_scene
function level1:enter(previous)
	main_scene = Scene("level1")
end

function level1:update(dt)

end

function level1:draw()
	--main_scene:draw()
end	
