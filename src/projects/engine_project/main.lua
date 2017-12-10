--DEV_CODE_START
--package.path=package.path..";C:/Users/XHH/Documents/PROJECTS/blanke4/src/projects/engine_project/?.lua"
--package.path=package.path..";C:/Users/XHH/Documents/PROJECTS/blanke4/src/projects/engine_project/?/init.lua"
--"?/?.lua","?.lua","?/init.lua"
--DEV_CODE_END

_FIRST_STATE = ''
_REPLACE_REQUIRE = nil
game_name = "blanke"

CONF = {
    window = {
        width = 800,
        height = 600
    }
}

-- engine
require('plugins.blanke.Blanke')
require('assets')

function love.load()
    BlankE.init(_FIRST_STATE)
end