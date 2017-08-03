--[[
local sin = math.sin
local pi = math.pi
]]
function hex2rgb(hex)
	assert(type(hex) == "string", "hex2rgb: expected string, got "..type(hex).." ("..hex..")")
    hex = hex:gsub("#","")
    if(string.len(hex) == 3) then
        return {tonumber("0x"..hex:sub(1,1)) * 17, tonumber("0x"..hex:sub(2,2)) * 17, tonumber("0x"..hex:sub(3,3)) * 17}
    elseif(string.len(hex) == 6) then
        return {tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))}
    end
end

function clamp(x, min, max)
	if x < min then return min end
	if x > max then return max end
	return x
end

function lerp(a,b,amt)
	return a + (b-a) * amt
end

function ifndef(var_check, default)
	if var_check ~= nil then
		return var_check
	end
	return default
end

function random_range(n1, n2)
	return love.math.random(n1, n2)
end

function sinusoidal(min, max, speed, start_offset)
	local dist = (max - min)/2
	local offset = (min + max)/2
	local start = ifndef(start_offset, min) * (2*math.pi)
	return (100*math.sin(game_time * speed * math.pi + start)/100) * dist + offset;
end

love.graphics.resetColor = function()
	love.graphics.setColor(255, 255, 255, 255)
end

-- https://github.com/Donearm/scripts
function basename(str)
	local name = string.gsub(str, "(.*/)(.*)", "%2")
	return name
end
function dirname(str)
	if str:match(".-/.-") then
		local name = string.gsub(str, "(.*/)(.*)", "%1")
		return name
	else
		return ''
	end
end
function extname(str)
	return str:match("^.+(%..+)$")
end

function string:replaceAt(pos, r) 
	return table.concat{self:sub(1,pos-1),r,self:sub(pos+1)}
end

function string:starts(Start)
    return string.sub(self,1,string.len(Start))==Start
end

function string:ends(End)
	return string.sub(self,-string.len(End))==End
end
function string:split(sep)
   local sep, fields = sep or ":", {}
   local pattern = string.format("([^%s]+)", sep)
   self:gsub(pattern, function(c) fields[#fields+1] = c end)
   return fields
end
function string:trim()
	return self:gsub("^%s+", ""):gsub("%s+$", "")
end

function table.find(t, value)
	for v, val in pairs(t) do
		if val == value then
			return v
		end
	end
	return 0
end	

function table.has_value(t, value)
	for v, val in ipairs(t) do
		if val == value then return true end
	end
	return false
end