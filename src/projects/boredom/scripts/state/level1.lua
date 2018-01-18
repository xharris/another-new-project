BlankE.addClassType("level1", "State")
local main_scene

function level1:enter(previous)
	Draw.setBackgroundColor(Draw.white2)
	main_scene = Scene("level1")

	main_effect = Effect("chroma shift")
end

function level1:update(dt) 
end

function level1:draw()
	--main_effect:send('center', {mouse_x, mouse_y})

	main_effect:draw(function()
		main_scene:draw()
	end)
	Debug.draw()
end	
