-- This script is for test purposes only, it shouldn't be included in the final build.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TerrainDescriptor = require(ReplicatedStorage.TerrainDescriptor)
local TerrainBuilder = require(ReplicatedStorage.TerrainBuilder)

local width, height = 128,128

local init_time = tick()

local Terrain = TerrainDescriptor.new()
Terrain:Initialize()
TerrainBuilder.Build(Terrain.Heightmap,Terrain.rivers,Terrain.lakes,Terrain.trees,workspace,-64*40, -64*40)

print("Map has been generated in "..tostring(tick()-init_time).." seconds")