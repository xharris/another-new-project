ideHitbox = {
	getObjectList = function() 
		local ret_list = {}
		for h, hitbox in ipairs(Scene.hitbox) do
			table.insert(ret_list, hitbox.name)
		end
		return ret_list
	end,
}

return ideHitbox