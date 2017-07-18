-- Called once, and only once, before entering the state the first time.
function _empty_state:init() end
function _empty_state:leave() end 

-- Called every time when entering the state.
function _empty_state:enter(previous)

end

function _empty_state:update(dt)

end

local _offset=0
function _empty_state:draw()
	local _max_size = math.max(game_width, game_height)
	_offset = _offset + 1
	if _offset >= _max_size then _offset = 0 end

	love.graphics.push('all')
	for _c = 0,_max_size*2,10 do
		local _new_radius = _c-_offset
		local opacity = (_new_radius/_max_size)*300
		love.graphics.setColor(0,(_new_radius)/_max_size*255,0,opacity)
		love.graphics.circle("line", game_width/2, game_height/2, _new_radius)
	end
	love.graphics.setColor(255,255,255,sinusoidal(150,255,0.5))
	love.graphics.printf("NO GAME",0,game_height/2,game_width,"center")
	love.graphics.pop()
end	
