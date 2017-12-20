require 'class'
grease = require 'grease'
require 'Util'
require 'json'
local uuid = require 'uuid'
local Debug = require 'Debug'

Debug.setFontSize(10)
Debug.setMargin(5)

-- BlankE Net server
Net = {
    entity_update_rate = 0, -- m/s
    
    is_init = false,
    client = nil,
    server = nil,
    
    onReceive = nil,    
    onConnect = nil,    
    onDisconnect = nil, 
    
    address = "localhost",
    port = 12345,

    _client_entities = {},      -- entities added by this client
    _server_entities = {},      -- entities added by other clients

    _entity_property_excludes = {'^_images$','^_sprites$','^sprite$','previous$','start$','^shapes$','^collision','^onCollision$','^is_net_entity$'},
    
    _timer = 0,
    id = nil,

    init = function(address, port)
        Net.address = ifndef(address, "localhost") 
        Net.port = ifndef(port, Net.port) 
        Net.is_init = true

        Debug.log("networking initialized")
    end,
    
    update = function(dt,override)
        override = ifndef(override, true)

        if Net.is_init then
            if Net.server then Net.server:update(dt) end

            Net._timer = Net._timer + 1
            if override or Net._timer % Net.entity_update_rate == 0 then
                Net.updateEntities()
            end
        end
    end,

    -- returns "Server" object
    host = function()
        if not Net.is_init then
            Net.init(Net.address, Net.port)
        end      
        Net.server = grease.udpServer()

        Net.server.callbacks.connect = Net._onConnect
        Net.server.callbacks.disconnect = Net._onDisconnect
        Net.server.callbacks.recv = Net._onReceive

        Net.server.handshake = "blanke_net"
        
        Net.server:listen(Net.port)

        Debug.log('hosting ' .. Net.address .. ':' .. Net.port)
        -- room_create() -- default room
    end,
    
    _onConnect = function(clientid) 
        Debug.log('+ ' .. clientid)
        Net.send({
            type='netevent',
            event='getID',
            info=clientid
        }, clientid)
        Net.syncEntities(clientid)
    end,
    
    _onDisconnect = function(clientid) 
        Debug.log('- ' .. clientid)

        if Net.onDisconnect then Net.onDisconnect(data) end
        for ent_class, entities in pairs(Net._server_entities) do
            for ent_uuid, entity in pairs(entities) do
                if entity._client_id == data then
                    Net._server_entities[ent_class][ent_uuid] = nil
                end
            end
        end
    end,
    
    _onReceive = function(data, id)
        if data:starts('{') then
            data = json.decode(data)
        elseif data:starts('"') then
            data = data:sub(2,-2)
        end

        if type(data) == "string" and data:ends('\n') then
            data = data:gsub('\n','')
        end

        if type(data) == "string" and data:ends('-') then
            Net._onDisconnect(data:sub(1,-2))
            return
        end

        if type(data) == "string" and data:ends('+') then
            Net._onConnect(data:sub(1,-2))
            return
        end

        function addEntity(info)
            local classname = info.classname
            local new_entity = {}

            if Net._server_entities[classname] ~= nil and
               Net._server_entities[classname][info.net_uuid] ~= nil then return false end

            -- set properties
            for key, val in pairs(info) do
                new_entity[key] = val
            end
            new_entity._client_id = info._client_id
            new_entity.is_net_entity = true

            Net._server_entities[classname] = ifndef(Net._server_entities[classname], {})
            Net._server_entities[classname][info.net_uuid] = new_entity
            return true
        end

        if data.type and data.type == 'netevent' then
            Debug.log(data.event)
            -- new entity added
            if data.event == 'entity.add' then
                if addEntity(data.info) then
                    Net.send(Net._getEntityInfo(data))
                end
            end

            -- update net entity
            if data.event == 'entity.update' then
                Net.send({
                    type='netevent',
                    event='entity.update',
                    info={
                        classname=data.info.classname,
                        net_uuid=data.info.net_uuid,
                        ent_info=data.info
                    }
                })
            end

            -- new person has joined network
            if data.event == 'join' then
            end

            -- send to all clients
            if data.event == 'broadcast' then
                Net.send({
                    type='netevent',
                    event='broadcast',
                    info=data.info
                })
            end
        end

        if Net.onReceive then Net.onReceive(data) end
    end,

    send = function(data, clientid) 
        data = json.encode(data)
        Net.server:send(data, clientid)
        return Net
    end,

    -- sent info to all clients about what entities are in the server
    syncEntities = function()
        Debug.log('sync')
        Net.send({
            type="netevent",
            event="entity.sync",
            info={
                entities=_server_entities
            }
        })
    end,

    disconnect = function()
        if Net.client then Net.client:disconnect() end
    end,

    _getEntityInfo = function(entity) 
        local entity_info = {}

        -- get properties needed for syncing
        for property, value in pairs(entity) do
            add = true
            if type(value) == 'function' then add = false end
            for i_e, exclude in ipairs(Net._entity_property_excludes) do
                if string.match(property, exclude) then
                    add = false
                end
            end

            if add then
                entity_info[property] = value
            end
        end
        entity_info.classname = entity.classname
        entity_info.x = entity.x
        entity_info.y = entity.y
        entity_info._client_id = entity._client_id

        return entity_info
    end,

    updateEntities = function()
        for net_uuid, entity in pairs(Net._client_entities) do
            Net.send({
                type='netevent',
                event='entity.update',
                info=Net._getEntityInfo(entity)
            })
        end
    end,
    
    --[[
    room_list = function() end,
    room_create
    room_join
    room_leave
    room_clients -- list clients in rooms
    
    entity_add -- add uuid to entity
    entity_remove
    entity_update -- manual update, usage example?

    send -- data
    
    -- events
    trigger
    receive -- data
    client_enter
    client_leave
    ]]
}

function love.load()
    Net.host()
end

function love.update(dt)
    Net.update(dt)
end

function love.draw()
    Debug.draw()
end