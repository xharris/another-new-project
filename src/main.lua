package.cpath = package.cpath .. ";/usr/local/lib/lua/5.2/?.so;/usr/local/lib/lua/5.2/?.dll;./?.dll;./?.so"

require "imgui"
require "template.plugins.printr"
_watcher = require 'watcher'

_FIRST_STATE = nil
_GAME_NAME = "blanke"
--require "includes"

require "ide.ui"
require "ide.helper"
require "ide.ide"
require "ide.console"

function love.load()
    IDE.setProjectFolder(IDE.project_folder)
    IDE.load()
end

function love.update(dt)
    imgui.NewFrame()
    IDE.update(dt)
end

function love.draw()
    if not BlankE or (BlankE and not BlankE._ide_mode) then
        IDE.draw()
    end
end

function love.quit()
    imgui.ShutDown();
end

--
-- User inputs
--
function love.textinput(t)
    imgui.TextInput(t)
    if not imgui.GetWantCaptureKeyboard() then
        -- Pass event to the game
    end
end

function love.keypressed(key)
    imgui.KeyPressed(key)
    if not imgui.GetWantCaptureKeyboard() then
        -- Pass event to the game
    end
end

function love.keyreleased(key)
    imgui.KeyReleased(key)
    if not imgui.GetWantCaptureKeyboard() then
        -- Pass event to the game
    end
end

function love.mousemoved(x, y)
    imgui.MouseMoved(x, y)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end

function love.mousepressed(x, y, button)
    imgui.MousePressed(button)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end

function love.mousereleased(x, y, button)
    imgui.MouseReleased(button)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end

function love.wheelmoved(x, y)
    imgui.WheelMoved(y)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
    end
end