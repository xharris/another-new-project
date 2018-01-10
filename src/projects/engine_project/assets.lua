asset_path=''
if _REPLACE_REQUIRE then
	asset_path=_REPLACE_REQUIRE:gsub('%.','/')
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

function assets:second_beat()
	local new_aud = love.audio.newSource(asset_path..'assets/audio/second_beat.wav','stream')
	return new_aud
end
function assets:main_scene()
	 return asset_path.."assets/scene/main_scene.json"
end


require 'scripts.entity.entity0'

require 'scripts.state.state0'
_FIRST_STATE = state0

