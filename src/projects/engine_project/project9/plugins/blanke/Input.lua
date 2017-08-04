Input = Class{
	init = function(self, ...)
        self.in_key = {}
        self.in_mouse = {}
        self.in_region = {}

        self.onInput = nil
        self._on = false -- are any of the inputs active?

        -- implement later
        self.pressed = false
        self.released = false

		-- store inputs
		arg_inputs = {...}
		for i_in, input in ipairs(arg_inputs) do
			self:add(input)
		end

        _addGameObject('input',self)
	end,

	add = function(self, input)
        if input:starts("mouse") then
            local btn = input:split(".")[2]
            self.in_mouse[input] = false
        
        else -- regular keyboard input
            self.in_key[input] = false
            
        end
        return self
	end,
    
    remove = function(self, input)
        if input:starts("mouse") then
            local btn = input:split(".")[2]
            self.in_mouse[input] = nil
        
        else -- regular keyboard input
            self.in_key[input] = nil
            
        end
        return self
    end,
    
    addRegion = function(self, shape_type, ...)
        local other_args = {...}
        return self
    end,
    
    keypressed = function(self, key)
        if self.in_key[key] ~= nil then self.in_key[key] = true end
        return self
    end,
    
    keyreleased = function(self, key)
        if self.in_key[key] ~= nil then self.in_key[key] = false end
        return self
    end,
    
    mousepressed = function(self, x, y, button)
        local btn_string = "mouse." .. button
        if self.in_mouse[btn_string] ~= nil then self.in_mouse[btn_string] = true end
        
        local region = self:getRegion(x, y)
        if region ~= nil then
            region = true
        end
        return self
    end,
    
    mousereleased = function(self, x, y, button)
        local btn_string = "mouse." .. button
        if self.in_mouse[btn_string] ~= nil then self.in_mouse[btn_string] = false end
        
        local region = self:getRegion(x, y)
        if region ~= nil then
            region = false
        end
        return self
    end,
    
    getRegion = function(self, x, y)
        return nil
    end,

    _isOn = function(self)
        for input, val in pairs(self.in_key) do
            if val == true then return true end
        end
        
        for input, val in pairs(self.in_mouse) do
            if val == true then return true end
        end
        
        for input, val in pairs(self.in_region) do
            if val == true then return true end
        end

        return false
    end,
    
    __call = function(self)
        return self:_isOn()
    end
}

return Input