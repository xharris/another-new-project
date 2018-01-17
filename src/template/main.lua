_REPLACE_REQUIRE = nil
game_name = "blanke"

-- engine
BlankE = require('plugins.blanke.Blanke')
require('assets')

function love.load()
    BlankE.init()
end