-- This script is for test purposes only, it shouldn't be included in the final build.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TerrainDescriptor = require(ReplicatedStorage.ProceduralMapGenerator.TerrainDescriptor)
local TerrainBuilder = require(ReplicatedStorage.ProceduralMapGenerator.TerrainBuilder)
local Colorset = require(script.Colorset)

local width, height = 128,128

local start_init_time = tick()

local Terrain = TerrainDescriptor.new()
Terrain:Initialize()

local TerrainBuilderObj = TerrainBuilder.new()
TerrainBuilderObj.Colorset = Colorset
TerrainBuilderObj:Build(Terrain,nil,-width/2*40,-height/2*40)

print("Map has been generated in "..tostring(tick()-start_init_time).." seconds")