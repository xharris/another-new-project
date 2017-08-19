local asset_path = ''
local oldreq = require
if _REPLACE_REQUIRE then
	asset_path = _REPLACE_REQUIRE:gsub('%.','/')
	require = function(s) return oldreq(_REPLACE_REQUIRE .. s) end
end
assets = Class{}


state0 = Class{classname='state0'}
require 'scripts.state.state0'
state1 = Class{classname='state1'}
require 'scripts.state.state1'
_FIRST_STATE = state1

if _REPLACE_REQUIRE then
	require = oldreq
end