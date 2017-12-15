_FIRST_STATE = ''
_REPLACE_REQUIRE = nil
game_name = "blanke"

-- engine
require('plugins.blanke.Blanke')
require('assets')

function love.load()
    BlankE.init(_FIRST_STATE)
end