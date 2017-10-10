--INJECTED_CODE_START
package.path=package.path..";C:\\Users\\XHH\\Documents\\PROJECTS\\blanke4\\src\\template\\?.lua"
package.path=package.path..";C:\\Users\\XHH\\Documents\\PROJECTS\\blanke4\\src\\template\\?\\init.lua"
--INJECTED_CODE_END

_FIRST_STATE = nil
_GAME_NAME = "blanke"
_REPLACE_REQUIRE = false

require 'includes'

function love.load()
    BlankE.init(_FIRST_STATE)
end
