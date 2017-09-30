local asset_path = ''
local oldreq = require
if _REPLACE_REQUIRE then
	asset_path = _REPLACE_REQUIRE:gsub('%.','/')
	require = function(s) return oldreq(_REPLACE_REQUIRE .. s) end
end
assets = Class{}

function assets:penguin()
	local new_img = love.graphics.newImage(asset_path..'assets/image/penguin.png')
	return new_img
end

function assets:tile_ground()
	local new_img = love.graphics.newImage(asset_path..'assets/image/tile_ground.png')
	return new_img
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