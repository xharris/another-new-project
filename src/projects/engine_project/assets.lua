local asset_path = ''
local oldreq = require
if _REPLACE_REQUIRE then
	print('replacing require')
	asset_path = _REPLACE_REQUIRE:gsub('%.','/')
	require = function(s) return oldreq(_REPLACE_REQUIRE .. s) end
end
assets = Class{}
print('asseting',_REPLACE_REQUIRE,asset_path)


function assets:_6C992_circle()
	local new_img = love.graphics.newImage(asset_path..'assets/image/6C992-circle.png')
	return new_img
end

function assets:example2()
	local new_img = love.graphics.newImage(asset_path..'assets/image/example2.png')
	return new_img
end

function assets:penguin()
	local new_img = love.graphics.newImage(asset_path..'assets/image/penguin.png')
	return new_img
end

function assets:tileset_sample()
	local new_img = love.graphics.newImage(asset_path..'assets/image/tileset_sample.png')
	return new_img
end

function assets:second_beat()
	local new_aud = love.audio.newSource(asset_path..'assets/audio/second_beat.wav','stream')
	return new_aud
end
function assets:main_scene()
	 return asset_path.."assets/scene/main_scene.json"
end


entity0 = Class{__includes=Entity,classname='entity0'}
require 'scripts.entity.entity0'

state0 = Class{classname='state0'}
require 'scripts.state.state0'
_FIRST_STATE = state0

if _REPLACE_REQUIRE then
	require = oldreq
end