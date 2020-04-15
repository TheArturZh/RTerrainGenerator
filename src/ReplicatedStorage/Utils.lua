local module = {}

-- Returned value: Number in range 0-255 (8-bit value contained in a double)
-- Takes in a set of numbers (Amount of parameters should be >0)
function module.SimpleHash(NumSeed,...)
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

return module
