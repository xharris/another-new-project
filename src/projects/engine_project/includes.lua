game_name = _GAME_NAME

CONF = {
    window = {
        width = 800,
        height = 600
    }
}

-- engine
if _REPLACE_REQUIRE then
	require('template.plugins.blanke.Blanke')
else
	require('plugins.blanke.Blanke')
end

-- assets
local oldreq = require
local require = oldreq
if _REPLACE_REQUIRE then
	require = function(s) return oldreq(_REPLACE_REQUIRE .. s) end
end

require 'assets'

require = oldreq
