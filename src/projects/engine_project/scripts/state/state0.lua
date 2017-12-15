-- Called once, and only once, before entering the state the first time.
function state0:init() end
function state0:leave() end 

-- Called every time when entering the state.
function state0:enter(previous)
	Net.init()
	k_host = Input("h")
	k_join = Input("j")

	love.graphics.setBackgroundColor(255,255,255)
	new_img = Image('penguin')
	new_img.x = 100
	new_img.y = 120
    
	main_scene = Scene('main_scene')

	main_player = entity0()
	main_player.nickname = "player"
	main_player.x = 352
	main_player.y = 368
	main_scene:addEntity(main_player)
  
    main_view = View()
    main_view:follow(main_player)      

    copy_tiles = main_scene:getTileImage(480, 96)
end

function state0:update(dt)
	if k_host() then
		Net.host()
	end
	if k_join() then
		Net.join()
	end
end

function state0:draw()
	love.graphics.setColor(255,0,0,255)
	love.graphics.print("hey how goes it", 100,100)
	love.graphics.setColor(255,255,255,255)

	new_img:draw() 

    main_view:draw(function()
        main_scene:draw()
    end)
end	