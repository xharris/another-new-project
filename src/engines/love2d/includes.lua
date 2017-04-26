Signal = require 'plugins.hump.signal'
Gamestate = require 'plugins.hump.gamestate'
Class = require 'plugins.hump.class'
Timer = require 'plugins.hump.timer'
Vector = require 'plugins.hump.vector'
Camera = require 'plugins.hump.camera'
anim8 = require 'plugins.anim8'
HC = require 'plugins.HC'

assets = require 'assets'
_Entity = require 'plugins.blanke.Entity'
Map = require 'plugins.blanke.Map'

<INCLUDES>

Signal.register('love.load', function()
	-- register gamestates
	if "<FIRST_STATE>" ~= "" then
		Gamestate.registerEvents()
		Gamestate.switch(<FIRST_STATE>)
	end
end)
