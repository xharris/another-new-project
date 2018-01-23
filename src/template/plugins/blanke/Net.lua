Net = {
    entity_update_rate = 0, -- m/s
    
    is_init = false,
    is_connected = false,
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
        return Net
    end,
    
    update = function(dt,override)
        override = ifndef(override, true)

        if Net.is_init then
            if Net.server then Net.server:update(dt) end
            if Net.client then 
                Net.client:update(dt)
                local data = Net.client:receive()
                if data then
                    Net._onReceive(data)
                end
            end

            Net._timer = Net._timer + 1
            if override or Net._timer % Net.entity_update_rate == 0 then
                Net.updateEntities()
            end
        end
        return Net
    end,

    -- returns "Server" object
    host = function()
        if Net.server then return end
        if Net.client then return end
        if not Net.is_init then
            Net.init(Net.address, Net.port)
        end   
        Net.server = grease.udpServer()
        Net.server:setPing()
        Net.server:listen(Net.port)
        
        Net.server.callbacks.connect = Net._onConnect
        Net.server.callbacks.disconnect = Net._onDisconnect
        Net.server.callbacks.recv = Net._onReceive

        Net.server.handshake = "blanke_net"
        Debug.log("hosting")

        --Net.server:startserver(Net.port)
        -- room_create() -- default room

        return Net
    end,
    
    -- returns "Client" object
    join = function(address, port) 
        if Net.server then return end
        if Net.client then return end
        if not Net.is_init then
            Net.init(address, port)
        end
        Net.client = grease.udpClient()
        
        Net.client.callbacks.recv = Net._onReceive

        Net.client.handshake = "blanke_net"
        
        Net.client:setPing()
        Net.client:connect(Net.address, Net.port)
        Net.is_connected = true
        Debug.log("joining")

        return Net
    end,

    disconnect = function()
        if Net.client then Net.client:disconnect() end
        Net.is_init = false
        Net.is_connected = false
        Net.client = nil
        return Net
    end,
    
    _onConnect = function(clientid) 
        Debug.log('+ '..clientid)
    end,
    
    _onDisconnect = function(clientid) 
        Debug.log('- '..clientid)
        if Net.onDisconnect then Net.onDisconnect(clientid) end
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
        Debug.log(data.event)

        function addEntity(info)
            local classname = info.classname

            -- is entity this instance?
            --if info._client_id == Net.id then return false end

            -- if entity is not already added
            if Net._server_entities[classname] ~= nil and
               Net._server_entities[classname][info.net_uuid] ~= nil then return false end

            -- set properties
            local new_entity = _G[classname]()
            for key, val in pairs(info) do
                new_entity[key] = val
            end
            --new_entity._client_id = info._client_id
            new_entity.is_net_entity = true

            Net._server_entities[classname] = ifndef(Net._server_entities[classname], {})
            Net._server_entities[classname][info.net_uuid] = new_entity
            return true
        end

        if data.type and data.type == 'netevent' then
            Debug.log(data.event)
            -- get assigned client id
            if data.event == 'getID' then
                Net.id = data.info
            end
            
            -- new entity added
            if data.event == 'entity.add' then
                if addEntity(Net._getEntityInfo(data.info)) then
                    Debug.log("added "..data.info.net_uuid)
                end
            end

            -- update net entity
            if data.event == 'entity.update' then
                local info = data.info

                if Net._server_entities[info.classname] ~= nil then
                    for net_uuid, entity in pairs(Net._server_entities[info.classname]) do
                        if entity.net_uuid == info.net_uuid then
                            for key, val in pairs(info) do
                                entity[key] = val
                            end
                        end
                    end
                end
            end

            -- synchronize entities on server
            if data.event == 'entity.sync' then
                for i, info in ipairs(data.info) do
                    if addEntity(info) then
                        Debug.log("added "..info._client_id)
                    end
                end
            end

            -- new person has joined network
            if data.event == 'join' then
                --[[
                Net.send({
                    type="netevent",
                    event="entity.sync",
                    info={
                        exclude_uuid=data.info.id
                    }
                })
                ]]--
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

    send = function(in_data) 
        data = json.encode(in_data)
        if Net.server then Net.server:send(data) end
        if Net.client then Net.client:send(data) end
        return Net
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
        entity_info._client_id = Net.id

        return entity_info
    end,

    addEntity = function(entity)
        Net._client_entities[entity.net_uuid] = entity

        --notify the other server clients
        Net.send({
            type='netevent',
            event='entity.add',
            info=Net._getEntityInfo(entity)
        })
        return Net
    end,

    updateEntities = function()
        for net_uuid, entity in pairs(Net._client_entities) do
            Debug.log("updating "..net_uuid)
            Net.send({
                type='netevent',
                event='entity.update',
                info=Net._getEntityInfo(entity)
            })
        end
        return Net
    end,

    draw = function(obj_name)
        if Net._server_entities[obj_name] then
            for net_uuid, obj in pairs(Net._server_entities[obj_name]) do
                obj:draw()
            end
        end
        return Net
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

return Net