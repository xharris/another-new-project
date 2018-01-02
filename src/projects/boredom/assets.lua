asset_path=''
if _REPLACE_REQUIRE then
	asset_path=_REPLACE_REQUIRE:gsub('%.','/')
end
assets = Class{}

function assets:player_stand()
	local new_img = love.graphics.newImage(asset_path..'assets/image/player_stand.png')
	return new_img
end
function assets:level1()
	 return asset_path.."assets/scene/level1.json"
end


require 'scripts.entity.entity0'

require 'scripts.state.level1'
_FIRST_STATE = level1

