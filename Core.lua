local ADDON_NAME = ...

local WML = LibStub("AceAddon-3.0"):NewAddon("WoWMusicLibrary", "AceConsole-3.0", "AceEvent-3.0")
_G.WoWMusicLibrary = WML
WML.addonName = ADDON_NAME

local defaults = {
	profile = {
		volume = 1,
		shuffle = false,
		repeatMode = "none",
		selectedPlaylistId = "official-kalimdor",
		playlistCounter = 0,
		playlists = {},
		minimap = { hide = false },
		window = {},
	},
}

function WML:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("WoWMusicLibraryDB", defaults, true)

	self.Library:Initialize()
	self.Player:Initialize()
	self.Options:Initialize()
	self.UI:Initialize()

	self:RegisterChatCommand("wml", "SlashCommand")
	self:RegisterChatCommand("wowmusic", "SlashCommand")
	self:CreateLauncher()
end

function WML:SlashCommand(input)
	input = strtrim(strlower(input or ""))

	if input == "options" or input == "config" then
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
	local AceConfigDialog = LibStub("AceConfigDialog-3.0", true)
	if AceConfigDialog then
		AceConfigDialog:Open("WoWMusicLibrary")
	end
end

function WML:NotifyChanged()
	if self.UI and self.UI.Refresh then
		self.UI:Refresh()
	end
end

function WML:CreateLauncher()
	local LDB = LibStub("LibDataBroker-1.1", true)
	local DBIcon = LibStub("LibDBIcon-1.0", true)
	if not LDB or not DBIcon then
		return
	end

	self.launcher = LDB:NewDataObject("WoWMusicLibrary", {
		type = "launcher",
		text = "WoW Music Library",
		icon = "Interface\\Icons\\INV_Misc_Note_01",
		OnClick = function(_, button)
			if button == "RightButton" then
				WML:OpenOptions()
			else
				WML:Toggle()
			end
		end,
		OnTooltipShow = function(tooltip)
			tooltip:AddLine("WoW Music Library")
			tooltip:AddLine("Left click: toggle")
			tooltip:AddLine("Right click: options")
		end,
	})

	DBIcon:Register("WoWMusicLibrary", self.launcher, self.db.profile.minimap)
end

function WML:SetMinimapHidden(hidden)
	self.db.profile.minimap.hide = hidden and true or false

	local DBIcon = LibStub("LibDBIcon-1.0", true)
	if not DBIcon then
		return
	end

	if self.db.profile.minimap.hide then
		DBIcon:Hide("WoWMusicLibrary")
	else
		DBIcon:Show("WoWMusicLibrary")
	end
end
