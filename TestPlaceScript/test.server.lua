-- This script is for test purposes only, it shouldn't be included in the final build.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TerrainDescriptor = require(ReplicatedStorage.TerrainDescriptor)
local TerrainBuilder = require(ReplicatedStorage.TerrainBuilder)

local width, height = 128,128

local start_init_time = tick()

local Terrain = TerrainDescriptor.new()
Terrain:Initialize()

local TerrainBuilderObj = TerrainBuilder.new()
TerrainBuilderObj:Build(Terrain,nil,-width/2*40,-height/2*40)

print("Map has been generated in "..tostring(tick()-start_init_time).." seconds")