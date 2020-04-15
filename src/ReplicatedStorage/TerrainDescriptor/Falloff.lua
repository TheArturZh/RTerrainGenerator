local module = {}

function module.Apply(Heightmap,Distance)
	local width = #Heightmap
	local height = Heightmap[1] and #Heightmap[1] or 0

	for x=1,Distance do
		local fade = (x-1)/Distance
		for y = 1,height do
			Heightmap[x][y] = Heightmap[x][y] * fade
		end
	end

	for x=width-Distance,width do
		local fade = (Distance - (x - (width-Distance))) / Distance
		for y = 1,height do
			Heightmap[x][y] = Heightmap[x][y] * fade
		end
	end

	for y=1,Distance do
		local fade = (y-1)/Distance
		for x = 1,width do
			Heightmap[x][y] = Heightmap[x][y] * fade
		end
	end

	for y=height-Distance,height do
		local fade = (Distance - (y - (height-Distance))) / Distance
		for x = 1,width do
			Heightmap[x][y] = Heightmap[x][y] * fade
		end
	end
end

return module
