local script_path = (...):match('(.-)[^%.]+$')
local asset_path = script_path:gsub('%.','/')..'/'
local oldreq = require
local require = function(s) return oldreq(script_path .. s) end
assets = Class{}

function assets:penguin()
	local new_img = love.graphics.newImage(asset_path..'assets/image/penguin.png')
	return new_img
end

function assets:second_beat()
	local new_aud = love.audio.newSource(asset_path..'assets/audio/second_beat.wav','stream')
	return new_aud
end
state0 = Class{classname='state0'}
require 'scripts.state.state0'
_FIRST_STATE = state0


require = oldreq