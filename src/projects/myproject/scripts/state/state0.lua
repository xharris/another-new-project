-- other functions: load(), leave()

local x, y, offsetx, offsety

-- Called every time when entering the state.
function state0:enter(previous)
    canv1 = Canvas()
    view1 = View()
    
    x = game_width/2
    y = game_height/2
    offsetx = 0
    offsety = 0
end

function state0:update(dt)
    offsetx = sinusoidal(0,100)
    offsety = sinusoidal(0,100)
   
    view1:moveToPosition(x+offsetx,y+offsety)
    view1.port_width = game_widh
    view1.port_height = game_height
    view1:zoom(10)
end

function state0:draw()
    Draw.setColor(255,255,255) 
    Draw.text(tostring(love.graphics:getWidth())..' '..tostring(love.graphics:getHeight()),200,188)
    Draw.text(tostring(x)..'\t'..tostring(y),200,200)

    canv1:draw(function()
        
        Draw.point(x+offsetx,y+offsety)
        
    end)
        
    view1:draw(function()
        canv1:show()
    end)
end	
