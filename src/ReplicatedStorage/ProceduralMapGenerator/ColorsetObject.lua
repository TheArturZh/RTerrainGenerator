local ColorsetBase = {}

local function object_constructor(colors,height_destribution)
	if type(colors) ~= "nil" and type(colors) ~= "table" then
		print('Failed to construct a colorset! Arg #1 "colors" should be a nil or a table!')
	end

	if type(height_destribution) ~= "nil" and type(height_destribution) ~= "table" then
		print('Failed to construct a colorset! Arg #1 "height_destribution" should be a nil or a table!')
	end

	local object = {}
	object.colors = colors or {}
	object.height_destribution = height_destribution or {}

	return setmetatable(object,{__index = ColorsetBase})
end

function ColorsetBase.pickColor(self,value)
	local lowest = 1
	for height,color in pairs(self.height_destribution) do
		if value < height and height < lowest then
			lowest = height
		end
	end

	return self.colors[self.height_destribution[lowest]]
end

return setmetatable(
	{new = object_constructor},
	{__newindex = function()
		error("Colorset: Attempt to edit a read-only wrapper! Make sure that you create a new object first")
	end}
)