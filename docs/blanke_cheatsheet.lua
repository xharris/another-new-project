-- -- ENTITY
-- add a sprite
self:addAnimation(
	'walk', 		-- sprite name
	'spritesheet0', -- image name
	{'1-2', 1}, 	-- {columns, rows}
	0.4				-- speed
)
self.sprite_index = 'walk'