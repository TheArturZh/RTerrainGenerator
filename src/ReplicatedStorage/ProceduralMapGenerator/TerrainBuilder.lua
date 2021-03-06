local DefaultColorset = require(script.Parent.DefaultColorset)
local Utils = require(script.Parent.Utils)

local TerrainBuilderBase = {
	 TileSide = 20
	,HugeTileSide = 40
	,TileHeight = 5
	,HeightRange = 400

	,SlopeLength = 3
	,WaterSlopeLength = 3
	,SlopesEnabled = true

	,water_plane_y_offset  = -0.5
	,water_plane_thickness = 0.1

	,TreesEnabled = true

	,Colorset = DefaultColorset
	,status = "Idle"
}

local object_constructor = function()
	local object = {}

	return setmetatable(object, {__index = TerrainBuilderBase})
end

local function compare(v1,v2)
	--should'nt be compared directly because of the way doubles behave
	if v2 - v1 >= 0.001 then
		return 1
	end

	return 0
end

local function HashSurroundings(Heightmap,x,y)
	local noise_val = Heightmap[x][y]
	local side_hash = 0

	--[[
	c2         s2      c3
  	           X
	s3 <-------|--------Y s4
	           V
	c1         s1      c4
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

local function GetSurroundings_Water(TerrainDescriptor,x,y)
	local noise_val = TerrainDescriptor.rivers[x][y]
	local sides = {}

	local compare_val = TerrainDescriptor:get_water_surface_level(x+1,y)
	if compare_val and compare_val - noise_val < -0.001 then
		sides[3] = noise_val-compare_val
	end

	compare_val = TerrainDescriptor:get_water_surface_level(x-1,y)
	if compare_val and compare_val - noise_val < -0.001 then
		sides[1] = noise_val-compare_val
	end

	compare_val = TerrainDescriptor:get_water_surface_level(x,y+1)
	if compare_val and compare_val - noise_val < -0.001 then
		sides[2] = noise_val-compare_val
	end

	compare_val = TerrainDescriptor:get_water_surface_level(x,y-1)
	if compare_val and compare_val - noise_val < -0.001 then
		sides[0] = noise_val-compare_val
	end

	return sides
end

function TerrainBuilderBase.apply_water_visual_properties(self,part)
	if self.Colorset.colors.water then
		part.Color = self.Colorset.colors.water
	else
		part.Color = DefaultColorset.colors.water
	end

	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CastShadow = false
	part.Transparency = 0.35
	part.Reflectance = 0.5
	part.Material = Enum.Material.Glass
end

function TerrainBuilderBase.apply_water_properties(self,part)
	self:apply_water_visual_properties(part)

	part.CanCollide = false
	part.Anchored = true
end

function TerrainBuilderBase.generate_water_plane(self,container,level,width,height,offsetX,offsetY)
	offsetX = offsetX or 0
	offsetY = offsetY or 0

	local water_plane_group = Instance.new("Model")
	water_plane_group.Name = "WaterPlane"
	water_plane_group.Parent = container

	-- Because of 2048x2048x2048 size cap
	-- water plane should be split on parts
	local water_width = width * self.HugeTileSide
	local water_height = height * self.HugeTileSide

	local countX, countY
	--Size of the part of water plane
	local part_sizeX,part_sizeY

	countX = math.ceil(water_width/2048)
	countY = math.ceil(water_height/2048)

	part_sizeX = water_width / countX
	part_sizeY = water_height / countY

	local water_plane = Instance.new("Part")
	water_plane.Name = "WaterPlaneSegment"
	water_plane.Size = Vector3.new(part_sizeX, self.water_plane_thickness, part_sizeY)

	self:apply_water_properties(water_plane)

	local posY = level * self.HeightRange + self.water_plane_y_offset

	for x=1,countX do
		for y=1,countY do
			local posX = part_sizeX * (x-0.5) - self.HugeTileSide + offsetX
			local posZ = part_sizeY * (y-0.5) - self.HugeTileSide + offsetY

			local segment = water_plane:Clone()
			segment.Position = Vector3.new(posX, posY, posZ)
			segment.Parent = water_plane_group
		end
	end

	water_plane:Destroy()
end

function TerrainBuilderBase.UpdateStatus(self,string_status)
	self.status = string_status
	if string_status ~= "Idle (Finished)" and string_status ~= "Idle" then
		wait()
	end
end

-- self,Heightmap,rivers,lakes,trees,container,offsetX,offsetY,width,height
function TerrainBuilderBase.Build(self,TerrainDescriptor,container,offsetX,offsetY)
	if TerrainDescriptor.status ~= "Initialized" then
		error("Failed to build a map: TerrainDescriptor isn't initialized!")
	end

	if not rawget(self, "Colorset") then
		print("No custom colorset passed, going to use a default one")
	elseif not self.Colorset.colors.water then
		warn("No water color specified in current colorset, going to use a default one (color)")
	end

	if not container then
		warn("No world container specified, creating one in game.Workspace")
		container = Instance.new("Model")
		container.Name = "World"
		container.Parent = workspace
	end

	local tile_height_step = 1 / (self.HeightRange / self.TileHeight)

	local RandomGen = Random.new(0)

	local offsetX = offsetX or 0
	local offsetY = offsetY or 0

	local Heightmap = TerrainDescriptor.Heightmap
	local lakes = TerrainDescriptor.lakes
	local rivers = TerrainDescriptor.rivers
	local trees = TerrainDescriptor.trees

	local water_level = TerrainDescriptor.water_level

	local map_width = TerrainDescriptor.width
	local map_height = TerrainDescriptor.height

	-- | Optimizing large flat tiles |
	-- height = { x = {y1 = {y2,x_size}} }
	-- step1: make y-axis rows (rows should be interrupted only by tiles at lower height)
	-- step2: optimize rows into squares: merge near rows with equal y1 and y2, append x2 to each table

	-- | Test cases: |
	--The lowerst layer (at height 0) should be a whole square

	self:UpdateStatus("Building huge tiles")

	local ProcessedHeightmap = {}

	--Step 1
	for height = 0, self.HeightRange / self.TileHeight do

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
	for height = 0, self.HeightRange / self.TileHeight do
		for x = 1, map_width-1 do
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

	--Build huge tiles
	local count = 0

	for height = 0, self.HeightRange / self.TileHeight do
		local picked_color = self.Colorset:pickColor(height * tile_height_step)
		for x = 1, map_width do
			for y,row in pairs(ProcessedHeightmap[height][x]) do

				local XSize = (row[2] or 1) * self.HugeTileSide
				local YSize = (row[1]-y+1) * self.HugeTileSide

				local HeightPos = (height - 0.5) * self.TileHeight

				local X_Tiles = math.ceil(XSize/2048)
				local Y_Tiles = math.ceil(YSize/2048)

				XSize = XSize / X_Tiles
				YSize = YSize / Y_Tiles

				for x_tile = 1, X_Tiles do

					local XPos = (x-1) * self.HugeTileSide + XSize/2 + XSize * (x_tile-1) + offsetX

					for y_tile = 1,Y_Tiles do
						count = count + 1
						local YPos = (y-1) * self.HugeTileSide + YSize/2 + YSize * (y_tile-1) + offsetY

						local Tile = Instance.new("Part")
						Tile.Size = Vector3.new(XSize,self.TileHeight,YSize)
						Tile.Anchored = true
						Tile.CFrame = CFrame.new(XPos,HeightPos,YPos)
						Tile.Color = picked_color
						Tile.Parent = container
						Tile.TopSurface = Enum.SurfaceType.Smooth
					end
				end

			end
		end
	end

	print("Count: "..tostring(count).." instead of "..tostring(map_width*map_height)..", compression rate: "..tostring( (1-(count/(map_width*map_height)))*100 ).."%")

	if self.SlopesEnabled then
		local slope_count = 0

		self:UpdateStatus("Building slopes 1/2")
		local wedge_parts_y = {}

		for x = 1, map_width do
			wedge_parts_y[x] = {}

			local row_hash
			local row_height
			local row_length

			for y = 1, map_height do

				local hash = HashSurroundings(Heightmap,x,y)
				hash = math.floor(hash / 0b0100)

				local height = Heightmap[x][y]

				if hash ~= 0 then
					if not row_hash then
						row_hash = hash
						row_height = height
						row_length = 1
					elseif height ~= row_height or hash ~= row_hash then
						wedge_parts_y[x][y-row_length] = {y-1, row_hash, row_height}

						row_hash = hash
						row_height = height
						row_length = 1
					else
						row_length = row_length + 1
					end
				elseif row_hash then
					wedge_parts_y[x][y-row_length] = {y-1, row_hash, row_height}

					row_hash = nil
				end

				if row_hash and y == map_height then
					wedge_parts_y[x][y-row_length+1] = {y, row_hash, row_height}
				end

			end
		end


		for x=1, map_width do
			for y,row in pairs(wedge_parts_y[x]) do

				slope_count = slope_count + 1
				local picked_color = self.Colorset:pickColor(row[3])
				local hash = row[2]

				--Size
				local SizeX = self.HugeTileSide * (row[1] - y + 1)
				local SizeY = self.TileHeight
				local SizeZ = self.SlopeLength

				local SizeVector = Vector3.new(SizeX, SizeY, SizeZ)

				--Position of wedge in workspace
				local workspaceX
				local workspaceY = row[3] * self.HeightRange + self.TileHeight/2
				local workspaceZ = (y-1) * self.HugeTileSide + SizeX/2 + offsetY

				local wedge_part = Instance.new("WedgePart")
				wedge_part.Anchored = true
				wedge_part.Size = SizeVector

				if hash == 0b10 or hash == 0b11 then
					wedge_part.Rotation = Vector3.new(0,90,0)
					workspaceX = x * self.HugeTileSide - SizeZ/2 + offsetX
				else
					wedge_part.Rotation = Vector3.new(0,-90,0)
					workspaceX = (x-1) * self.HugeTileSide + SizeZ/2 + offsetX
				end

				wedge_part.Position = Vector3.new(workspaceX,workspaceY,workspaceZ)
				wedge_part.Color = picked_color
				wedge_part.Parent = container

				if hash == 0b11 then
					slope_count = slope_count + 1

					local wedge_part2 = Instance.new("WedgePart")
					wedge_part2.Anchored = true
					wedge_part2.Rotation = Vector3.new(0,-90,0)
					wedge_part2.Size = SizeVector
					local workspaceX = (x-1) * self.HugeTileSide + SizeZ/2 + offsetX
					wedge_part2.Position = Vector3.new(workspaceX,workspaceY,workspaceZ)
					wedge_part2.Color = picked_color
					wedge_part2.Parent = container
				end

			end
		end

		self:UpdateStatus("Building slopes 2/2")

		local wedge_parts_x = {}

		for y = 1,map_height do
			wedge_parts_x[y] = {}

			local row_hash
			local row_height
			local row_length

			for x = 1,map_width do

				local hash = HashSurroundings(Heightmap,x,y)
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

				--Size
				local SizeX = self.HugeTileSide * (row[1] - x + 1)
				local SizeY = self.TileHeight
				local SizeZ = self.SlopeLength
				local SizeVector = Vector3.new(SizeX,SizeY,SizeZ)

				--Position of wedge in workspace
				local workspaceX = (x-1) * self.HugeTileSide + SizeX/2 + offsetX
				local workspaceY = row[3] * self.HeightRange + self.TileHeight/2
				local workspaceZ

				local wedge_part = Instance.new("WedgePart")

				if hash == 0b10 or hash == 0b11 then
					wedge_part.Rotation = Vector3.new(0,0,0)
					workspaceZ = y * self.HugeTileSide - SizeZ/2 + offsetY
				else
					wedge_part.Rotation = Vector3.new(0,180,0)
					workspaceZ = (y-1) * self.HugeTileSide + SizeZ/2 + offsetY
				end

				wedge_part.Anchored = true
				wedge_part.Position = Vector3.new(workspaceX,workspaceY,workspaceZ)
				wedge_part.Color = self.Colorset:pickColor(row[3])
				wedge_part.Size = SizeVector
				wedge_part.Parent = container

				if hash == 0b11 then
					slope_count = slope_count + 1

					local workspaceZ = (y-1) * self.HugeTileSide + SizeZ/2 + offsetY

					local wedge_part2 = Instance.new("WedgePart")
					wedge_part2.Anchored = true
					wedge_part2.Rotation = Vector3.new(0,180,0)
					wedge_part2.Size = SizeVector
					wedge_part2.Position = Vector3.new(workspaceX,workspaceY,workspaceZ)
					wedge_part2.Color = self.Colorset:pickColor(row[3])
					wedge_part2.Parent = container
				end

			end

		end

		print("Slopes: "..tostring(slope_count)..", Total: "..tostring(slope_count + count))
	end

	self:generate_water_plane(container,water_level,map_width,map_height,offsetX,offsetY)

	self:UpdateStatus("Creating lakes")
	--Generate water plane for lakes

	local generated_lake_planes = 0

	if lakes then

		for x = 1,map_width do

			if lakes[x] then
				local part_length
				local part_height_pos

				local posX = x * self.HugeTileSide + offsetX

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

						local posY = (y-part_length) * self.HugeTileSide + offsetY
						self:generate_water_plane(container,part_height_pos,1,part_length,posX,posY)

						part_length = nil
					end

					if part_length and y == map_height then
						generated_lake_planes = generated_lake_planes + 1

						local posY = (y-part_length+1) * self.HugeTileSide + offsetY
						self:generate_water_plane(container,part_height_pos,1,part_length,posX,posY)
					end

				end
			end

		end

		print("Generated lake water planes:",generated_lake_planes)

	end


	self:UpdateStatus("Creating rivers")
	--Generate river water plane
	for x=1, map_width do
		if rivers[x] then
			for y=1, map_height do

				local height = rivers[x][y]

				if height and height - water_level > 0.001 then
					self:generate_water_plane(container,height,1,1,x*self.HugeTileSide+offsetX,y*self.HugeTileSide+offsetY)

					local sides = GetSurroundings_Water(TerrainDescriptor,x,y)

					for side,height_diff in pairs(sides) do
						local wedge_part = Instance.new("WedgePart")
						wedge_part.Anchored = true
						wedge_part.Size = Vector3.new(self.HugeTileSide, self.TileHeight, self.WaterSlopeLength)
						wedge_part.Orientation = Vector3.new(0,90*side,0)

						local workspaceX = offsetX
						local workspaceY = height * self.HeightRange - wedge_part.Size.Y/2 + self.water_plane_y_offset + self.water_plane_thickness/2
						local workspaceZ = offsetY

						if side == 0 then
							workspaceX = workspaceX + (x-0.5) * self.HugeTileSide
							workspaceZ = workspaceZ + (y-1) * self.HugeTileSide - wedge_part.Size.Z/2
						elseif side == 1 then
							workspaceX = workspaceX + (x-1) * self.HugeTileSide - wedge_part.Size.Z/2
							workspaceZ = workspaceZ + (y-0.5) * self.HugeTileSide
						elseif side == 2 then
							workspaceX = workspaceX + (x-0.5) * self.HugeTileSide
							workspaceZ = workspaceZ + (y) * self.HugeTileSide + wedge_part.Size.Z/2
						elseif side == 3 then
							workspaceX = workspaceX + (x) * self.HugeTileSide + wedge_part.Size.Z/2
							workspaceZ = workspaceZ + (y-0.5) * self.HugeTileSide
						end

						wedge_part.Position = Vector3.new(workspaceX, workspaceY, workspaceZ)
						wedge_part.CanCollide = false

						self:apply_water_properties(wedge_part)

						wedge_part.Parent = container

						local height_diff_step = Utils.round(height_diff / tile_height_step)

						if height_diff_step > 1 then
							local vertical = Instance.new("Part")
							vertical.Anchored = true
							vertical.Size = Vector3.new(self.HugeTileSide, self.TileHeight*(height_diff_step-1), self.WaterSlopeLength)
							vertical.Orientation = wedge_part.Orientation

							local workspaceX = wedge_part.Position.X
							local workspaceY = wedge_part.Position.Y - wedge_part.Size.Y/2 - vertical.Size.Y/2
							local workspaceZ = wedge_part.Position.Z

							vertical.Position = Vector3.new(workspaceX, workspaceY, workspaceZ)

							self:apply_water_properties(vertical)

							vertical.CanCollide = false
							vertical.Parent = container
						end
					end
				end
			end
		end
	end

	local HugeTileSizeCoeff = 2

	if self.TreesEnabled then
		self:UpdateStatus("Creating trees")
		--Get tree meshes
		local tree_meshes = self.tree_meshes

		if not tree_meshes then
			if script.Parent:FindFirstChild("Meshes") then
				tree_meshes = script.Parent.Meshes.Trees:GetChildren()
			else
				tree_meshes = {}
			end
		end

		if #tree_meshes == 0 then
			warn("No tree meshes found! Trees will not be generated.")
		end

		if type(trees) == "table" and #tree_meshes > 0 then
			for x,row in pairs(trees) do
				local HugeTileX = math.ceil(x / HugeTileSizeCoeff)

				for y,check in pairs(row) do
					local HugeTileY = math.ceil(y / HugeTileSizeCoeff)

					if check then

						local tree_posX = (x-0.5) * self.TileSide + offsetX
						local tree_posY = Heightmap[HugeTileX][HugeTileY] * self.HeightRange
						local tree_posZ = (y-0.5) * self.TileSide + offsetY

						local tree_pos_vec = Vector3.new(tree_posX, tree_posY, tree_posZ)

						local random_tree = RandomGen:NextInteger(1,#tree_meshes)
						local tree = tree_meshes[random_tree]:Clone()

						--Random tree orientation
						local tree_angle_y = RandomGen:NextInteger(1,360)
						local new_offsets_v2 = Utils.turn_vector2(Vector2.new(tree.Position.X,tree.Position.Z), tree_angle_y)
						local new_tree_offsets = Vector3.new(
							new_offsets_v2.X
							,tree.Position.Y
							,new_offsets_v2.Y
						)

						tree.Orientation = Vector3.new(0,-tree_angle_y,0)
						tree.Position = new_tree_offsets + tree_pos_vec
						tree.Anchored = true
						tree.Parent = workspace

					end

				end
			end
		end
	end

	self:UpdateStatus("Idle (Finished)")

	return container
end

return setmetatable(
	{new = object_constructor},
	{__newindex = function()
		error("TerrainBuilder: Attempt to edit a read-only wrapper! Make sure that you create a new object first")
	end}
)