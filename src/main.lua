package.cpath = package.cpath .. ";/usr/local/lib/lua/5.2/?.so;/usr/local/lib/lua/5.2/?.dll;./?.dll;./?.so"

require "imgui"
require "template.plugins.printr"

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
end

function love.draw()
    -- Menu
    if imgui.BeginMainMenuBar() then
        -- FILE
        if imgui.BeginMenu("File") then
            -- project directory
            status, new_folder = imgui.InputText("",IDE.project_folder,300)
            if status and new_folder ~= IDE.project_folder then
                IDE.setProjectFolder(new_folder)
            end
            -- available projects in dir
            if #IDE.project_list > 0 then
                imgui.BeginChild("project list", 0, 60, true)
                for p, project in ipairs(IDE.project_list) do
                    -- chose a project to open?
                    if imgui.MenuItem(project) then
                        IDE.openProject(IDE.project_folder..'/'..project)
                    end
                end
                imgui.EndChild()
            end
            if IDE.current_project ~= '' then
                imgui.MenuItem("Save")
            end
            imgui.EndMenu()
        end

        -- ADD OBJECT
        if IDE.current_project ~= '' and imgui.BeginMenu("Add") then
            for m, mod in pairs(IDE.modules) do
                local clicked = imgui.MenuItem(m)
                if clicked and mod.new then
                    mod.new()
                    IDE.refreshAssets()
                end
            end
            imgui.EndMenu()
        end

        -- DEV
        if imgui.BeginMenu("Dev") then
            UI.titlebar.show_dev_tools = imgui.MenuItem("Show dev tools")
            imgui.EndMenu()
        end
        imgui.EndMainMenuBar()
    end
    
    --checkUI("titlebar.new_project", IDE.newProject)
    if UI.titlebar.new_project then UI.titlebar.new_project = IDE.newProject() end
    if UI.titlebar.show_dev_tools then UI.titlebar.show_dev_tools = imgui.ShowTestWindow(true) end

    CONSOLE.draw()

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