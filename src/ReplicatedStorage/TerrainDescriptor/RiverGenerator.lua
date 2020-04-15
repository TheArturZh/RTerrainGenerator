local module = {}

local max_lifetime = 50
module.rivers = {}
module.lakes = {}

local function rivers_put(x,y,height)
	if not module.rivers[x] then
		module.rivers[x] = {}
	end
	module.rivers[x][y] = height
end

local function ValleyDetection(Heightmap,water_level,map_width,map_height)
	map_width  = map_width  or #Heightmap
	map_height = map_height or (Heightmap[1] and #Heightmap[1] or 0)

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

local function valley_to_lake(valleys,posX,posY)
	if not (valleys[posX] and valleys[posX][posY]) then
		error("Valley not found at position "..tonumber(posX)..", "..tonumber(posY))
	end

	local lakes = module.lakes

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

		for y = y+1,max_y do
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

local function is_rivers_nearby(x,y)
	if module.rivers[x] then
		if module.rivers[x][y+1] then
			return true
		end
		if module.rivers[x][y-1] then
			return true
		end
		if module.rivers[x][y] then
			return true
		end
	end

	if module.rivers[x+1] then
		if module.rivers[x+1][y+1] then
			return true
		end
		if module.rivers[x+1][y-1] then
			return true
		end
		if module.rivers[x+1][y] then
			return true
		end
	end

	if module.rivers[x-1] then
		if module.rivers[x-1][y+1] then
			return true
		end
		if module.rivers[x-1][y-1] then
			return true
		end
		if module.rivers[x-1][y] then
			return true
		end
	end


	return false
end

function module.Generate(Heightmap,river_amount,water_level,seed)
	local map_width  = #Heightmap
	local map_height = Heightmap[1] and #Heightmap[1] or 0

	local RandomGen = Random.new(seed or 0)

	local valleys = ValleyDetection(Heightmap,water_level)

	local function get_val_river(x,y)
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

	for river_num = 1,river_amount do

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

				if valleys[posX][posY] then
					is_empty = false
				end

				if is_rivers_nearby(posX,posY) then
					is_empty = false
				end

			until good_height and is_empty

			rivers_put(posX,posY,get_val_river(posX,posY))
		end


		local dirX,dirY = 0,0
		local velX,velY = 0,0

		for lifetime=1,max_lifetime do

			local current_val = get_val_river(posX,posY)

			if posX <= 1 or posY <= 1 or posX == map_width or posY == map_height then
				print("MAP END!")
				break
			end

			--Find next pos
			local lowest_height = math.huge
			local lowest_x
			local lowest_y

			local function check_pos(x_diff,y_diff)
				if math.abs(dirY - y_diff) <= 1 and math.abs(dirX - x_diff) <= 1 then

					local result_posX = posX + x_diff
					local result_posY = posY + y_diff
					local val = get_val_river(result_posX, result_posY)

					if val < lowest_height then
						lowest_height = val
						lowest_x = result_posX
						lowest_y = result_posY
					elseif val == lowest_height then
						if (Heightmap[lowest_x][lowest_y] > Heightmap[result_posX][result_posY]) then
							lowest_x = result_posX
							lowest_y = result_posY
						elseif (Heightmap[lowest_x][lowest_y] == Heightmap[result_posX][result_posY]) then
							if ((x_diff ~= 0 and x_diff == velX) or x_diff == 0) and ((y_diff ~= 0 and y_diff == velY) or y_diff == 0) then
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

			if lowest_height > current_val then
				print("END: NOWHERE TO FLOW")
				break
			end

			if module.rivers[lowest_x] and module.rivers[lowest_x][lowest_y] then
				print("END: MERGED WITH RIVER")
				break
			end

			if valleys[lowest_x][lowest_y] then
				print("END: MERGED WITH LAKE")
				valley_to_lake(valleys,lowest_x,lowest_y)
				break
			end

			if lowest_height < water_level then
				print("END: OCEAN LEVEL REACHED")
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

			posX,posY = lowest_x,lowest_y

			rivers_put(posX,posY,lowest_height)

			if lifetime == max_lifetime then
				print("END: RIVER LIFETIME EXCEEDED")
			end

		end
	end

	return module.rivers, module.lakes
end

function module.ApplyToHeightmap(Heightmap,depth,rivers)
	if not rivers then
		error('Error: There is no data about rivers being passed to "ApplyToHeightmap" function')
	end

	for x,row in pairs(rivers) do
		for y,height in pairs(row) do
			if Heightmap[x] and Heightmap[x][y] then
				Heightmap[x][y] = height - depth
				if Heightmap[x][y] < 0 then
					Heightmap[x][y] = 0
				end
			end
		end
	end
end


return module
