local Addon = _G[...]
local VehicleLeaveButton = _G.MainMenuBarVehicleLeaveButton

--[[ The Bar ]]--

local VehicleBar = Addon:CreateClass('Frame', Addon.Frame)

function VehicleBar:New()
	local bar = VehicleBar.super.New(self, 'vehicle')

	bar:LoadButtons()
	bar:UpdateOnTaxi()
	bar:Layout()

	return bar
end

function VehicleBar:Create(...)
	local bar = VehicleBar.super.Create(self, ...)

	bar.header:SetAttribute('_onstate-taxi', [[
		self:RunAttribute('updateVehicleButton')
	]])

	bar.header:SetAttribute('_onstate-canexitvehicle', [[
		self:RunAttribute('updateVehicleButton')
	]])

	bar.header:SetAttribute('updateVehicleButton', [[
		local isVisible = self:GetAttribute('state-taxi') == 1
		 			   or self:GetAttribute('state-canexitvehicle') == 1

		self:SetAttribute('state-display', isVisible and 'show' or 'hide')
		self:CallMethod('UpdateExitButton')
	]])

	bar.header.UpdateExitButton = function(self)
		if self:GetAttribute('state-display') == 'show' then
			VehicleLeaveButton:Show()
			VehicleLeaveButton:Enable()
		else
			VehicleLeaveButton:Hide()
			VehicleLeaveButton:Disable()
			VehicleLeaveButton:UnlockHighlight()
		end
	end

	RegisterStateDriver(bar.header, 'canexitvehicle', '[canexitvehicle]1;0')

	return bar
end

function VehicleBar:UpdateOnTaxi()
	self.header:SetAttribute('state-taxi', UnitOnTaxi('player') and 1 or 0)
end

function VehicleBar:GetDefaults()
	return {
		point = 'CENTER',
		x = -244,
		y = 0,
	}
end

function VehicleBar:GetShowStates()
	return nil
end

function VehicleBar:NumButtons()
	return 1
end

function VehicleBar:AddButton(i)
	local button = VehicleLeaveButton

	if button then
		button:SetParent(self.header)
		button:Show()

		self.buttons[i] = button
	end
end

function VehicleBar:RemoveButton(i)
	local button = self.buttons[i]

	if button then
		button:SetParent(nil)
		button:Hide()

		self.buttons[i] = nil
	end
end


--[[ Controller ]]--

local VehicleBarController = Addon:NewModule('VehicleBar', 'AceEvent-3.0')

function VehicleBarController:OnInitialize()
	VehicleLeaveButton:UnregisterAllEvents()
end

function VehicleBarController:Load()
	self.frame = VehicleBar:New()

	self:RegisterEvent('UPDATE_BONUS_ACTIONBAR', 'UpdateOnTaxi')
	self:RegisterEvent('UPDATE_MULTI_CAST_ACTIONBAR', 'UpdateOnTaxi')
	self:RegisterEvent('UNIT_ENTERED_VEHICLE', 'UpdateOnTaxi')
	self:RegisterEvent('UNIT_EXITED_VEHICLE', 'UpdateOnTaxi')
	self:RegisterEvent('VEHICLE_UPDATE', 'UpdateOnTaxi')
	self:RegisterEvent('PLAYER_REGEN_ENABLED', 'UpdateOnTaxi')
end

function VehicleBarController:Unload()
	self:UnregisterAllEvents()

	if self.frame then
		self.frame:Free()
		self.frame = nil
	end
end

function VehicleBarController:UpdateOnTaxi()
	if InCombatLockdown() then return end

	self.frame:UpdateOnTaxi()
end
