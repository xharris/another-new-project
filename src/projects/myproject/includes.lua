game_name = _GAME_NAME

CONF = {
    window = {
        width = 800,
        height = 600
    }
}

-- engine
package.path = package.path .. ";..\\template\\?.lua"
require('plugins.blanke.Blanke')

-- assets
require 'assets'
