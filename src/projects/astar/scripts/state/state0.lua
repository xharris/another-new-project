BlankE.addClassType("state0", "State")

local square_size = 20
local squares = 20
local origin_x, origin_y

-- 0 : empty
-- 1 : wall
-- 2 : start
-- 3 : end
-- 4 : path
local EMPTY, WALL, START, END, PATH, VICTORY = 0, 1, 2, 3, 4, 5

local map

function getMap(x, y) 
	return map[y*squares+x]
end

function setMap(x, y, value)
	map[y*squares+x] = value
end

local start_x, start_y, end_x, end_y
local open_stack, started, done, step_timer

function state0:enter(previous)
	Debug.clear()
	map = {
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
		3, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0,
		0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0,
		0, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1, 0,
		1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 0,
		0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1,
		0, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1, 1,
		0, 1, 1, 1, 1, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 0,
		0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0,
		0, 0, 0, 1, 1, 1, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0,
		1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1,
		0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0,
		0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0,
		0, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1, 0,
		1, 1, 0, 1, 0, 1, 1, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 0,
		0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1,
		0, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 1, 0, 1, 1,
		0, 1, 1, 1, 1, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 0,
		0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0,
		2, 0, 0, 1, 1, 1, 0, 1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 0,
	}

	start_x = 0
	start_y = 0
	open_stack = {}
	started = false
	done = false
	step_timer = Timer()
	step_timer:every(function()
		if not BlankE.pause then aStarStep() end
	end, .1):start()

	-- find start point
	for x = 0, squares-1 do
		for y = 0, squares-1 do
			if getMap(x, y) == START then
				start_x = x
				start_y = y
			end
			if getMap(x, y) == END then
				end_x = x
				end_y = y
			end
		end
	end
end


function calcFValue(from_x, from_y, x, y, g)
	local space_type = getMap(x, y)
	if space_type == WALL or space_type == PATH or space_type == START
		or x < 1 or y < 1 or x > squares or y > squares then return -1 end
	local h = math.sqrt(math.pow(end_x - x,2) + math.pow(end_y - y,2))
	return g + h
end

function checkNeighbors(x, y, g)
	local f_values = {}
	local f_min = -1
	local checkN = function(in_x,in_y)
		local f_val = calcFValue(x, y, in_x, in_y, g)
		if f_min == -1 then f_min = f_val end
		if f_val ~= -1 and f_val <= f_min then
			table.insert(f_values, {in_x, in_y, f_val})
		end
	end
	checkN(x+1,y)
	checkN(x-1,y)
	checkN(x,y+1)
	checkN(x,y-1)

	checkN(x-1, y-1)
	checkN(x-1, y+1)
	checkN(x+1, y-1)
	checkN(x+1, y+1)

	table.sort(f_values, function(a, b)
		return a[3] > b[3]
	end)

	-- recheck min vals
	for i, value in ipairs(f_values) do
		if value[3] <= f_min then
			table.insert(open_stack, value)
		end
	end

end

function aStarStep()
	if not started then
		started = true
		table.insert(open_stack, {start_x, start_y, 0})
	end

	if #open_stack > 0 and not done then
		local curr_index = #open_stack
		local path_x, path_y, path_g = unpack(open_stack[curr_index])
		if getMap(path_x, path_y) == END then
			done = true
			setMap(path_x, path_y, VICTORY)
		else
			setMap(path_x, path_y, PATH)
			checkNeighbors(path_x, path_y, path_g)
		end
		table.remove(open_stack, curr_index)
	end
end

function state0:update(dt)
end

function state0:draw()
	origin_x = game_width/2 - ((square_size*squares)/2)
	origin_y = game_height/2 - ((square_size*squares)/2)
    for x = 1, squares-1 do
    	for y = 1, squares-1 do
    		local map_color = getMap(x, y)
    		local map_mode = "line"
    		if map_color == EMPTY then Draw.setColor(Draw.grey); map_mode = "line" end
    		if map_color == WALL then Draw.setColor(Draw.red); map_mode = "fill" end
    		if map_color == START then Draw.setColor(Draw.orange); map_mode = "fill" end
    		if map_color == END then Draw.setColor(Draw.blue); map_mode = "fill" end
    		if map_color == PATH then Draw.setColor(Draw.grey); map_mode = "fill" end
    		if map_color == VICTORY then Draw.setColor(Draw.green); map_mode = "fill" end

	        Draw.rect(map_mode,
	        	origin_x+(x*(square_size+1)),
	        	origin_y+(y*(square_size+1)),
	        	square_size,
	        	square_size
	        )
	    end
    end
end	
 