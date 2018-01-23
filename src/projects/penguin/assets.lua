asset_path=''
if _REPLACE_REQUIRE then
	asset_path=_REPLACE_REQUIRE:gsub('%.','/')
end
assets = Class{}

function assets:ground()
	local new_img = love.graphics.newImage(asset_path..'assets/image/ground.png')
	return new_img
end

function assets:penguin()
	local new_img = love.graphics.newImage(asset_path..'assets/image/penguin.png')
	return new_img
end

function assets:penguin_filler()
	local new_img = love.graphics.newImage(asset_path..'assets/image/penguin_filler.png')
	return new_img
end
function assets:test()
	 return asset_path.."assets/scene/test.json"
end


require 'scripts.entity.penguin'

require 'scripts.state.playState'
BlankE.first_state = "playState"

