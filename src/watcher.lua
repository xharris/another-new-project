local function ternary(condition, if_true, if_false)
    return condition and if_true or if_false
end

local last_modified = {}
local ignores = {'/dist/'}
local function _check_modification(dir, callback)
    local directory = ternary(string.sub(dir, #dir, #dir) == '/', dir, dir .. '/')
    local file

    local ignore = false
    for i, str in ipairs(ignores) do
        if directory:contains(str) then ignore = true end
    end

    if not ignore then
        for i, _file in ipairs(love.filesystem.getDirectoryItems(directory)) do
            if _file ~= '..' and _file ~= '.' then
                file = directory .. _file
                if love.filesystem.isFile(file) then
                    if last_modified[file] == nil then
                        last_modified[file] = 0
                    elseif love.filesystem.getLastModified(file) > last_modified[file] then
                        local old_modified = last_modified[file]
                        last_modified[file] = love.filesystem.getLastModified(file)
                        if old_modified ~= nil and old_modified ~= 0 then
                            callback(file)
                        end
                    end
                elseif love.filesystem.isDirectory(file) then
                    _check_modification(file .. '/', callback)
                end
            end
        end
    end
end


local last_dir = '$'
local function watcher(directory, callback)
    if last_dir ~= directory then
        last_dir = directory  
        last_modified = {}
    end

    _check_modification(directory, function(file_name)
        last = last_modified[file_name]
        
        if file_name ~= '' and file_name ~= nil then
            callback(file_name)
        end
    end)  
end

return watcher