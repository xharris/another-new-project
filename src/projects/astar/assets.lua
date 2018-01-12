asset_path=''
if _REPLACE_REQUIRE then
	asset_path=_REPLACE_REQUIRE:gsub('%.','/')
end
assets = Class{}
function assets:level1()
	 return asset_path.."assets/scene/level1.json"
end



require 'scripts.state.state0'

