local module = {}

local Colorset = require(script.Parent.Colorset)
local Utils = require(script.Parent.Utils)

module.TileSide = 20
module.TileHeight = 5
module.HeightRange = 400
module.SlopeLength = 3
module.WaterSlopeLength = 3

module.HugeTileSide = 40

module.water_color = Color3.fromRGB(37, 149, 247)
module.water_level = 0.3

module.water_plane_y_offset  = -0.5
module.water_plane_thickness = 0.1

if script.Parent:FindFirstChild("Meshes") then
	module.tree_meshes = script.Parent.Meshes.Trees:GetChildren()
else
	module.tree_meshes = {}
end

local tile_height_step = 1/(module.HeightRange/module.TileHeight)

local function compare(v1,v2)
	if v2 - v1 >= (tile_height_step - 0.001) then
		return 1
	end

	return 0
end

local function HashSurroundings(Heightmap,x,y,map_width,map_height)
	local noise_val = Heightmap[x][y]
	local side_hash = 0

	--[[
	c2              c3
	        X
	<-------|--------Y
	        V
	c1              c4
	--]]
	local corner_hash = 0b0000

	if Heightmap[x - 1] then
		if Heightmap[x - 1][y] then
			side_hash = side_hash + 0b0100 * compare(noise_val,Heightmap[x-1][y])
		end

		if Heightmap[x - 1][y + 1] then
			corner_hash = corner_hash + 0b0100 * compare(noise_val,Heightmap[x-1][y+1])
		end

		if Heightmap[x - 1][y - 1] then
			corner_hash = corner_hash + 0b0010 * compare(noise_val,Heightmap[x-1][y-1])
		end
	end
	if Heightmap[x + 1] then
		if Heightmap[x + 1][y] then
			side_hash = side_hash + 0b1000 * compare(noise_val,Heightmap[x+1][y])
		end

		if Heightmap[x + 1][y + 1] then
			corner_hash = corner_hash + 0b1000 * compare(noise_val,Heightmap[x+1][y+1])
		end

		if Heightmap[x + 1][y - 1] then
			corner_hash = corner_hash + 0b0001 * compare(noise_val,Heightmap[x+1][y-1])
		end
	end

	if Heightmap[x] then
		if Heightmap[x][y - 1] then
			side_hash = side_hash + 0b0001 * compare(noise_val,Heightmap[x][y-1])
		end
		if Heightmap[x][y + 1] then
			side_hash = side_hash + 0b0010 * compare(noise_val,Heightmap[x][y+1])
		end
	end

	return side_hash, corner_hash
end

local function get_val(Heightmap,rivers,lakes,x,y)
	return (rivers[x] and rivers[x][y]) or (lakes[x] and lakes[x][y]) or ((Heightmap[x] and Heightmap[x][y] and Heightmap[x][y] < module.water_level) and module.water_level)
end

local function GetSurroundings_Water(Heightmap,rivers,lakes,x,y,map_width,map_height)
	local noise_val = rivers[x][y]
	local sides = {}

	local compare_val = get_val(Heightmap,rivers,lakes,x+1,y)
	if compare_val and compare_val - noise_val < -0.001 then
		sides[3] = noise_val-compare_val
	end

	compare_val = get_val(Heightmap,rivers,lakes,x-1,y)
	if compare_val and compare_val - noise_val < -0.001 then
		sides[1] = noise_val-compare_val
	end

	compare_val = get_val(Heightmap,rivers,lakes,x,y+1)
	if compare_val and compare_val - noise_val < -0.001 then
		sides[2] = noise_val-compare_val
	end

	compare_val = get_val(Heightmap,rivers,lakes,x,y-1)
	if compare_val and compare_val - noise_val < -0.001 then
		sides[0] = noise_val-compare_val
	end

	return sides
end

local function apply_water_visual_properties(part)
	part.Color = module.water_color
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CastShadow = false
	part.Transparency = 0.35
	part.Reflectance = 0.5
	part.Material = Enum.Material.Glass
end

local function generate_water_plane(container,level,width,height,offsetX,offsetY)
	offsetX = offsetX or 0
	offsetY = offsetY or 0

	local water_plane_group = Instance.new("Model")
	water_plane_group.Name = "WaterPlane"
	water_plane_group.Parent = container

	-- Because of 2048x2048x2048 size cap
	-- water plane should be split on parts
	local water_width = width*module.HugeTileSide
	local water_height = height*module.HugeTileSide

	local countX, countY
	--Size of the part of water plane
	local part_sizeX,part_sizeY

	countX = math.ceil(water_width/2048)
	countY = math.ceil(water_height/2048)

	part_sizeX = water_width / countX
	part_sizeY = water_height / countY

	local water_plane = Instance.new("Part")
	water_plane.Anchored = true
	water_plane.Name = "WaterPlaneSegment"
	water_plane.CanCollide = false
	water_plane.Size = Vector3.new(part_sizeX,module.water_plane_thickness,part_sizeY)
	apply_water_visual_properties(water_plane)

	for x=1,countX do
		for y=1,countY do
			local segment = water_plane:Clone()
			segment.Position = Vector3.new(part_sizeX*(x-1+0.5) - module.HugeTileSide + offsetX,(level*module.HeightRange)+module.water_plane_y_offset,part_sizeY*(y-1+0.5) - module.HugeTileSide + offsetY)
			segment.Parent = water_plane_group
		end
	end

	water_plane:Destroy()
end

function module.Build(Heightmap,rivers,lakes,trees,container,offsetX,offsetY,width,height)
	if not Heightmap then
		error("Heightmap doesn't exist!")
	end

	local RandomGen = Random.new(0)

	local offsetX = offsetX or 0
	local offsetY = offsetY or 0

	local map_width = #Heightmap
	local map_height = Heightmap[1] and #Heightmap[1] or 0

	local container = container or workspace

	-- | Optimizing large flat tiles |
	-- height = { x = {y1 = {y2,x_size}} }
	-- step1: make y-axis rows (rows should be interrupted only by tiles at lower height)
	-- step2: optimize rows into squares: merge near rows with equal y1 and y2, append x2 to each table

	-- | Test cases: |
	--The lowerst layer (at height 0) should be a whole square

	local ProcessedHeightmap = {}

	--Step 1
	for height = 0, module.HeightRange/module.TileHeight do

		ProcessedHeightmap[height] = {}

		for x = 1,map_width do

			ProcessedHeightmap[height][x] = {}
			local row_length

			for y=1,map_height do

				--Ah yes, I love comparing doubles that are expceted to be whole but in fact are fractional
				--(yep, "round" function is a MUST here)
				if Utils.round(Heightmap[x][y] / tile_height_step) >= height then

					if not row_length then
						row_length = 1
					else
						row_length = row_length + 1
					end

				elseif row_length then
					ProcessedHeightmap[height][x][y-row_length] = {y-1}

					row_length = nil
				end

				if row_length and y == map_height then
					--Row is interrupted by map edge
					ProcessedHeightmap[height][x][y-row_length+1] = {y}
				end

			end

		end
	end

	--Step 2
	for height = 0, module.HeightRange/module.TileHeight do
		for x = 1,map_width-1 do
			for y,row in pairs(ProcessedHeightmap[height][x]) do

				for x_merge = x+1, map_width do

					local next_val = ProcessedHeightmap[height][x_merge][y]

					if next_val then
						if row[1] == next_val[1] then
							row[2] = row[2] and row[2]+1 or 2
							ProcessedHeightmap[height][x_merge][y] = nil
						else
							break
						end
					else
						break
					end

				end

			end
		end
	end

	--Render huge tiles
	local count = 0

	for height = 0, module.HeightRange/module.TileHeight do
		local color = Colorset.pickColor(height*tile_height_step)
		for x = 1, map_width do
			for y,row in pairs(ProcessedHeightmap[height][x]) do

				local XSize = (row[2] or 1) * module.HugeTileSide
				local YSize = (row[1]-y+1) * module.HugeTileSide

				local XPos = (x-1) * module.HugeTileSide + XSize/2 + offsetX
				local YPos = (y-1) * module.HugeTileSide + YSize/2 + offsetY
				local HeightPos = (height-0.5)*module.TileHeight

				if XSize <= 2048 and YSize <= 2048 then
					count = count + 1
					local Tile = Instance.new("Part")
					Tile.Size = Vector3.new(XSize,module.TileHeight,YSize)
					Tile.Anchored = true
					Tile.CFrame = CFrame.new(XPos,HeightPos,YPos)
					Tile.Color = color
					Tile.Parent = container
					Tile.TopSurface = Enum.SurfaceType.Smooth
				else
					local X_Tiles = math.ceil(XSize/2048)
					local Y_Tiles = math.ceil(YSize/2048)

					local XSize = XSize / X_Tiles
					local YSize = YSize / Y_Tiles

					for x_tile = 1,X_Tiles do

						local XPos = (x-1) * module.HugeTileSide + XSize/2 + XSize * (x_tile-1) + offsetX

						for y_tile = 1,Y_Tiles do
							local YPos = (y-1) * module.HugeTileSide + YSize/2 + YSize * (y_tile-1) + offsetY
							count = count + 1
							local Tile = Instance.new("Part")
							Tile.Size = Vector3.new(XSize,module.TileHeight,YSize)
							Tile.Anchored = true
							Tile.CFrame = CFrame.new(XPos,HeightPos,YPos)
							Tile.Color = color
							Tile.Parent = container
							Tile.TopSurface = Enum.SurfaceType.Smooth

						end
					end

				end

			end
		end
	end

	local slope_count = 0

	wait()
	local wedge_parts_y = {}

	for x = 1,map_width do
		wedge_parts_y[x] = {}

		local row_hash
		local row_height
		local row_length

		for y = 1,map_height do

			local hash = HashSurroundings(Heightmap,x,y,map_width,map_height)
			hash = math.floor(hash / 0b0100)

			local height = Heightmap[x][y]

			if hash ~= 0 then
				if not row_hash then
					row_hash = hash
					row_height = height
					row_length = 1
				elseif height ~= row_height or hash ~= row_hash then
					wedge_parts_y[x][y-row_length] = {y-1,row_hash,row_height}

					row_hash = hash
					row_height = height
					row_length = 1
				else
					row_length = row_length + 1
				end
			elseif row_hash then
				wedge_parts_y[x][y-row_length] = {y-1,row_hash,row_height}

				row_hash = nil
			end

			if row_hash and y == map_height then
				wedge_parts_y[x][y-row_length+1] = {y,row_hash,row_height}
			end

		end
	end



	for x=1, map_width do
		for y,row in pairs(wedge_parts_y[x]) do

			local hash = row[2]

			slope_count = slope_count + 1

			local wedge_part = Instance.new("WedgePart")
			wedge_part.Anchored = true

			--Size
			local SizeX = module.HugeTileSide * (row[1] - y + 1)
			local SizeY = module.TileHeight
			local SizeZ = module.SlopeLength

			local SizeVector = Vector3.new(SizeX,SizeY,SizeZ)

			wedge_part.Size = SizeVector

			--Position of wedge in workspace
			local workspaceX
			local workspaceY = row[3] * module.HeightRange + module.TileHeight/2
			local workspaceZ = (y-1) * module.HugeTileSide + SizeX/2 + offsetY

			if hash == 0b10 or hash == 0b11 then
				wedge_part.Rotation = Vector3.new(0,90,0)
				workspaceX = x * module.HugeTileSide - SizeZ/2 + offsetX
			else
				wedge_part.Rotation = Vector3.new(0,-90,0)
				workspaceX = (x-1) * module.HugeTileSide + SizeZ/2 + offsetX
			end

			wedge_part.Position = Vector3.new(workspaceX,workspaceY,workspaceZ)

			wedge_part.Color = Colorset.pickColor(row[3])


			wedge_part.Parent = container

			if hash == 0b11 then
				slope_count = slope_count + 1
				local wedge_part2 = Instance.new("WedgePart")
				wedge_part2.Anchored = true
				wedge_part2.Rotation = Vector3.new(0,-90,0)
				wedge_part2.Size = SizeVector
				local workspaceX = (x-1) * module.HugeTileSide + SizeZ/2 + offsetX
				wedge_part2.Position = Vector3.new(workspaceX,workspaceY,workspaceZ)

				wedge_part2.Color = Colorset.pickColor(row[3])

				wedge_part2.Parent = container
			end

		end
	end

	wait()

	local wedge_parts_x = {}

	for y = 1,map_height do
		wedge_parts_x[y] = {}

		local row_hash
		local row_height
		local row_length

		for x = 1,map_width do

			local hash = HashSurroundings(Heightmap,x,y,map_width,map_height)
			hash = hash % 0b0100

			local height = Heightmap[x][y]

			if hash ~= 0 then
				if not row_hash then
					row_hash = hash
					row_height = height
					row_length = 1
				elseif height ~= row_height or hash ~= row_hash then
					wedge_parts_x[y][x-row_length] = {x-1,row_hash,row_height}

					row_hash = hash
					row_height = height
					row_length = 1
				else
					row_length = row_length + 1
				end
			elseif row_hash then
				wedge_parts_x[y][x-row_length] = {x-1,row_hash,row_height}

				row_hash = nil
			end

			if row_hash and x == map_width then
				wedge_parts_x[y][x-row_length+1] = {x,row_hash,row_height}
			end

		end
	end

	for y=1, map_height do
		for x,row in pairs(wedge_parts_x[y]) do

			local hash = row[2]

			slope_count = slope_count + 1

			local wedge_part = Instance.new("WedgePart")
			wedge_part.Anchored = true

			--Size
			local SizeX = module.HugeTileSide * (row[1] - x + 1)
			local SizeY = module.TileHeight
			local SizeZ = module.SlopeLength

			local SizeVector = Vector3.new(SizeX,SizeY,SizeZ)

			wedge_part.Size = SizeVector

			--Position of wedge in workspace
			local workspaceX = (x-1) * module.HugeTileSide + SizeX/2 + offsetX
			local workspaceY = row[3] * module.HeightRange + module.TileHeight/2
			local workspaceZ

			if hash == 0b10 or hash == 0b11 then
				wedge_part.Rotation = Vector3.new(0,0,0)
				workspaceZ = y * module.HugeTileSide - SizeZ/2 + offsetY
			else
				wedge_part.Rotation = Vector3.new(0,180,0)
				workspaceZ = (y-1) * module.HugeTileSide + SizeZ/2 + offsetY
			end

			wedge_part.Position = Vector3.new(workspaceX,workspaceY,workspaceZ)

			wedge_part.Color = Colorset.pickColor(row[3])

			wedge_part.Parent = container

			if hash == 0b11 then
				slope_count = slope_count + 1

				local wedge_part2 = Instance.new("WedgePart")
				wedge_part2.Anchored = true
				wedge_part2.Rotation = Vector3.new(0,180,0)
				wedge_part2.Size = SizeVector
				local workspaceZ = (y-1) * module.HugeTileSide + SizeZ/2 + offsetY
				wedge_part2.Position = Vector3.new(workspaceX,workspaceY,workspaceZ)

				wedge_part2.Color = Colorset.pickColor(row[3])

				wedge_part2.Parent = container
			end

		end
	end

	print("Count: "..tostring(count).." instead of "..tostring(map_width*map_height)..", compression rate: "..tostring( (1-(count/(map_width*map_height)))*100 ).."%")
	print("Slopes: "..tostring(slope_count)..", Total: "..tostring(slope_count + count))

	generate_water_plane(container,module.water_level,map_width,map_height,offsetX,offsetY)

	wait()
	--Generate water plane for lakes

	local generated_lake_planes = 0

	if lakes then

		for x = 1,map_width do

			if lakes[x] then
				local part_length
				local part_height_pos

				for y = 1,map_height do
					local height = lakes[x][y]

					if height then
						if not part_length then
							part_length = 1
							part_height_pos = height
						else
							part_length = part_length + 1
						end
					elseif part_length then
						generated_lake_planes = generated_lake_planes + 1
						generate_water_plane(container,part_height_pos,1,part_length,x*module.HugeTileSide+offsetX,(y-part_length)*module.HugeTileSide+offsetY)
						part_length = nil
					end

					if part_length and y == map_height then
						generated_lake_planes = generated_lake_planes + 1
						generate_water_plane(container,part_height_pos,1,part_length,x*module.HugeTileSide+offsetX,(y-part_length+1)*module.HugeTileSide+offsetY)
					end

				end
			end

		end

		print("Generated lake water planes:",generated_lake_planes)

	end


	wait()
	--Generate river water plane
	for x=1,map_width do

		if rivers[x] then
			for y=1,map_height do

				local height = rivers[x][y]
				if height then
					generate_water_plane(container,height,1,1,x*module.HugeTileSide+offsetX,y*module.HugeTileSide+offsetY)

					local sides = GetSurroundings_Water(Heightmap,rivers,lakes,x,y,map_width,map_height)

					for side,height_diff in pairs(sides) do
						local wedge_part = Instance.new("WedgePart")
						wedge_part.Anchored = true

						wedge_part.Size = Vector3.new(module.HugeTileSide,module.TileHeight,module.WaterSlopeLength)

						wedge_part.Orientation = Vector3.new(0,90*side,0)

						local workspaceX = offsetX
						local workspaceY = height * module.HeightRange - wedge_part.Size.Y/2 + module.water_plane_y_offset + module.water_plane_thickness/2
						local workspaceZ = offsetY

						if side == 0 then
							workspaceX = workspaceX + (x-0.5) * module.HugeTileSide
							workspaceZ = workspaceZ + (y-1) * module.HugeTileSide - wedge_part.Size.Z/2
						elseif side == 1 then
							workspaceX = workspaceX + (x-1) * module.HugeTileSide - wedge_part.Size.Z/2
							workspaceZ = workspaceZ + (y-0.5) * module.HugeTileSide
						elseif side == 2 then
							workspaceX = workspaceX + (x-0.5) * module.HugeTileSide
							workspaceZ = workspaceZ + (y) * module.HugeTileSide + wedge_part.Size.Z/2
						elseif side == 3 then
							workspaceX = workspaceX + (x) * module.HugeTileSide + wedge_part.Size.Z/2
							workspaceZ = workspaceZ + (y-0.5) * module.HugeTileSide
						end

						wedge_part.Position = Vector3.new(workspaceX,workspaceY,workspaceZ)

						apply_water_visual_properties(wedge_part)

						wedge_part.Parent = container

						local height_diff_step = Utils.round(height_diff/tile_height_step)

						if height_diff_step > 1 then
							local vertical = Instance.new("Part")
							vertical.Anchored = true

							vertical.Size = Vector3.new(module.HugeTileSide,module.TileHeight*(height_diff_step-1),module.WaterSlopeLength)

							vertical.Orientation = wedge_part.Orientation

							local workspaceX = wedge_part.Position.X
							local workspaceY = wedge_part.Position.Y - wedge_part.Size.Y/2 - vertical.Size.Y/2
							local workspaceZ = wedge_part.Position.Z

							vertical.Position = Vector3.new(workspaceX,workspaceY,workspaceZ)

							apply_water_visual_properties(vertical)

							vertical.Parent = container
						end

					end

				end

			end
		end

	end

	local HugeTileSizeCoeff = 2

	if type(trees) == "table" and #module.tree_meshes > 0 then

		for x,row in pairs(trees) do

			local HugeTileX = math.ceil(x/HugeTileSizeCoeff)

			for y,check in pairs(row) do

				local HugeTileY = math.ceil(y/HugeTileSizeCoeff)

				if check then

					local tree_pos = Vector3.new((x-0.5) * module.TileSide + offsetX, Heightmap[HugeTileX][HugeTileY] * module.HeightRange,(y-0.5) * module.TileSide + offsetY)

					local random_tree = RandomGen:NextInteger(1,#module.tree_meshes)

					local tree = module.tree_meshes[random_tree]:Clone()
					tree.Anchored = true

					--Random tree orientation
					local tree_angle_y = RandomGen:NextInteger(1,360)

					local new_offsets_v2 = Utils.turn_vector2(Vector2.new(tree.Position.X,tree.Position.Z),tree_angle_y)

					local new_tree_offsets = Vector3.new(
						 new_offsets_v2.X
						,tree.Position.Y
						,new_offsets_v2.Y
					)

					tree.Orientation = Vector3.new(0,-tree_angle_y,0)

					--Calculate final position
					tree.Position = new_tree_offsets + tree_pos

					tree.Parent = workspace

				end

			end
		end

	end
end

return module
