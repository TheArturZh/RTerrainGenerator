local module = {}

local HeightmapGenerator = require(script.Parent.HeightmapGenerator)
local Falloff = require(script.Falloff)
local RiverGenerator = require(script.RiverGenerator)
local Utils = require(script.Parent.Utils)

module.tile_height_step = 0.0125

module.water_level = 0.3
module.rivers = RiverGenerator.rivers
module.lakes  = RiverGenerator.lakes

module.HugeTileSizeCoeff = 2

module.trees = {}
module.forest_point_amount = 5
module.forest_point_radius = 14
module.forest_max_height   = 0.6
module.forest_base_chance  = 0.025
module.forest_deduplication_grid_scale = 32

module.FalloffDistance = 10

local function ApplyHeightmapSteps(Heightmap, step)
	local width = #Heightmap
	local height = Heightmap[1] and #Heightmap[1] or 0

	for x = 1, width do
		for y = 1, height do
			Heightmap[x][y] = Utils.round(Heightmap[x][y]/step) * step
		end
	end
end

module.InitializeTerrain = function(width, height, forests, seed)
	seed = seed or 0
	local RandomGen = Random.new(seed)

	local offsetX,offsetY

	if seed ~= 0 then
		offsetX = RandomGen:NextInteger(0,32*1024)
		offsetY = RandomGen:NextInteger(0,32*1024)
	else
		offsetX = 0
		offsetY = 0
	end

	local Heightmap = HeightmapGenerator.GenerateWithDomainWarping(offsetX,offsetY,width,height,32,4,0.5,2)

	Falloff.Apply(Heightmap,module.FalloffDistance)

	ApplyHeightmapSteps(Heightmap, module.tile_height_step)

	wait()

	RiverGenerator.Generate(Heightmap,5,module.water_level,seed)
	RiverGenerator.ApplyToHeightmap(Heightmap,module.tile_height_step*1)

	if forests then

		for x = 1,width*module.HugeTileSizeCoeff do
			module.trees[x] = {}
		end

		local forest_points = {}

		do
			local forest_grid = {}

			local forset_grid_falloff = math.ceil(module.FalloffDistance/module.forest_deduplication_grid_scale)

			for i = forset_grid_falloff, width/16 - forset_grid_falloff do
				forest_grid[i] = {}
			end

			for point = 1,module.forest_point_amount do
				local pointX, pointY

				repeat
					pointX = RandomGen:NextInteger(forset_grid_falloff, width/16 - forset_grid_falloff)
					pointY = RandomGen:NextInteger(forset_grid_falloff, height/16 - forset_grid_falloff)
				until not (forest_grid[pointX][pointY])

				forest_grid[pointX][pointY] = true
			end

			local offsetMax = module.forest_deduplication_grid_scale * module.HugeTileSizeCoeff - 1

			for pointX, row_x in pairs(forest_grid) do
				for pointY, val in pairs(row_x) do

					local offsetX = RandomGen:NextInteger(0, offsetMax)
					local offsetY = RandomGen:NextInteger(0, offsetMax)

					local finalX = pointX * module.forest_deduplication_grid_scale * module.HugeTileSizeCoeff + offsetX
					local finalY = pointY * module.forest_deduplication_grid_scale * module.HugeTileSizeCoeff + offsetY

					print(pointX,pointY,finalX,finalY)

					forest_points[#forest_points+1] = {finalX, finalY}

				end
			end
		end

		local forest_max_chance = module.forest_base_chance + 1

		wait()

		for x = 1,width*module.HugeTileSizeCoeff do

			local HugeTileX = math.ceil(x/module.HugeTileSizeCoeff)

			for y = 1,height*module.HugeTileSizeCoeff do

				local HugeTileY = math.ceil(y/module.HugeTileSizeCoeff)

				local Height = Heightmap[HugeTileX][HugeTileY]

				if Height >= module.water_level and Height > 0.35 and Height < module.forest_max_height then
					if (not (module.rivers[HugeTileX] and module.rivers[HugeTileX][HugeTileY])) and (not(module.lakes[HugeTileX] and module.lakes[HugeTileX][HugeTileY])) then

						local chance = module.forest_base_chance

						for _,point in pairs(forest_points) do
							local x_diff = math.abs(x - point[1])
							if x_diff <= (module.forest_point_radius) then

								local y_diff = math.abs(y - point[2])
								if y_diff <= (module.forest_point_radius) then

									local new_radius = math.sqrt(x_diff^2 + y_diff^2)
									local new_chance = (1 - new_radius / module.forest_point_radius + module.forest_base_chance) / forest_max_chance

									if new_chance > chance then
										chance = new_chance
									end

								end

							end
						end

						local roll = RandomGen:NextNumber(0,1)
						if roll <= chance then
							module.trees[x][y] = true
						end

					end
				end

			end
		end

	end

	return Heightmap
end

return module
