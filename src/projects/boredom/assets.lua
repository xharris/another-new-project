asset_path=''
if _REPLACE_REQUIRE then
	asset_path=_REPLACE_REQUIRE:gsub('%.','/')
end
assets = Class{}


level1 = Class{classname='level1'}
require 'scripts.state.level1'
_FIRST_STATE = level1

