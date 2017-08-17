local asset_path = ''
local oldreq = require
if _REPLACE_REQUIRE then
	asset_path = _REPLACE_REQUIRE:gsub('%.','/')
	require = function(s) return oldreq(_REPLACE_REQUIRE .. s) end
end
assets = Class{}



if _REPLACE_REQUIRE then
	require = oldreq
end