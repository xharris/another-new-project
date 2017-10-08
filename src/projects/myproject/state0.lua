-- other functions: load(), leave()

-- Called every time when entering the state.
function state0:enter(previous)
    lorenz_canvas = Canvas()
    lorenz_view = View()
    lorenz_canvas.auto_clear = false
    
    x = .01
    y = 0
    z = 0
    t = 1
    
    a = 10
    b = 2.66
    c = 28
end

local offset = 100
function state0:update(dt)
    t = .05-- t + 1
    
    -- lorenz
    local dx = (a*(y - x))*t
    local dy = (x*(b - z) - y)*t
    local dz = (x*y - c*z)*t
    
    x = x + dx
    y = y + dy
    z = z + dz
    
    lorenz_view:moveToPosition(x+offset,y+offset)
    lorenz_view.port_width = game_widh
    lorenz_view.port_height = game_height
    lorenz_view:zoom(10)
end

function state0:draw()
    Draw.setColor(255,255,255) 
    Draw.text(tostring(love.graphics:getWidth())..' '..tostring(love.graphics:getHeight()),200,188)
    Draw.text(tostring(x)..'\t'..tostring(y),200,200)

    lorenz_canvas:draw(function()
        
        Draw.point(x+offset,y+offset)
        
    end)
        
    lorenz_view:draw(function()
        lorenz_canvas:show()
    end)
end	
