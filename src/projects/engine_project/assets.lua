assets = Class{}

function assets:penguin()
	local new_img = love.graphics.newImage('assets/image/penguin.png')
	return new_img
end

function assets:tile_ground()
	local new_img = love.graphics.newImage('assets/image/tile_ground.png')
	return new_img
end
function assets:main_scene()
	 return "assets/scene/main_scene.json"
end


entity0 = Class{__includes=Entity,classname='entity0'}
require 'scripts.entity.entity0'

state0 = Class{classname='state0'}
require 'scripts.state.state0'
_FIRST_STATE = state0
