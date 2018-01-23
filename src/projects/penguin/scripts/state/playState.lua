BlankE.addClassType("playState", "State")

local k_join
local main_view

-- Called every time when entering the state.
function playState:enter(previous)
	Draw.setBackgroundColor('white2')

	test_scene = Scene('test')
	main_view = View()
	k_join = Input('j')
end

function playState:update(dt)
	if k_join() and not Net.is_connected then
		Net.join()
		-- add player's penguin
		new_penguin = Penguin()
		test_scene:addEntity(new_penguin)
		Net.addEntity(new_penguin)
		-- create camera
		main_view:follow(new_penguin)
	end
end

function playState:draw()
	Net.draw()
	main_view:draw(function()
		test_scene:draw()
	end)
	Debug.draw()
end	
