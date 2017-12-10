_FIRST_STATE = ''
_REPLACE_REQUIRE = false
game_name = "blanke"

CONF = {
    window = {
        width = 800,
        height = 600
    }
}

-- engine
require('plugins.blanke.Blanke')
require 'assets'

function love.load()
    BlankE.init(_FIRST_STATE)
end