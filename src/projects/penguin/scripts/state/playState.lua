BlankE.addClassType("playState", "State")

local k_join
local main_view
wall_x = 0

-- Called every time when entering the state.
function playState:enter(previous)
	Draw.setBackgroundColor('white2')

	wall_x = 0
	test_scene = Scene('test')
	main_view = View()
	k_join = Input('j')
end

function Net:onReady()
	-- add player's penguin
	new_penguin = Penguin()
	test_scene:addEntity(new_penguin)
	Net.addObject(new_penguin)
	-- create camera
	main_view:follow(new_penguin)
end

function playState:update(dt)
	if k_join() and not Net.is_connected then
		--new_penguin = Penguin()
		--test_scene:addEntity(new_penguin)
		Net.join()
	end
	wall_x = wall_x + 0.5
end

function playState:draw()
	main_view:draw(function()
		Net.draw('Penguin')
		test_scene:draw()
	end)
	Draw.line(wall_x, 0, wall_x, game_height)
	Debug.draw()
end	
