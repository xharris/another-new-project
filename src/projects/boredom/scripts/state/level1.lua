BlankE.addClassType("level1", "State")
local main_scene

function level1:enter(previous)
	Draw.setBackgroundColor(Draw.white2)
	main_scene = Scene("level1")
	--main_view = View()
	local layers = main_scene:getList("entity")
	local player
	for layer, data in pairs(layers) do
		for e, ent in ipairs(data) do
			if ent.classname == 'entity0' then
				player = ent
			end
		end
	end	
	--main_view:follow(player)
end

function level1:update(dt) 
end

function level1:draw()
	--main_view:draw(function()
		main_scene:draw()
	--end)
	Debug.draw()
end	
