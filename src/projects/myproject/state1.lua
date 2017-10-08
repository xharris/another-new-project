-- other functions: load(), leave()

-- Called every time when entering the state.
function state1:enter(previous)

end

function state1:update(dt)

end

function state1:draw()
    Draw.setColor(255,255,255)
    --Draw.rect(50,50,200,200)
    Draw.rect('line',50,50,200,200)
end	
