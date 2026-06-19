local WML = WoWMusicLibrary

local Player = {
	trackId = nil,
	playlistId = nil,
	soundHandle = nil,
	isPlaying = false,
	savedMusicEnabled = nil,
}

WML.Player = Player

local function GetCVarValue(name)
	if C_CVar and C_CVar.GetCVar then
		return C_CVar.GetCVar(name)
	end

	return GetCVar and GetCVar(name)
end

local function SetCVarValue(name, value)
	if C_CVar and C_CVar.SetCVar then
		C_CVar.SetCVar(name, value)
	elseif SetCVar then
		SetCVar(name, value)
	end
end

function Player:Initialize()
	self.playlistId = WML.db.profile.selectedPlaylistId
	WML:RegisterEvent("PLAYER_LOGOUT", function()
		Player:RestoreZoneMusic()
	end)
end

function Player:PlayTrack(trackId, playlistId)
	local track = WML.Library:GetTrack(trackId)
	if not track then
		WML:Print("Track not found: " .. tostring(trackId))
		return
	end

	self:Stop(true, true)
	self:MuteZoneMusic()

	local willPlay, soundHandle = PlaySoundFile(track.value, "Master")
	if not willPlay then
		self:RestoreZoneMusic()
		WML:Print("Could not play: " .. track.title)
		WML:NotifyChanged()
		return
	end

	self.trackId = track.id
	self.playlistId = playlistId or WML.db.profile.selectedPlaylistId
	self.soundHandle = soundHandle
	self.isPlaying = true

	WML:NotifyChanged()
	return true
end

function Player:Stop(silent, keepZoneMusicMuted)
	if self.soundHandle then
		StopSound(self.soundHandle)
	end

	self.soundHandle = nil
	self.isPlaying = false

	if not keepZoneMusicMuted then
		self:RestoreZoneMusic()
	end

	if not silent then
		WML:NotifyChanged()
	end
end

function Player:MuteZoneMusic()
	if self.savedMusicEnabled == nil then
		self.savedMusicEnabled = GetCVarValue("Sound_EnableMusic") or "1"
	end

	SetCVarValue("Sound_EnableMusic", "0")

	if StopMusic then
		StopMusic()
	end
end

function Player:RestoreZoneMusic()
	if self.savedMusicEnabled == nil then
		return
	end

	SetCVarValue("Sound_EnableMusic", self.savedMusicEnabled)
	self.savedMusicEnabled = nil
end

function Player:TogglePlay()
	if self.isPlaying then
		self:Stop()
		return
	end

	local track = self:GetCurrentOrFirstTrack()
	if track then
		self:PlayTrack(track.id, self.playlistId or WML.db.profile.selectedPlaylistId)
	end
end

function Player:Next()
	local track, playlistId = self:GetRelativeTrack(1)
	if track then
		self:PlayTrack(track.id, playlistId)
	end
end

function Player:Previous()
	local track, playlistId = self:GetRelativeTrack(-1)
	if track then
		self:PlayTrack(track.id, playlistId)
	end
end

function Player:GetState()
	return {
		isPlaying = self.isPlaying,
		trackId = self.trackId,
		track = WML.Library:GetTrack(self.trackId),
		playlistId = self.playlistId,
		soundHandle = self.soundHandle,
	}
end

function Player:GetCurrentOrFirstTrack()
	if self.trackId and WML.Library:GetTrack(self.trackId) then
		return WML.Library:GetTrack(self.trackId)
	end

	local tracks = WML.Library:GetPlaylistTracks(WML.db.profile.selectedPlaylistId)
	if #tracks == 0 then
		tracks = WML.Library:GetPlaylistTracks("official-kalimdor")
		self.playlistId = "official-kalimdor"
	end

	return tracks[1]
end

function Player:GetRelativeTrack(delta)
	local playlistId = self.playlistId or WML.db.profile.selectedPlaylistId
	local tracks = WML.Library:GetPlaylistTracks(playlistId)

	if #tracks == 0 then
		playlistId = "official-kalimdor"
		tracks = WML.Library:GetPlaylistTracks(playlistId)
	end

	if #tracks == 0 then
		return nil, playlistId
	end

	if WML.db.profile.shuffle and #tracks > 1 then
		local track
		repeat
			track = tracks[math.random(#tracks)]
		until track.id ~= self.trackId
		return track, playlistId
	end

	local index = 1
	for i, track in ipairs(tracks) do
		if track.id == self.trackId then
			index = i
			break
		end
	end

	if WML.db.profile.repeatMode ~= "track" then
		index = index + delta
	end

	if index < 1 then
		index = #tracks
	elseif index > #tracks then
		index = 1
	end

	return tracks[index], playlistId
end
