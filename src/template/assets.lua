local asset_path = (...):match("(.-)[^%.]+$")

state0 = Class{classname='state0'}
require (asset_path..'scripts/state/state0')
_FIRST_STATE = state0