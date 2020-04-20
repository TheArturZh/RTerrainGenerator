local module = {}

-- Returned value: Number in range 0-255 (8-bit value contained in a double)
-- Takes in a set of numbers (Amount of parameters should be >0)
function module.simple_hash(NumSeed, ...)
	if type(NumSeed) ~= "number" then
		error("Failed to generate a hash: a seed should be a number")
	end

	local AdditionalNums = {...}

	local Displacement = 0

	for i,num in pairs(AdditionalNums) do
		Displacement = Displacement + num * i
	end
	Displacement = Displacement % 256

	local hash = bit32.rrotate(NumSeed,Displacement) % 256

	return hash
end

function module.inverse_lerp(from, to, value)
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

--[[
	Important note: vector rotates in opposite direction of the Roblox part rotation
	(negative angle should be used).
]]
function module.turn_vector2(v2, angle)
	local angle_rad = angle/180 * math.pi

	local cos = math.cos(angle_rad)
	local sin = math.sin(angle_rad)

	local x = v2.x * cos - v2.y * sin
	local y = v2.x * sin + v2.y * cos

	return Vector2.new(x,y)
end

function module.round(x)
	if x%1 >= 0.5 then
		return math.ceil(x)
	end
	return math.floor(x)
end

return module
