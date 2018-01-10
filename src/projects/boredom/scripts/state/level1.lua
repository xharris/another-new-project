BlankE.addClassType("level1", "State")
local main_scene

function level1:enter(previous)
	Draw.setBackgroundColor(Draw.white2)
	main_scene = Scene("level1")

	my_effect = Effect("zoom_blur")
end

function level1:update(dt)
	my_effect:send("center", {mouse_x, mouse_y})
end

function level1:draw()
	my_effect:draw(function()
		main_scene:draw()
	end)
	Debug.draw()
end	
