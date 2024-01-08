--[[
    LatencyLens - World of Warcraft Addon
    Author: Joshua Russell (Kkthnx)
    Copyright (c) 2023 Joshua Russell

    This addon, "LatencyLens," is developed and maintained by Joshua Russell, also known as Kkthnx.
    It provides real-time insights into game performance, displaying FPS, network latency, and memory usage of addons.

    All rights reserved. Redistribution and use in source and binary forms, with or without modification,
    are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice,
       this list of conditions, and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice,
       this list of conditions, and the following disclaimer in the documentation
       and/or other materials provided with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
    INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
    IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
    OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
    OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
    EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

local L = LatencyLensLocalization

-- WoW API Functions
local GetNumAddOns, GetAddOnInfo, IsAddOnLoaded = C_AddOns.GetNumAddOns or GetNumAddOns, C_AddOns.GetAddOnInfo or GetAddOnInfo, C_AddOns.IsAddOnLoaded or IsAddOnLoaded
local GetAddOnMemoryUsage, UpdateAddOnMemoryUsage = GetAddOnMemoryUsage, UpdateAddOnMemoryUsage
local GetNetStats, GetFramerate = GetNetStats, GetFramerate
local GetTime = GetTime

-- Lua Standard Function
local format, floor, min = string.format, math.floor, math.min
local ipairs, table_insert, table_sort = ipairs, table.insert, table.sort

-- Example (replace with actual constants or variables you use)
local MAX_ADDONS_DISPLAYED = 8

-- Garbage Collection and Debugging
local collectgarbage, gcinfo = collectgarbage, gcinfo

-- Utility Functions
local function formatMemory(value)
	return value > 1024 and format("%.1f MB", value / 1024) or format("%.0f KB", value)
end

local function GetPerformanceColor(value, isLatency)
	-- Define thresholds for latency and FPS
	local thresholds = isLatency and { 60, 120, 180, 250 } or { 10, 15, 30, 60 }
	local colors = { "|cff00ff00", "|cffffff00", "|cffff8000", "|cffff0000" }

	-- Iterate through the thresholds and return the corresponding color
	for i, threshold in ipairs(thresholds) do
		if (isLatency and value <= threshold) or (not isLatency and value >= threshold) then
			return colors[i]
		end
	end
	return colors[#colors] -- Default color if no thresholds are met
end

-- Create the main frame
local frame = CreateFrame("Frame", "LatencyFPSFrame", UIParent)
frame:SetPoint("CENTER")
frame:SetSize(100, 30)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

-- Initialize default values for frame fields
-- This is necessary to prevent nil value errors when these fields are accessed
-- before they are set by their respective update functions. It ensures that the frame
-- always has valid data to work with, enhancing the addon's stability and reliability.
frame.fps = 0 -- Default value for FPS
frame.lagHome = 0 -- Default value for home latency
frame.lagWorld = 0 -- Default value for world latency

-- Create a font string for the frame
frame.text = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
frame.text:SetPoint("CENTER")

-- Update Functions
local function UpdateLatencyFPS()
	local _, _, lagHome, lagWorld = GetNetStats()
	local fps = floor(GetFramerate())
	local fpsColor = GetPerformanceColor(fps, false) -- For FPS
	local latencyColor = GetPerformanceColor(lagHome, true) -- For Latency
	frame.text:SetText(fpsColor .. fps .. "|rfps - " .. latencyColor .. lagHome .. "|rms")
	frame.lagHome = lagHome
	frame.lagWorld = lagWorld
	frame.fps = fps
end

-- Throttling for Memory Usage Update
local lastUpdate = 0
local updateInterval = 10

local function UpdateAddonMemoryUsage()
	if InCombatLockdown() or (GetTime() - lastUpdate < updateInterval) then
		return -- Do nothing if in combat or if the interval hasn't passed
	end
	UpdateAddOnMemoryUsage()
	lastUpdate = GetTime()
end

-- Cache Addon Names
local cachedAddonNames = {}
for i = 1, GetNumAddOns() do
	cachedAddonNames[i] = GetAddOnInfo(i)
end

-- Get Top Addons by Memory Usage
local function GetTopAddons()
	UpdateAddonMemoryUsage()
	local addonUsage = {}

	for i, name in ipairs(cachedAddonNames) do
		if IsAddOnLoaded(i) then
			table_insert(addonUsage, { name = name, usage = GetAddOnMemoryUsage(i) })
		end
	end

	table_sort(addonUsage, function(a, b)
		return a.usage > b.usage
	end)
	return addonUsage
end

-- Tooltip Update Function
local TooltipOnEnter = false
local function UpdateTooltip(self)
	GameTooltip:SetOwner(self, "ANCHOR_TOP")
	GameTooltip:ClearLines()

	-- Add FPS and Latency lines
	GameTooltip:AddLine(L["FPS"] .. self.fps)
	GameTooltip:AddLine(L["HOME_LATENCY"] .. self.lagHome .. "ms")
	GameTooltip:AddLine(L["WORLD_LATENCY"] .. self.lagWorld .. "ms")

	if IsLeftShiftKeyDown() then
		-- Additional details for memory usage
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["TOP_ADDONS_BY_MEMORY"])
		for i, addon in ipairs(GetTopAddons()) do
			if i > MAX_ADDONS_DISPLAYED then
				break
			end
			local usageStr = formatMemory(addon.usage)
			GameTooltip:AddLine(string.format("|cff00ddff%d.|r %s - |cffffd700%s|r", i, addon.name, usageStr))
		end
	else
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(L["PRESS_SHIFT"])
	end

	GameTooltip:Show()
end

-- Event Handlers
frame:SetScript("OnEnter", function(self)
	if InCombatLockdown() then
		return -- Do nothing if in combat
	end
	TooltipOnEnter = true
	UpdateTooltip(self)
end)

frame:SetScript("OnLeave", function()
	TooltipOnEnter = false
	GameTooltip:Hide()
end)

frame:SetScript("OnUpdate", function(self, elapsed)
	if TooltipOnEnter then
		UpdateTooltip(self)
	end

	self.timeSinceLastUpdate = (self.timeSinceLastUpdate or 0) + elapsed
	if self.timeSinceLastUpdate >= 3.0 then
		UpdateLatencyFPS()
		self.timeSinceLastUpdate = 0
	end
end)

-- Cooldown variables
local lastClickTime = 0
local clickCooldown = 10 -- Cooldown in seconds

frame:SetScript("OnMouseUp", function(self, btn)
	local currentTime = GetTime()
	if btn == "LeftButton" then
		if currentTime - lastClickTime < clickCooldown then
			print(L["WAIT_BEFORE_COLLECTING"])
			return
		end

		lastClickTime = currentTime
		local before = gcinfo()
		collectgarbage("collect")
		print(format(L["MEMORY_COLLECTED"], formatMemory(before - gcinfo())))
		UpdateTooltip(self)
	end
end)
