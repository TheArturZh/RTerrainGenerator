local PerlinNoise = require(script.PerlinNoise)
local Utils = require(script.Parent.Utils)

local HeightmapGeneratorBase = {}

--{ amplitude, frequency, exp_distr, bidirectional, warped }
local octave_settings_default = {
	 {1.0,1,true,true,true}
	,{0.5,2,true,true,true}
	,{0.3,4,true,true,true}
}

local warp_octave_settings_default = {
	 {1.000,1,true,true}
	,{0.500,2,true,true}
	,{0.250,4,true,true}
	,{0.125,8,true,true}
}

local function object_constructor()
	local object = {}
	object.octave_settings = {}
	object.warp_octave_settings = {}
	setmetatable(object,{__index = HeightmapGeneratorBase})

	return object
end

function HeightmapGeneratorBase.Generate(self,offsetX,offsetY,width,height,scale,generate_warp_map)
	local heightmap = {}

	local warp_map_x, warp_map_y

	if not generate_warp_map then
		warp_map_x = self:Generate(offsetX+260,offsetY+260,width,height,scale,true)
		warp_map_y = self:Generate(offsetX+255,offsetY+255,width,height,scale,true)
	end

	local octave_settings

	if generate_warp_map then
		octave_settings = self.warp_octave_settings
		if (not octave_settings) or #octave_settings == 0 then
			warn("No warp map octaves found, using the default ones")
			octave_settings = warp_octave_settings_default
		end
	else
		octave_settings = self.octave_settings
		if (not octave_settings) or #octave_settings == 0 then
			warn("No heightmap octaves found, using the default ones")
			octave_settings = octave_settings_default
		end
	end

	local max_noize_height = -math.huge
	local min_noize_height = math.huge

	for x = 1, width do

		heightmap[x] = {}

		for y = 1, height do

			local noise_height = 0

			for _,octave in pairs(octave_settings) do
				local amplitude = octave[1]
				local frequency = octave[2]

				local sampleX, sampleY

				if octave[5] and not generate_warp_map then
					sampleX = (x + offsetX + warp_map_x[x][y]*15) / scale * frequency
					sampleY = (y + offsetY + warp_map_y[x][y]*15) / scale * frequency
				else
					sampleX = (x + offsetX) / scale * frequency
					sampleY = (y + offsetY) / scale * frequency
				end

				local noise_val
				if octave[3] then
					noise_val = PerlinNoise.Noise2DExpDistr(sampleX,sampleY)
				else
					noise_val = PerlinNoise.Noise2D(sampleX,sampleY)
				end

				if octave[4] then
					noise_val = noise_val * 2 - 1
				end

				noise_height = noise_height + noise_val * amplitude
			end

			if noise_height > max_noize_height then
				max_noize_height = noise_height
			end
			if noise_height < min_noize_height then
				min_noize_height = noise_height
			end

			heightmap[x][y] = noise_height
		end
	end

	for x = 1,width do
		for y = 1,height do
			heightmap[x][y] = Utils.inverse_lerp(min_noize_height,max_noize_height,heightmap[x][y])
		end
	end

	return heightmap
end

return setmetatable(
	 {new = object_constructor}
	,{__newindex = function()
		error("HeightmapGenerator: Attempt to edit a read-only wrapper! Make sure that you create a new object first")
	end}
)
