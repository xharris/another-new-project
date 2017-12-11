--  GOALS
--[[
(C) complete, usable, good enough
(D) done, but feels incomplete
(W) wip

    - add 'return self' to end of some classes                      (C)
    - slowly replace 3rd party plugins                              (D)
        ~ keep an eye on system.lua for os compatibility issues     (W)
    - game exporting (D=works on mac and windows)
        ? download 10.2 of LoVE for needed os                       
        - .LoVE                                                     (D)
        - win                                                       (D)
        - mac                                                       (W)
        - web
        - android
        - ios
    - run game externally (export and run)                          (W)
    - plugins
        - asset explorer                                            (D)
            - call rename method of modules on rename               (W)
        - image editor (pixel art, spritesheets)
        - exporter                                                  (-)
            - see "game exporting" ^^^                              (-)
    - scene editor
        - zooming in/out                                            (D)
        - add/remove/move layer                                     (D)
    - closing a project                                             (C)

    BUGS

    - Timer/Entity jumping example is not consistent in exported game
    - Rework shaders
        - Some shaders cause screen to go white/black (crt)
        - Poor use of canvases
    - IDE text color does not update on errors
    - replace more helper.py functions (newScript)
    - start the scene when a new one is created
]]
ProFi = nil
if _PROFILING then
    ProFi = require 'profiler'
    ProFi:setGetTimeMethod( love.timer.getTime )
    ProFi:start()
end

local old_print = print
print = function(...)
    local debug_info = debug.getinfo(2)
    old_print(debug_info.short_src..':'..debug_info.currentline, ...);
end

package.cpath = package.cpath .. ";/usr/local/lib/lua/5.2/?.so;/usr/local/lib/lua/5.2/?.dll;./?.dll;./?.so"

require "imgui"
lfs = require "lfs"
require "template.plugins.blanke.extra.printr"
require "template.plugins.blanke.Util"
_watcher = require 'watcher'

_GAME_NAME = "blanke"

require "ide.system"
require "ide.helper"
require "ide.ui"
require "ide.ide"
require "ide.console"

function love.load()
    IDE.setProjectFolder(IDE.project_folder)
    IDE.load()
end

function love.update(dt)
    imgui.NewFrame()
    if BlankE and not IDE.errd then BlankE.update(dt) end
    IDE.update(dt)
end

function love.draw()
    if BlankE and not IDE.errd and UI.getSetting('show_game') then
        BlankE.draw()
        State.draw()
    end
    IDE.draw()
end

function love.quit()
    IDE.quit()
    if BlankE then BlankE.quit() end
    imgui.ShutDown();
    if _PROFILING then
        ProFi:stop()
        ProFi:writeReport("profile_report.txt")
    end
end

function love.filedropped(file)
    IDE.addResource(file)
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
        if BlankE then BlankE.keypressed(key) end
    end
end

function love.keyreleased(key)
    imgui.KeyReleased(key)
    if not imgui.GetWantCaptureKeyboard() then
        -- Pass event to the game
        if BlankE then BlankE.keyreleased(key) end
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
        if BlankE then BlankE.mousepressed(x,y,button) end
    end
end

function love.mousereleased(x, y, button)
    imgui.MouseReleased(button)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
        if BlankE then BlankE.mousereleased(x,y,button) end
    end
end

function love.wheelmoved(x, y)
    imgui.WheelMoved(y)
    if not imgui.GetWantCaptureMouse() then
        -- Pass event to the game
        if BlankE then BlankE.wheelmoved(x,y) end
    end
end

 --[[
local function error_printer(msg, layer)
    print((debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", "")))
end
function love.errhand(msg)
    IDE.errd = true

    local trace = debug.traceback()
    local err = {}
 
    table.insert(err, "Error\n")
    table.insert(err, msg.."\n\n")
 
    for l in string.gmatch(trace, "(.-)\n") do
        if not string.match(l, "boot.lua") then
            l = string.gsub(l, "stack traceback:", "Traceback\n")
            table.insert(err, l)
        end
    end
 
    local p = table.concat(err, "\n")
 
    p = string.gsub(p, "\t", "")
    p = string.gsub(p, "%[string \"(.-)\"%]", "%1")
 
    if love.math then
        love.math.setRandomSeed(os.time())
    end
 
    if love.load then love.load(arg) end
 
    -- We don't want the first frame's dt to include time taken by love.load.
    if love.timer then love.timer.step() end
 
    local dt = 0
 
    -- Main loop time.
    while true do
        -- Process events.
        if love.event then
            love.event.pump()
            for name, a,b,c,d,e,f in love.event.poll() do
                if name == "quit" then
                    if not love.quit or not love.quit() then
                        return a
                    end
                end
                love.handlers[name](a,b,c,d,e,f)
            end
        end
 
        -- Update dt, as we'll be passing it to update
        if love.timer then
            love.timer.step()
            dt = love.timer.getDelta()
        end
 
        -- Call update and draw
        if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled
 
        if love.graphics and love.graphics.isActive() then
            love.graphics.clear(love.graphics.getBackgroundColor())
            love.graphics.origin()
            
            if IDE.errd then
                BlankE.errhand(p)
                IDE.draw()
            else
                love.draw()
            end

            love.graphics.present()
        end
 
        if love.timer then love.timer.sleep(0.001) end
    end
 
end]]