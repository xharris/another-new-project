game_name = _GAME_NAME

CONF = {
    window = {
        width = 800,
        height = 600
    }
}

local oldreq = require
local require = oldreq
if _REPLACE_REQUIRE then
	require = function(s) return oldreq(_REPLACE_REQUIRE .. s) end
end

require "plugins.printr"
require "plugins.json"
uuid = require("plugins.uuid")

Class = require ('plugins.blanke.Class') -- hump.class

anim8 = require 'plugins.anim8'
HC = require 'plugins.HC'

require 'plugins.blanke.Blanke'

require 'assets'

require = oldreq
