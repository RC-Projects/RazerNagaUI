--[[
	Action Button.lua
		A RazerNaga action button
--]]

local RazerNaga = _G[...]
local KeyBound = LibStub('LibKeyBound-1.0')
local Bindings = RazerNaga.BindingsController
local Tooltips = RazerNaga:GetModule('Tooltips')

local ActionButton = RazerNaga:CreateClass('CheckButton', RazerNaga.BindableButton)
RazerNaga.ActionButton = ActionButton
ActionButton.unused = {}
ActionButton.active = {}

local function GetOrCreateActionButton(id)
	if id <= 12 then
		local b = _G['ActionButton' .. id]
		b.buttonType = 'ACTIONBUTTON'
		return b
	elseif id <= 24 then
		return CreateFrame('CheckButton', 'RazerNagaActionButton' .. (id-12), nil, 'ActionBarButtonTemplate')
	elseif id <= 36 then
		local b = _G['MultiBarRightButton' .. (id-24)]
		b.noGrid = 1
		return b
	elseif id <= 48 then
		local b = _G['MultiBarLeftButton' .. (id-36)]
		b.noGrid = 1
		return b
	elseif id <= 60 then
		local b = _G['MultiBarBottomRightButton' .. (id-48)]
		b.noGrid = 1
		return b
	elseif id <= 72 then
		local b = _G['MultiBarBottomLeftButton' .. (id-60)]
		b.noGrid = 1
		return b
	end
	return CreateFrame('CheckButton', 'RazerNagaActionButton' .. (id-60), nil, 'ActionBarButtonTemplate')
end

--constructor
function ActionButton:New(id)
	local b = self:Restore(id) or self:Create(id)

	if b then
		b:SetAttribute('showgrid', 0)
		b:SetAttribute('action--base', id)
		b:SetAttribute('_childupdate-action', [[
			local state = message
			local overridePage = self:GetParent():GetAttribute('state-overridepage')
			local newActionID

			if state == 'override' then
				newActionID = (self:GetAttribute('button--index') or 1) + (overridePage - 1) * 12
			else
				newActionID = state and self:GetAttribute('action--' .. state) or self:GetAttribute('action--base')
			end

			if newActionID ~= self:GetAttribute('action') then
				self:SetAttribute('action', newActionID)
				self:CallMethod('UpdateState')
			end
		]])

		Bindings:Register(b, b:GetName():match('RazerNagaActionButton%d'))
		Tooltips:Register(b)

		--get rid of range indicator text
		local hotkey = b.HotKey
		if hotkey:GetText() == _G['RANGE_INDICATOR'] then
			hotkey:SetText('')
		end

		b:UpdateMacro()

		self.active[id] = b
	end

	return b
end

function ActionButton:Create(id)
	local b = GetOrCreateActionButton(id)

	if b then
		self:Bind(b)

		--this is used to preserve the button's old id
		--we cannot simply keep a button's id at > 0 or blizzard code will take control of paging
		--but we need the button's id for the old bindings system
		b:SetAttribute('bindingid', b:GetID())
		b:SetID(0)

		b:ClearAllPoints()
		b:SetAttribute('useparent-actionpage', nil)
		b:SetAttribute('useparent-unit', true)
		b:SetAttribute("statehidden", nil)
		b:EnableMouseWheel(true)

		b:HookScript('OnEnter', self.OnEnter)

		if b.UpdateHotKeys then
			hooksecurefunc(b, 'UpdateHotkeys', self.UpdateHotkey)
		end

		if b.ShowGrid and b.ShowGrid ~= self.ShowGrid then
			hooksecurefunc(b, 'ShowGrid', self.ShowGrid)
		end

		if b.HideGrid and b.HideGrid ~= self.HideGrid then
			hooksecurefunc(b, 'HideGrid', self.HideGrid)
		end

		b:Skin()
	end
	return b
end

function ActionButton:Restore(id)
	local b = self.unused[id]

	if b then
		self.unused[id] = nil

		b:SetAttribute("statehidden", nil)

		self.active[id] = b
		return b
	end
end

--destructor
do
	local HiddenActionButtonFrame = CreateFrame('Frame')
	HiddenActionButtonFrame:Hide()

	function ActionButton:Free()
		local id = self:GetAttribute('action--base')

		self.active[id] = nil

		Tooltips:Unregister(self)
		Bindings:Unregister(self)

		self:SetAttribute("statehidden", true)
		self:SetParent(HiddenActionButtonFrame)
		self:Hide()
		self.action = 0

		self.unused[id] = self
	end
end

--keybound support
function ActionButton:OnEnter()
	KeyBound:Set(self)
end

--override the old update hotkeys function
if ActionButton_UpdateHotkeys then
	hooksecurefunc('ActionButton_UpdateHotkeys', ActionButton.UpdateHotkey)
end

--button visibility
function ActionButton:ShowGrid(reason)
	if InCombatLockdown() then return end

	self:SetAttribute("showgrid", bit.bor(self:GetAttribute("showgrid"), reason))

	if self:GetAttribute("showgrid") > 0 and not self:GetAttribute("statehidden") then
		self:Show()
	end
end

function ActionButton:HideGrid(reason)
	if InCombatLockdown() then return end

	local showgrid = self:GetAttribute("showgrid");
	if showgrid > 0 then
		self:SetAttribute("showgrid", bit.band(showgrid, bit.bnot(reason)));
	end

	if self:GetAttribute("showgrid") == 0 and not HasAction(self.action) then
		self:Hide()
	end
end


--macro text
function ActionButton:UpdateMacro()
	if RazerNaga:ShowMacroText() then
		self.Name:Show()
	else
		self.Name:Hide()
	end
end

function ActionButton:SetFlyoutDirection(direction)
	if InCombatLockdown() then return end

	self:SetAttribute('flyoutDirection', direction)
	ActionButton_UpdateFlyout(self)
end

if ActionButton_UpdateState then
	ActionButton.UpdateState = ActionButton_UpdateState
end

--utility function, resyncs the button's current action, modified by state
function ActionButton:LoadAction()
	local state = self:GetParent():GetAttribute('state-page')
	local id = state and self:GetAttribute('action--' .. state) or self:GetAttribute('action--base')

	self:SetAttribute('action', id)
end

function ActionButton:Skin()
	if not RazerNaga:Masque('Action Bar', self) then
		self.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
		self:GetNormalTexture():SetVertexColor(1, 1, 1, 0.5)

		local floatingBG = _G[self:GetName() .. 'FloatingBG']
		if floatingBG then
			floatingBG:Hide()
		end
	end
end