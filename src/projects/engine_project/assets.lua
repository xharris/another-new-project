local asset_path = (...):match('(.-)[^%.]+$')
local oldreq = require
local require = function(s) return oldreq(asset_path .. s) end
assets = Class{}

function assets:penguin()
	local new_img = love.graphics.newImage('assets/image/penguin.png')
	return new_img
end

function assets:second_beat()
	local new_aud = love.audio.newSource(asset_path:gsub('%.','/')..'/assets/audio/second_beat.wav','stream')
	return new_aud
end
state0 = Class{classname='state0'}
require 'scripts.state.state0'
_FIRST_STATE = state0


require = oldreq
