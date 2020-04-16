--[[
	This module is a decorator for all other modules that are generating a data model of the world.
]]--

local HeightmapGenerator = require(script.Parent.HeightmapGenerator)
local Falloff = require(script.Falloff)
local RiverGenerator = require(script.RiverGenerator)
local Utils = require(script.Parent.Utils)

local TerrainDescriptorBase = {
	--Default values of properties
	 tile_height_step     = 0.0125
	,huge_tile_size_coeff = 2

	,water_level          = 0.3

	,forests_enabled      = true
	,forest_point_amount  = 5
	,forest_point_radius  = 14
	,forest_max_height    = 0.6
	,forest_min_height    = 0.351
	,forest_base_chance   = 0.025
	,falloff_distance     = 10
	,forest_deduplication_grid_scale = 32

	,width  = 128
	,height = 128

	,seed = 251

	,status = "Uninitialized"

	--[[ Following will be added after initialization:
	,Heightmap = {...}
	,rivers = {...}
	,lakes  = {...}
	,trees  = {...}
	]]--
}

local object_constructor = function()
	local new_object = {}
	return setmetatable(new_object,{__index = TerrainDescriptorBase})
end
TerrainDescriptorBase.new = object_constructor

function TerrainDescriptorBase.UpdateStatus(self,string_status)
	self.status = string_status
	if string_status ~= "Initialized" then
		wait()
	end
end

local function ApplyHeightmapSteps(Heightmap, step)
	if step ~= 0 then
		local width = #Heightmap
		local height = Heightmap[1] and #Heightmap[1] or 0

		for x = 1, width do
			for y = 1, height do
				Heightmap[x][y] = math.floor(Heightmap[x][y]/step) * step
			end
		end
	end
end

local function ApplyRiversToHeightmap(Heightmap,depth,rivers)
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

TerrainDescriptorBase.Initialize = function(self)
	local seed = self.seed or 0
	local RandomGen = Random.new(seed)

	local offsetX,offsetY

	if seed ~= 0 then
		offsetX = RandomGen:NextInteger(0,32*1024)
		offsetY = RandomGen:NextInteger(0,32*1024)
	else
		offsetX = 0
		offsetY = 0
	end

	self:UpdateStatus("Generating heightmap")

	local Heightmap = HeightmapGenerator.GenerateWithDomainWarping(offsetX,offsetY,self.width,self.height,32,4,0.5,2)
	Falloff.Apply(Heightmap, self.falloff_distance)
	ApplyHeightmapSteps(Heightmap, self.tile_height_step)

	self:UpdateStatus("Generating rivers and lakes")

	local RiverGeneratorObj = RiverGenerator.new()
	RiverGeneratorObj.seed = self.seed
	RiverGeneratorObj.water_level = self.water_level

	local rivers, lakes = RiverGeneratorObj:Generate(Heightmap, 5, self.water_level, seed)
	ApplyRiversToHeightmap(Heightmap, self.tile_height_step, rivers)

	self:UpdateStatus("Generating trees")

	local trees = {}

	--what
	if self.forests_enabled then

		for x = 1, self.width * self.huge_tile_size_coeff do
			trees[x] = {}
		end

		local forest_points = {}

		do
			local forest_grid = {}

			local forest_grid_falloff = math.ceil(self.falloff_distance / self.forest_deduplication_grid_scale)

			for i = forest_grid_falloff, self.width/self.forest_deduplication_grid_scale - forest_grid_falloff do
				forest_grid[i] = {}
			end

			for point = 1, self.forest_point_amount do
				local pointX, pointY

				repeat
					pointX = RandomGen:NextInteger(forest_grid_falloff, self.width/self.forest_deduplication_grid_scale - forest_grid_falloff)
					pointY = RandomGen:NextInteger(forest_grid_falloff, self.height/self.forest_deduplication_grid_scale - forest_grid_falloff)
				until not (forest_grid[pointX][pointY])

				forest_grid[pointX][pointY] = true
			end

			local offsetMax = self.forest_deduplication_grid_scale * self.huge_tile_size_coeff - 1

			for pointX, row_x in pairs(forest_grid) do
				for pointY, val in pairs(row_x) do

					local offsetX = RandomGen:NextInteger(0, offsetMax)
					local offsetY = RandomGen:NextInteger(0, offsetMax)

					local finalX = pointX * self.forest_deduplication_grid_scale * self.huge_tile_size_coeff + offsetX
					local finalY = pointY * self.forest_deduplication_grid_scale * self.huge_tile_size_coeff + offsetY

					forest_points[#forest_points+1] = {finalX, finalY}

				end
			end
		end

		local forest_max_chance = self.forest_base_chance + 1
		local forest_min_height = self.water_level

		if self.forest_min_height > self.water_level then
			forest_min_height = self.forest_min_height
		end

		for x = 1, self.width * self.huge_tile_size_coeff do

			local HugeTileX = math.ceil(x / self.huge_tile_size_coeff)

			for y = 1, self.height * self.huge_tile_size_coeff do

				local HugeTileY = math.ceil(y / self.huge_tile_size_coeff)

				local Height = Heightmap[HugeTileX][HugeTileY]

				if Height >= self.forest_min_height and Height < self.forest_max_height then
					if (not (rivers[HugeTileX] and rivers[HugeTileX][HugeTileY])) and (not(lakes[HugeTileX] and lakes[HugeTileX][HugeTileY])) then

						local chance = self.forest_base_chance

						for _,point in pairs(forest_points) do
							local x_diff = math.abs(x - point[1])
							if x_diff <= (self.forest_point_radius) then

								local y_diff = math.abs(y - point[2])
								if y_diff <= (self.forest_point_radius) then

									local new_radius = math.sqrt(x_diff^2 + y_diff^2)
									local new_chance = (1 - new_radius / self.forest_point_radius + self.forest_base_chance) / forest_max_chance

									if new_chance > chance then
										chance = new_chance
									end

								end

							end
						end

						local roll = RandomGen:NextNumber(0,1)
						if roll <= chance then
							trees[x][y] = true
						end

					end
				end

			end
		end

	end

	self.Heightmap = Heightmap
	self.trees = trees
	self.rivers = rivers
	self.lakes = lakes

	self:UpdateStatus("Initialized")
end

return setmetatable(
	{new = object_constructor},
	{__newindex = function()
		error("TerrainDescriptor: Attempt to edit a read-only wrapper! Make sure that you create a new object first")
	end}
)
