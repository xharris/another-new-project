asset_path=''
if _REPLACE_REQUIRE then
	asset_path=_REPLACE_REQUIRE:gsub('%.','/')
end
assets = Class{}

require 'scripts.entity.entity0'

require 'scripts.state.state0'
BlankE.first_state = "state0"

