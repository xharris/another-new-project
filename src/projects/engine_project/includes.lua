game_name = _GAME_NAME

local oldreq = require
local require = oldreq
if _REPLACE_REQUIRE then
	require = function(s) return oldreq(_REPLACE_REQUIRE .. s) end
end

require "plugins.printr"
require "plugins.json.json"
uuid = require("plugins.uuid")

Class = require 'plugins.hump.class'

require 'plugins.blanke.Globals'
require 'plugins.blanke.Util'
require 'plugins.blanke.Debug'

Input = require 'plugins.blanke.Input'

Signal = require 'plugins.hump.signal'
Gamestate = require 'plugins.hump.gamestate'
Timer = require 'plugins.hump.timer'
Vector = require 'plugins.hump.vector'
Camera = require 'plugins.hump.camera'
anim8 = require 'plugins.anim8'
HC = require 'plugins.HC'

require 'plugins.blanke.Blanke'

require 'assets'


require = oldreq
