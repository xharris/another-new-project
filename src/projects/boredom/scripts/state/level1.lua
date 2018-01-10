BlankE.addClassType("level1", "State")
local main_scene

function level1:enter(previous)
	Draw.setBackgroundColor(Draw.white2)
	main_scene = Scene("level1")
end

function level1:update(dt)
	
end

function level1:draw()
	main_scene:draw()
	Debug.draw()
end	
