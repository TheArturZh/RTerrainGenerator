local module = {}

module.colors = {
	 water = Color3.fromRGB(37, 149, 247)
	,sand = Color3.fromRGB(219, 218, 143)
	,grass = Color3.fromRGB(92, 156, 78)
	,grass_dark = Color3.fromRGB(75, 128, 62)
	,rock = Color3.fromRGB(120, 98, 98)
	,rock_dark = Color3.fromRGB(79, 65, 65)
	,snow = Color3.new(1,1,1)
}

module.height_destribution = {
	 [0.35] = module.colors.sand
	,[0.55] = module.colors.grass
	,[0.6]  = module.colors.grass_dark
	,[0.7]  = module.colors.rock
	,[0.9]  = module.colors.rock_dark
	,[1]    = module.colors.snow
}

function module.pickColor(value)
	local lowest = 1
	for height,color in pairs(module.height_destribution) do
		if value < height and height < lowest then
			lowest = height
		end
	end

	return module.height_destribution[lowest]
end

return module