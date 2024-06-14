-- Global variables
local addonName, latencyLens = ...
local L = latencyLens.L

-- Lua functions
local format, floor, min, max = format, floor, min, max
local ipairs, tinsert, wipe, sort = ipairs, tinsert, wipe, sort

-- WoW API functions
local GetAvailableBandwidth, GetDownloadedPercentage = GetAvailableBandwidth, GetDownloadedPercentage
local GetCVarBool, SetCVar = GetCVarBool, SetCVar
local GetFileStreamingStatus, GetBackgroundLoadingStatus = GetFileStreamingStatus, GetBackgroundLoadingStatus
local GetFramerate, GetTime = GetFramerate, GetTime
local GetNetStats, GetNetIpTypes = GetNetStats, GetNetIpTypes
local IsAddOnLoaded = C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
local GetNumAddOns = C_AddOns and C_AddOns.GetNumAddOns or GetNumAddOns
local GetAddOnInfo = C_AddOns and C_AddOns.GetAddOnInfo or GetAddOnInfo
local IsShiftKeyDown = IsShiftKeyDown
local ResetCPUUsage, collectgarbage, gcinfo = ResetCPUUsage, collectgarbage, gcinfo
local UpdateAddOnCPUUsage, GetAddOnCPUUsage = UpdateAddOnCPUUsage, GetAddOnCPUUsage
local UpdateAddOnMemoryUsage, GetAddOnMemoryUsage = UpdateAddOnMemoryUsage, GetAddOnMemoryUsage

-- Constants
local UNKNOWN = UNKNOWN
local enableString = "|cff55ff55" .. VIDEO_OPTIONS_ENABLED
local disableString = "|cffff5555" .. VIDEO_OPTIONS_DISABLED
local scriptProfileStatus = GetCVarBool("scriptProfile")

-- Callback variables
local classColorText, noLabel, enableStats = nil, nil, nil

-- Tooltip related variables
local infoTable = {}
local ipTypes = { "IPv4", "IPv6" }
local showMoreString = "%d %s (%s)"
local usageString = "%.3f ms"

-- Frame and other UI elements
local statsFrame
local enteredFrame = false

latencyLens:RegisterOptionCallback("classColorText", function(value)
	classColorText = value
end)

latencyLens:RegisterOptionCallback("noLabel", function(value)
	noLabel = value
end)

latencyLens:RegisterOptionCallback("enableStats", function(value)
	enableStats = value

	if enableStats then
		latencyLens:OnLogin() -- Ensure statsFrame is initialized if enabled
	else
		-- Disable stats display
		if statsFrame then
			statsFrame:Hide()
			-- Clean up scripts if necessary
			statsFrame:SetScript("OnEnter", nil)
			statsFrame:SetScript("OnLeave", nil)
			statsFrame:SetScript("OnUpdate", nil)
			statsFrame:SetScript("OnMouseUp", nil)
			statsFrame:SetScript("OnDragStart", nil)
			statsFrame:SetScript("OnDragStop", nil)
		end
	end
end)

local function buildAddonList()
	local numAddons = GetNumAddOns()
	if numAddons == #infoTable then
		return
	end

	wipe(infoTable)
	for i = 1, numAddons do
		local _, title, _, loadable = GetAddOnInfo(i)
		if loadable then
			tinsert(infoTable, { i, title, 0, 0 })
		end
	end
end

local function updateMemory()
	UpdateAddOnMemoryUsage()

	local total = 0
	for _, data in ipairs(infoTable) do
		if IsAddOnLoaded(data[1]) then
			local mem = GetAddOnMemoryUsage(data[1])
			data[3] = mem
			total = total + mem
		end
	end
	sort(infoTable, latencyLens.sortByMemory)

	return total
end

local function updateCPU()
	UpdateAddOnCPUUsage()

	local total = 0
	for _, data in ipairs(infoTable) do
		if IsAddOnLoaded(data[1]) then
			local addonCPU = GetAddOnCPUUsage(data[1])
			data[4] = addonCPU
			total = total + addonCPU
		end
	end
	sort(infoTable, latencyLens.sortByCPU)

	return total
end

local classColor = RAID_CLASS_COLORS[select(2, UnitClass("player"))]
local function colorFPS(fps)
	if classColorText then
		return format("|cff%02x%02x%02x%d|r", classColor.r * 255, classColor.g * 255, classColor.b * 255, fps)
	else
		if fps < 15 then
			return "|cffD80909" .. fps
		elseif fps < 30 then
			return "|cffE8DA0F" .. fps
		else
			return "|cff0CD809" .. fps
		end
	end
end

local function colorLatency(latency)
	if classColorText then
		return format("|cff%02x%02x%02x%d|r", classColor.r * 255, classColor.g * 255, classColor.b * 255, latency)
	else
		if latency < 250 then
			return "|cff0CD809" .. latency
		elseif latency < 500 then
			return "|cffE8DA0F" .. latency
		else
			return "|cffD80909" .. latency
		end
	end
end

local function setFrameRateAndLatency(self)
	local fps = floor(GetFramerate())
	local _, _, latencyHome, latencyWorld = GetNetStats()
	local latency = max(latencyHome, latencyWorld)

	if noLabel then
		self.text:SetText(colorFPS(fps) .. " / " .. colorLatency(latency))
	else
		self.text:SetText(L["Fps"] .. ": " .. colorFPS(fps) .. " |r " .. L["Ms"] .. ": " .. colorLatency(latency) .. "|r")
	end
end

local function onEnter(self)
	enteredFrame = true

	if not next(infoTable) then
		buildAddonList()
	end
	local isShiftKeyDown = IsShiftKeyDown()
	local maxAddOns = 10
	local maxShown = isShiftKeyDown and #infoTable or min(maxAddOns, #infoTable)

	local _, anchor, offset = latencyLens:GetTooltipAnchor(self)
	GameTooltip:SetOwner(self, "ANCHOR_" .. anchor, 0, offset)
	GameTooltip:ClearLines()
	GameTooltip:AddLine(addonName, 0.1, 0.6, 0.6)
	GameTooltip:AddLine(" ")

	local _, _, latencyHome, latencyWorld = GetNetStats()
	GameTooltip:AddDoubleLine(L["Home Latency"], colorLatency(latencyHome) .. "|r ms", 0.5, 0.8, 0.8, 1, 1, 1)
	GameTooltip:AddDoubleLine(L["World Latency"], colorLatency(latencyWorld) .. "|r ms", 0.5, 0.8, 0.8, 1, 1, 1)

	if GetCVarBool("useIPv6") then
		local ipTypeHome, ipTypeWorld = GetNetIpTypes()
		GameTooltip:AddLine(" ")
		GameTooltip:AddDoubleLine(L["Home Protocol"], ipTypes[ipTypeHome or 0] or UNKNOWN, 0.5, 0.8, 0.8, 1, 1, 1)
		GameTooltip:AddDoubleLine(L["World Protocol"], ipTypes[ipTypeWorld or 0] or UNKNOWN, 0.5, 0.8, 0.8, 1, 1, 1)
	end

	local downloading = GetFileStreamingStatus() ~= 0 or GetBackgroundLoadingStatus() ~= 0
	if downloading then
		GameTooltip:AddLine(" ")
		GameTooltip:AddDoubleLine(L["Bandwidth"], format("%.2f Mbps", GetAvailableBandwidth()), 0.5, 0.8, 0.8, 1, 1, 1)
		GameTooltip:AddDoubleLine(L["Download"], format("%.2f%%", GetDownloadedPercentage() * 100), 0.5, 0.8, 0.8, 1, 1, 1)
	end

	GameTooltip:AddLine(" ")

	if self.showMemory or not scriptProfileStatus then
		local totalMemory = updateMemory()
		GameTooltip:AddDoubleLine(L["Total Memory"], latencyLens:formatMemory(totalMemory), 0.1, 0.6, 0.6, 0.5, 0.8, 0.8)
		GameTooltip:AddLine(" ")

		local numEnabled = 0
		for _, data in ipairs(infoTable) do
			if IsAddOnLoaded(data[1]) then
				numEnabled = numEnabled + 1
				if numEnabled <= maxShown then
					local r, g, b = latencyLens:smoothColor(data[3], totalMemory)
					GameTooltip:AddDoubleLine(data[2], latencyLens:formatMemory(data[3]), 1, 1, 1, r, g, b)
				end
			end
		end

		if not isShiftKeyDown and (numEnabled > maxAddOns) then
			local hiddenMemory = 0
			for i = (maxAddOns + 1), numEnabled do
				hiddenMemory = hiddenMemory + infoTable[i][3]
			end
			GameTooltip:AddDoubleLine(format(showMoreString, numEnabled - maxAddOns, L["Hidden"], L["Hold Shift"]), latencyLens:formatMemory(hiddenMemory), 0.5, 0.8, 0.8, 0.5, 0.8, 0.8)
		end
	else
		local totalCPU = updateCPU()
		local passedTime = max(1, GetTime() - latencyLens.loginTime)
		GameTooltip:AddDoubleLine(L["System"], format(usageString, totalCPU / passedTime, 0.1, 0.6, 0.6, 0.5, 0.8, 0.8))
		GameTooltip:AddLine(" ")

		local numEnabled = 0
		for _, data in ipairs(infoTable) do
			if IsAddOnLoaded(data[1]) then
				numEnabled = numEnabled + 1
				if numEnabled <= maxShown then
					local r, g, b = latencyLens:smoothColor(data[4], totalCPU)
					GameTooltip:AddDoubleLine(data[2], format(usageString, data[4] / passedTime), 1, 1, 1, r, g, b)
				end
			end
		end

		if not isShiftKeyDown and (numEnabled > maxAddOns) then
			local hiddenUsage = 0
			for i = (maxAddOns + 1), numEnabled do
				hiddenUsage = hiddenUsage + infoTable[i][4]
			end
			GameTooltip:AddDoubleLine(format(showMoreString, numEnabled - maxAddOns, L["Hidden"], L["Hold Shift"]), format(usageString, hiddenUsage / passedTime), 0.5, 0.8, 0.8, 0.5, 0.8, 0.8)
		end
	end

	GameTooltip:AddDoubleLine(" ", latencyLens.LineString)
	GameTooltip:AddDoubleLine(" ", latencyLens.LeftButton .. L["Collect Memory"] .. " ", 1, 1, 1, 0.5, 0.8, 0.8)
	if scriptProfileStatus then
		GameTooltip:AddDoubleLine(" ", latencyLens.RightButton .. L["Toggle Mode"] .. " ", 1, 1, 1, 0.5, 0.8, 0.8)
	end
	GameTooltip:AddDoubleLine(" ", latencyLens.ScrollButton .. L["CPU Usage"] .. ": " .. (GetCVarBool("scriptProfile") and enableString or disableString) .. " ", 1, 1, 1, 0.5, 0.8, 0.8)
	GameTooltip:Show()
end

local function onLeave()
	enteredFrame = false
	GameTooltip:Hide()
end

local function onUpdate(self, elapsed)
	self.timer = (self.timer or 0) + elapsed
	if self.timer > 1 then
		if enableStats then
			setFrameRateAndLatency(self)
			if enteredFrame then
				onEnter(self)
			end
		else
			self.text:SetText("")
			if enteredFrame then
				onLeave()
			end
		end
		self.timer = 0
	end
end

local lastCollectionTime = 0
local collectionInterval = 10 -- seconds

local function onMouseUp(self, btn)
	if btn == "LeftButton" then
		local currentTime = GetTime()
		if currentTime - lastCollectionTime >= collectionInterval then
			if scriptProfileStatus then
				ResetCPUUsage()
				latencyLens.loginTime = currentTime
			end
			local before = gcinfo()
			collectgarbage("collect")
			latencyLens:Print(format("%s", latencyLens:formatMemory(before - gcinfo())))
			lastCollectionTime = currentTime
			onEnter(self)
		else
			latencyLens:Print(format("%s", L["Please wait before collecting memory again."]))
		end
	elseif btn == "RightButton" then
		if IsShiftKeyDown() then
			self:ClearAllPoints()
			if Minimap then
				self:SetPoint("TOP", Minimap, "BOTTOM", 0, -6)
			else
				self:SetPoint("CENTER", UIParent, "CENTER")
			end
		elseif scriptProfileStatus then
			self.showMemory = not self.showMemory
			onEnter(self)
		end
	elseif btn == "MiddleButton" then
		if GetCVarBool("scriptProfile") then
			SetCVar("scriptProfile", 0)
		else
			SetCVar("scriptProfile", 1)
		end

		if GetCVarBool("scriptProfile") == scriptProfileStatus then
			StaticPopup_Hide("CPUUSAGE_TOGGLE")
		else
			StaticPopup_Show("CPUUSAGE_TOGGLE")
		end
		onEnter(self)
	end
end

local function onDragStart(self)
	if not InCombatLockdown() and IsShiftKeyDown() then
		self:StartMoving()
	end
end

local function onDragStop(self)
	self:StopMovingOrSizing()
end

StaticPopupDialogs["CPUUSAGE_TOGGLE"] = {
	text = "You have toggled the CPU profiling option, which requires enabling or disabling the 'scriptProfile' setting. This change necessitates a UI reload to take effect. Would you like to reload the UI now?",
	button1 = APPLY,
	OnAccept = function()
		ReloadUI()
	end,
	whileDead = 1,
}

function latencyLens:OnLogin()
	self.loginTime = GetTime()

	-- Initialize the addon and setup statsFrame if enabled
	if enableStats then
		if not statsFrame then
			statsFrame = CreateFrame("Frame", "latencyLensFrame", UIParent)
			statsFrame:ClearAllPoints()
			if Minimap then
				statsFrame:SetPoint("TOP", Minimap, "BOTTOM", 0, -6)
			else
				statsFrame:SetPoint("CENTER", UIParent, "CENTER")
			end
			statsFrame:SetSize(100, 30)
			statsFrame:SetMovable(true)
			statsFrame:EnableMouse(true)
			statsFrame:RegisterForDrag("LeftButton")

			-- Create a font string for the frame
			statsFrame.text = statsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
			statsFrame.text:SetPoint("CENTER")

			-- Set initial scripts
			statsFrame:SetScript("OnEnter", onEnter)
			statsFrame:SetScript("OnLeave", onLeave)
			statsFrame:SetScript("OnUpdate", onUpdate)
			statsFrame:SetScript("OnMouseUp", onMouseUp)
			statsFrame:SetScript("OnDragStart", onDragStart)
			statsFrame:SetScript("OnDragStop", onDragStop)
		else
			-- If frame exists but was hidden, show it
			statsFrame:Show()
		end
	else
		-- If statsFrame exists but enableStats is false, hide and clean up
		if statsFrame then
			statsFrame:Hide()
			statsFrame:SetScript("OnEnter", nil)
			statsFrame:SetScript("OnLeave", nil)
			statsFrame:SetScript("OnUpdate", nil)
			statsFrame:SetScript("OnMouseUp", nil)
			statsFrame:SetScript("OnDragStart", nil)
			statsFrame:SetScript("OnDragStop", nil)
		end
	end
end
