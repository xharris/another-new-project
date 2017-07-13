require "settings"
require "imgui"
require "includes"
require "IDE"

function love.load()
    BlankE.init(_FIRST_STATE)
end

function love.update(dt)
    imgui.NewFrame()
end

function love.draw()
    -- Menu
    if imgui.BeginMainMenuBar() then
        if imgui.BeginMenu("File") then
            UI.titlebar.new_project = imgui.MenuItem("New")
            imgui.MenuItem("Open")
            imgui.MenuItem("Save")
            imgui.EndMenu()
        end
        imgui.EndMainMenuBar()
    end

    if UI.titlebar.new_project then
        UI.titlebar.new_project = IDE.newProject()
    end

    love.graphics.clear(unpack(UI.color.background))
    imgui.Render();
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