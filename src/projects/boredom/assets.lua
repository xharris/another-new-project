asset_path=''
if _REPLACE_REQUIRE then
	asset_path=_REPLACE_REQUIRE:gsub('%.','/')
end
assets = Class{}

function assets:ground()
	local new_img = love.graphics.newImage(asset_path..'assets/image/ground.png')
	return new_img
end

function assets:ness_noscale()
	local new_img = love.graphics.newImage(asset_path..'assets/image/ness-noscale.jpg')
	return new_img
end

function assets:player_stand()
	local new_img = love.graphics.newImage(asset_path..'assets/image/player_stand.png')
	return new_img
end

function assets:player_walk()
	local new_img = love.graphics.newImage(asset_path..'assets/image/player_walk.png')
	return new_img
end
function assets:level1()
	 return asset_path.."assets/scene/level1.json"
end


require 'scripts.entity.entity0'

require 'scripts.state.level1'
BlankE.first_state = "level1"

