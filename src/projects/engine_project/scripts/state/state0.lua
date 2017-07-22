-- Called once, and only once, before entering the state the first time.
function state0:init() end
function state0:leave() end 
local test_ent
-- Called every time when entering the state.
function state0:enter(previous)
	new_img = Image('penguin')
	new_img.x = 100
	new_img.y = 120
	main_scene = Scene('main_scene')
	test_ent = entity0()
    test_ent.nickname = "the first one"
	main_scene:addEntity(test_ent)
end

function state0:update(dt)

end

function state0:draw()
	love.graphics.setColor(255,0,0,255)
	love.graphics.print("hey how goes it", 100,100)
	love.graphics.setColor(255,255,255,255)
	new_img:draw()
	main_scene:draw()
end	