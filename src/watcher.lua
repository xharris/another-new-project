local function ternary(condition, if_true, if_false)
    return condition and if_true or if_false
end

local last_modified = {}
local function _check_modification(dir, callback)
    local directory = ternary(string.sub(dir, #dir, #dir) == '/', dir, dir .. '/')
    local file

    for i, _file in ipairs(love.filesystem.getDirectoryItems(directory)) do
        if _file ~= '..' and _file ~= '.' then
            file = directory .. _file
            if love.filesystem.isFile(file) then
                if last_modified[file] == nil then
                    last_modified[file] = 0
                elseif love.filesystem.getLastModified(file) > last_modified[file] then
                    last_modified[file] = love.filesystem.getLastModified(file)
                    callback(file)
                end
            elseif love.filesystem.isDirectory(file) then
                _check_modification(file .. '/', callback)
            end
        end
    end
end


local last_dir = '$'
local function watcher(directory, callback)
    if last_dir ~= directory then
        last_modified = {}
        last_dir = directory
    end

    _check_modification(directory, function(file_name)
        last = last_modified[file_name]
        if file_name ~= '' then
            callback(file_name)
        end
    end)
        
end

return watcher