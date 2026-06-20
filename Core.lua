local ADDON_NAME = ...

local WML = LibStub("AceAddon-3.0"):NewAddon("SpotiWoW", "AceConsole-3.0", "AceEvent-3.0")
_G.SpotiWoW = WML
WML.addonName = ADDON_NAME
WML.settingsPlaylistId = "__settings"

local defaults = {
	profile = {
		audioChannel = "Master",
		shuffle = false,
		selectedPlaylistId = "official-kalimdor",
		playlistCounter = 0,
		playlists = {},
		window = {},
		miniWindow = {},
		miniCollapsed = false,
		miniBackgroundOpacity = 1,
	},
}

function WML:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("SpotiWoWDB", defaults, true)

	self.Library:Initialize()
	self.Player:Initialize()
	self.UI:Initialize()

	self:RegisterChatCommand("spotiwow", "SlashCommand")
	self:RegisterChatCommand("swow", "SlashCommand")
end

function WML:SlashCommand(input)
	input = strtrim(strlower(input or ""))

	if input == "settings" or input == "options" or input == "config" then
		self:OpenOptions()
	elseif input == "stop" then
		self.Player:Stop()
	else
		self:Toggle()
	end
end

function WML:Toggle()
	if self.UI:IsShown() then
		self.UI:Hide()
	else
		self.UI:Show()
	end
end

function WML:OpenOptions()
	self.db.profile.selectedPlaylistId = self.settingsPlaylistId
	self.UI:Show()
end

function SpotiWoW_OnAddonCompartmentClick(_, buttonName)
	if buttonName == "RightButton" then
		WML:OpenOptions()
	else
		WML:Toggle()
	end
end

function SpotiWoW_OnAddonCompartmentEnter(_, button)
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	GameTooltip:AddLine("SpotiWoW")
	GameTooltip:AddLine("Left click: toggle")
	GameTooltip:AddLine("Right click: settings")
	GameTooltip:Show()
end

function SpotiWoW_OnAddonCompartmentLeave()
	GameTooltip:Hide()
end

function WML:NotifyChanged()
	if self.UI and self.UI.Refresh then
		self.UI:Refresh()
	end
end
