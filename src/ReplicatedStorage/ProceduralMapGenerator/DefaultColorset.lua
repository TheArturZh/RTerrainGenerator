local Colorset = require(script.Parent.ColorsetObject)

local colors = {
	 water = Color3.fromRGB(37, 149, 247)
	,sand = Color3.fromRGB(219, 218, 143)
	,grass = Color3.fromRGB(92, 156, 78)
	,grass_dark = Color3.fromRGB(75, 128, 62)
	,rock = Color3.fromRGB(120, 98, 98)
	,rock_dark = Color3.fromRGB(79, 65, 65)
	,snow = Color3.new(1,1,1)
}

local height_destribution = {
	 [0.35] = "sand"
	,[0.55] = "grass"
	,[0.6]  = "grass_dark"
	,[0.7]  = "rock"
	,[0.9]  = "rock_dark"
	,[1]    = "snow"
}

return Colorset.new(colors, height_destribution)