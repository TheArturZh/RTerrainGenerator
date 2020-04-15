local public = {}

local PerlinNoise = require(script.Parent.PerlinNoise)

local function InverseLerp(from, to, value)
	if from < to then
		if value < from then
			return 0
		end

		if value > to then
			return 1
		end

		value = value - from
		value = value/(to - from)
		return value
	end

	if from <= to then
		return 0
	end

	if value < to then
		return 1
	end

	if value > from then
        return 0
	end

	return 1.0 - ((value - to) / (from - to))
end

--amplitude, frequency, exp_distr, warped, bidirectional
local octave_settings = {
	{1,1,true,true,true},
	{0.5,2,true,true,true},
	{0.3,4,true,true,true},
	--{0.02,8,false,true,false}
}

function public.GenerateHeightmap(offsetX,offsetY,width,height,scale,octaves,persistance,lacunarity)
	local heightmap = {}

	local max_noize_height = -math.huge
	local min_noize_height = math.huge

	for x = 1, width do

		heightmap[x] = {}

		for y = 1, height do

			local amplitude = 1
			local frequency = 1
			local noise_height = 0

			for i=1,octaves do
				local sampleX = (x+offsetX) / scale * frequency
				local sampleY = (y+offsetY) / scale * frequency

				local noise_val = PerlinNoise.Noise2DExpDistr(sampleX,sampleY) * 2 - 1
				noise_height = noise_height + noise_val * amplitude

				amplitude = amplitude * persistance
				frequency = frequency * lacunarity
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
			heightmap[x][y] = InverseLerp(min_noize_height,max_noize_height,heightmap[x][y])
		end
	end

	return heightmap
end

function public.GenerateWithDomainWarping(offsetX,offsetY,width,height,scale,octaves,persistance,lacunarity)
	local heightmap = {}

	local fbmX = public.GenerateHeightmap(offsetX+260,offsetY+260,width,height,scale,4,persistance,lacunarity)
	local fbmY = public.GenerateHeightmap(offsetX+255,offsetY+255,width,height,scale,4,persistance,lacunarity)

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

				if octave[4] then
					sampleX = (x+offsetX+fbmX[x][y]*15) / scale * frequency
					sampleY = (y+offsetY+fbmY[x][y]*15) / scale * frequency
				else
					sampleX = (x+offsetX) / scale * frequency
					sampleY = (y+offsetY) / scale * frequency
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
			heightmap[x][y] = InverseLerp(min_noize_height,max_noize_height,heightmap[x][y])
		end
	end

	return heightmap
end

return public
