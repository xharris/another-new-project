BlankE.addClassType("playState", "State")

local k_join, k_leave
main_view = View()

-- Called every time when entering the state.
function playState:enter(previous)
	Draw.setBackgroundColor('white2')

	test_scene = Scene('test')
	k_join = Input('j')
	k_leave = Input('d')
end

function Net:onReady()
	-- add player's penguin
	new_penguin = Penguin()
	test_scene:addEntity(new_penguin)
	main_view:follow(new_penguin)

	Net.addObject(new_penguin)
end

function playState:update(dt)
	if k_join() and not Net.is_connected then
		--new_penguin = Penguin()
		--test_scene:addEntity(new_penguin)
		
	new_penguin = Penguin()
	test_scene:addEntity(new_penguin)
	main_view:follow(new_penguin)
		--Net.join()
	end

	if k_leave() and Net.is_connected then
		Net.disconnect()
	end
end

function playState:draw()
	main_view:draw(function()
		Net.draw('Penguin')
		test_scene:draw()
	end)
	Debug.draw()
end	
