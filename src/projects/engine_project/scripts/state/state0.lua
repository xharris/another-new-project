-- Called once, and only once, before entering the state the first time.
function state0:init() end
function state0:leave() end 

EffectManager.new{
	name = 'outline',
	params = {['stepSize']={0,0}},
	code = [[

vec4 resultCol;
extern number stepSize;

number alpha;

vec4 effect( vec4 col, Image texture, vec2 texturePos, vec2 screenPos )
{
    // get color of pixels:
    alpha = texture2D( texture, texturePos + vec2(0,-stepSize)).a;
    alpha -= texture2D( texture, texturePos + vec2(0,stepSize) ).a;

    // calculate resulting color
    resultCol = vec4( 1.0f, 1.0f, 1.0f, 0.5f*alpha );
    // return color for current pixel
    return resultCol;
}
	]]
}

-- Called every time when entering the state.
function state0:enter(previous)
	love.graphics.setBackgroundColor(255,255,255,255)
	new_img = Image('penguin')
	new_img.x = 100
	new_img.y = 120
    
	main_scene = Scene('main_scene')
    
	test_ent = entity0(96, 224)
    test_ent.nickname = "player"
	main_scene:addEntity(test_ent)
    
    main_view = View()
    main_view:follow(test_ent)

    main_effect = Effect('crt') 
    --main_effect.stepSize = {3/new_img.width, 3/new_img.height}
end

function state0:update(dt)

end

function state0:draw()
	love.graphics.setColor(255,0,0,255)
	love.graphics.print("hey how goes it", 100,100)
	love.graphics.setColor(255,255,255,255)

	new_img:draw()
    --main_effect:draw(function()
    	new_img:draw() 
    --end)

    main_view:draw(function()
        main_scene:draw()
    end)
    Debug.draw()
end	