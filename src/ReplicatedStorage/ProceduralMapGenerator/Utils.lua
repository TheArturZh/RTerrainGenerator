--[[
	Copyright (c) 2020, Artur Zhidkov (TheArturZh)
--]]

local module = {}

--[[
	This function is from ToLua project:
	https://github.com/topameng/tolua/blob/master/Assets/ToLua/Lua/UnityEngine/Mathf.lua
	Copyright (c) 2015 - 2016, 蒙占志(topameng) topameng@gmail.com
--]]
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
	local angle_rad = math.rad(angle)

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
