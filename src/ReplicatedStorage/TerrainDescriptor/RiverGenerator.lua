local module = {}

local debug_messages = false

local RiverGeneratorBase = {
	--Default properties
	 max_lifetime = 50
	,river_amount = 5
	,water_level  = 0.3
	,seed = 251
	,text_output = true
}

local function object_constructor()
	local new_object = {}
	return setmetatable(new_object,{__index = RiverGeneratorBase})
end

local function debug_msg(...)
	if debug_messages then
		print(...)
	end
end

RiverGeneratorBase.new = object_constructor

local function ValleyDetection(Heightmap,water_level)
	local map_width  = #Heightmap
	local map_height = Heightmap[1] and #Heightmap[1] or 0

	local drains = {}
	--Make map edges drain water
	do
		for x = 1,map_width do
			drains[x] = {}
			drains[x][1] = true
			drains[x][map_height] = true
		end

		for y = 1,map_height do
			drains[1][y] = true
			drains[map_width][y] = true
		end
	end

	local fill = {}

	for x = 1,map_width do
		fill[x] = {}
	end

	local changed = true

	while changed do

		changed = false

		for x = 1, map_width do
			for y = 1, map_height do
				local val = fill[x][y] or Heightmap[x][y]

				local lowest_surrunding = math.huge

				--Get lowest surrounding tile that drains into the ocean
				if x > 1 and drains[x-1][y] then
					local cmp_val = fill[x-1][y] or Heightmap[x-1][y]
					if cmp_val <= lowest_surrunding then
						lowest_surrunding = cmp_val
					end
				end

				if y > 1 and drains[x][y-1] then
					local cmp_val = fill[x][y-1] or Heightmap[x][y-1]
					if cmp_val <= lowest_surrunding then
						lowest_surrunding = cmp_val
					end
				end

				if x < map_width and drains[x+1][y] then
					local cmp_val = fill[x+1][y] or Heightmap[x+1][y]
					if cmp_val <= lowest_surrunding then
						lowest_surrunding = cmp_val
					end
				end

				if y < map_height and drains[x][y+1] then
					local cmp_val = fill[x][y+1] or Heightmap[x][y+1]
					if cmp_val <= lowest_surrunding then
						lowest_surrunding = cmp_val
					end
				end

				if lowest_surrunding ~= math.huge then

					if lowest_surrunding > Heightmap[x][y] then
						if fill[x][y] ~= lowest_surrunding then
							fill[x][y] = lowest_surrunding
							changed = true
						end
					elseif fill[x][y] then
						fill[x][y] = nil
						changed = true
					end

					drains[x][y] = true
				end

			end
		end

	end

	for x=1,map_width do
		for y=1,map_height do
			if fill[x][y] and fill[x][y] <= water_level then
				fill[x][y] = nil
			end
		end
	end

	return fill
end

local function valley_to_lake(valleys,lakes,posX,posY)
	if not (valleys[posX] and valleys[posX][posY]) then
		error("Valley not found at position "..tostring(posX)..", "..tostring(posY))
	end

	local function recursive_line_fill(posX,posY)
		lakes[posX] = lakes[posX] or {}

		local y = posY
		local max_y

		while valleys[posX][y] do
			lakes[posX][y] = valleys[posX][y]
			max_y = y
			y = y + 1
		end

		y = posY - 1

		while valleys[posX][y] do
			lakes[posX][y] = valleys[posX][y]
			y = y - 1
		end

		for y = y+1, max_y do
			if valleys[posX+1][y] and not (lakes[posX+1] and lakes[posX+1][y]) then
				recursive_line_fill(posX+1,y)
			end

			if valleys[posX-1][y] and not (lakes[posX-1] and lakes[posX-1][y]) then
				recursive_line_fill(posX-1,y)
			end
		end
	end

	recursive_line_fill(posX,posY)
end

local function is_rivers_nearby(rivers,x,y)
	if rivers[x] then
		if rivers[x][y+1] then
			return true
		end
		if rivers[x][y-1] then
			return true
		end
		if rivers[x][y] then
			return true
		end
	end

	if rivers[x+1] then
		if rivers[x+1][y+1] then
			return true
		end
		if rivers[x+1][y-1] then
			return true
		end
		if rivers[x+1][y] then
			return true
		end
	end

	if rivers[x-1] then
		if rivers[x-1][y+1] then
			return true
		end
		if rivers[x-1][y-1] then
			return true
		end
		if rivers[x-1][y] then
			return true
		end
	end


	return false
end

function RiverGeneratorBase.Generate(self, Heightmap)
	local map_width  = #Heightmap
	local map_height = Heightmap[1] and #Heightmap[1] or 0

	local RandomGen = Random.new(self.seed or 0)

	local valleys = ValleyDetection(Heightmap, self.water_level)

	--[[
		Because rivers should not split, river tile should be lower or on the same height as the surrouding tiles.
		Because of that we need to find the lowest surrounding tile, that is not the next tile where river will flow, and level
		current tile (tile at given X and Y) to it.
		Also, river shouldn't be lower that a lake, so this function checks that too.
	]]--
	local function get_val_leveled(x,y)
		local sec_low_height = Heightmap[x][y]
		local lowest_height = Heightmap[x][y]
		local lowest_lake = math.huge

		local function checkval(x,y)
			if not (valleys[x] and valleys[x][y]) then

				local val = Heightmap[x][y]

				if val <= lowest_height then
					sec_low_height = lowest_height
					lowest_height = val
				elseif val < sec_low_height then
					sec_low_height = val
				end

			elseif lowest_lake > valleys[x][y] then
				lowest_lake = valleys[x][y]
			end
		end

		checkval(x-1,y)
		checkval(x+1,y)
		checkval(x,y-1)
		checkval(x,y+1)

		if lowest_lake ~= math.huge and lowest_lake > sec_low_height then
			return lowest_lake
		end

		return sec_low_height
	end

	local rivers = {}
	local lakes = {}

	local function rivers_put(x,y,height)
		if not rivers[x] then
			rivers[x] = {}
		end
		rivers[x][y] = height
	end

	for river_num = 1, self.river_amount do

		local posX
		local posY

		--Pick a starting position
		do
			repeat
				local good_height = false
				local is_empty = true

				posX = RandomGen:NextInteger(20,map_width-20)
				posY = RandomGen:NextInteger(20,map_height-20)

				if Heightmap[posX][posY] >= 0.45 and Heightmap[posX][posY] < 0.9 then
					good_height = true
				end

				--River shouldn't spawn in valley
				if valleys[posX][posY] then
					is_empty = false
				end

				--River shouldn't spawn next to another river
				if is_rivers_nearby(rivers,posX,posY) then
					is_empty = false
				end

			until good_height and is_empty

			rivers_put(posX,posY,get_val_leveled(posX,posY))
		end


		local dirX,dirY = 0,0
		local velX,velY = 0,0

		--Simulate river flow
		for lifetime=1, self.max_lifetime do

			if posX <= 1 or posY <= 1 or posX >= map_width or posY >= map_height then
				debug_msg("END: MAP BORDER MET")
				break
			end

			local current_val = get_val_leveled(posX,posY)

			--[[
				To find next river position we should check leveled values of 4 surrounding tiles and pick the lowest.
				If there is two tiles with the same leveled values, pick one that have the lowest value on a heightmap.
				If they have same leveled and heightmap values, pick one according to river's velocity.
			]]--
			local lowest_height = math.huge
			local lowest_x
			local lowest_y

			local function check_pos(x_diff,y_diff)
				if math.abs(dirY - y_diff) <= 1 and math.abs(dirX - x_diff) <= 1 then

					local result_posX = posX + x_diff
					local result_posY = posY + y_diff

					local val = get_val_leveled(result_posX, result_posY)

					if val < lowest_height then

						lowest_height = val
						lowest_x = result_posX
						lowest_y = result_posY

					elseif val == lowest_height then

						if (Heightmap[lowest_x][lowest_y] > Heightmap[result_posX][result_posY]) then

							lowest_x = result_posX
							lowest_y = result_posY

						elseif (Heightmap[lowest_x][lowest_y] == Heightmap[result_posX][result_posY]) then
							--On completely flat surfaces water will flow according to it's velocity
							if ((x_diff ~= 0 and x_diff == velX) or x_diff == 0) and
							   ((y_diff ~= 0 and y_diff == velY) or y_diff == 0) then

								lowest_x = result_posX
								lowest_y = result_posY

							end
						end

					end

				end
			end

			check_pos(-1,0)
			check_pos(1,0)
			check_pos(0,-1)
			check_pos(0,1)

			--This one shouldn't happen
			if lowest_height > current_val then
				debug_msg("END: NOWHERE TO FLOW")
				break
			end

			if rivers[lowest_x] and rivers[lowest_x][lowest_y] then
				debug_msg("END: MERGED WITH RIVER")
				break
			end

			if valleys[lowest_x][lowest_y] then
				debug_msg("END: MERGED WITH LAKE")
				valley_to_lake(valleys,lakes,lowest_x,lowest_y)
				break
			end

			if Heightmap[lowest_x][lowest_y] < self.water_level then
				debug_msg("END: OCEAN LEVEL REACHED")
				break
			end

			dirX = lowest_x - posX
			dirY = lowest_y - posY

			if dirX ~= 0 then
				velX = dirX
			end
			if dirY ~= 0 then
				velY = dirY
			end

			posX, posY = lowest_x, lowest_y

			rivers_put(posX,posY,lowest_height)

			if lifetime == self.max_lifetime then
				debug_msg("END: RIVER LIFETIME EXCEEDED")
			end

		end
	end

	return rivers, lakes
end

return setmetatable(
	{new = object_constructor},
	{__newindex = function()
		error("RiverGenerator: Attempt to edit a read-only wrapper! Make sure that you create a new object first")
	end}
)
