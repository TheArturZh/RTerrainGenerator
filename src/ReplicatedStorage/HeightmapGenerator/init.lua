local module = {}

local PerlinNoise = require(script.PerlinNoise)
local Utils = require(script.Parent.Utils)

--{ amplitude, frequency, exp_distr, warped, bidirectional }
local octave_settings = {
	{1,1,true,true,true},
	{0.5,2,true,true,true},
	{0.3,4,true,true,true}
}

function module.Generate(offsetX,offsetY,width,height,scale,ignore_warping)
	local heightmap = {}

	local warp_map_x, warp_map_y

	if not ignore_warping then
		warp_map_x = module.Generate(offsetX+260,offsetY+260,width,height,scale,true)
		warp_map_y = module.Generate(offsetX+255,offsetY+255,width,height,scale,true)
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

				if octave[4] and not ignore_warping then
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

				if octave[5] then
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

return module
