local asset_path = (...):match('(.-)[^%.]+$')

local oldreq = require
local require = function(s) return oldreq(asset_path .. s) end

state0 = Class{classname='state0'}
require('scripts.state.state0')
_FIRST_STATE = state0

require = oldreq