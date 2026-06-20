local WML = SpotiWoW

local Player = {
	trackId = nil,
	playlistId = nil,
	queueTrackIds = nil,
	soundHandle = nil,
	finishTicker = nil,
	finishToken = 0,
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

local function CopyTrackIds(trackIds)
	local copy = {}

	for _, trackId in ipairs(trackIds or {}) do
		table.insert(copy, trackId)
	end

	return copy
end

function Player:Initialize()
	self.playlistId = WML.db.profile.selectedPlaylistId
	WML:RegisterEvent("SOUNDKIT_FINISHED", function(_, soundHandle)
		Player:OnSoundFinished(soundHandle)
	end)
	WML:RegisterEvent("PLAYER_LOGOUT", function()
		Player:RestoreZoneMusic()
	end)
end

function Player:PlayTrack(trackId, playlistId, trackIds)
	local track = WML.Library:GetTrack(trackId)
	if not track then
		WML:Print("Track not found: " .. tostring(trackId))
		return
	end

	self:Stop(true, true)
	self:MuteZoneMusic()

	local willPlay, soundHandle = PlaySoundFile(track.value, WML.db.profile.audioChannel or "Master", false, true)
	if not willPlay then
		self:RestoreZoneMusic()
		WML:Print("Could not play: " .. track.title)
		WML:NotifyChanged()
		return
	end

	self.trackId = track.id
	self.playlistId = playlistId or WML.db.profile.selectedPlaylistId
	if trackIds then
		self.queueTrackIds = CopyTrackIds(trackIds)
	end
	self.soundHandle = soundHandle
	self.isPlaying = true
	self:StartFinishWatcher()

	WML:NotifyChanged()
	return true
end

function Player:SetQueue(playlistId, trackIds)
	self.playlistId = playlistId or self.playlistId
	self.queueTrackIds = CopyTrackIds(trackIds)
end

function Player:OnSoundFinished(soundHandle)
	if not self.isPlaying or not self.soundHandle or soundHandle ~= self.soundHandle then
		return
	end

	self:CancelFinishWatcher()
	self.soundHandle = nil
	self.isPlaying = false

	local track, playlistId = self:GetRelativeTrack(1)
	if track then
		self:PlayTrack(track.id, playlistId)
	else
		self:RestoreZoneMusic()
		WML:NotifyChanged()
	end
end

function Player:Stop(silent, keepZoneMusicMuted)
	self:CancelFinishWatcher()

	local soundHandle = self.soundHandle

	self.soundHandle = nil
	self.isPlaying = false

	if soundHandle then
		StopSound(soundHandle)
	end

	if not keepZoneMusicMuted then
		self:RestoreZoneMusic()
	end

	if not silent then
		WML:NotifyChanged()
	end
end

function Player:CancelFinishWatcher()
	self.finishToken = (self.finishToken or 0) + 1

	if self.finishTicker then
		self.finishTicker:Cancel()
		self.finishTicker = nil
	end
end

function Player:StartFinishWatcher()
	self:CancelFinishWatcher()

	if not C_Timer or not C_Timer.NewTicker or not C_Sound or not C_Sound.IsPlaying or not self.soundHandle then
		return
	end

	local token = self.finishToken
	self.finishTicker = C_Timer.NewTicker(1, function(ticker)
		if token ~= Player.finishToken or not Player.isPlaying or not Player.soundHandle then
			ticker:Cancel()
			return
		end

		local ok, isPlaying = pcall(C_Sound.IsPlaying, Player.soundHandle)
		if ok and not isPlaying then
			ticker:Cancel()
			Player:OnSoundFinished(Player.soundHandle)
		end
	end)
end

function Player:MuteZoneMusic()
	if WML.db.profile.audioChannel == "Music" then
		if StopMusic then
			StopMusic()
		end
		return
	end

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
	local playlistId = WML.db.profile.selectedPlaylistId
	if playlistId == WML.settingsPlaylistId then
		playlistId = self.playlistId
	end

	local tracks = self:GetPlaybackTracks(playlistId)

	for _, track in ipairs(tracks) do
		if track.id == self.trackId then
			return track
		end
	end

	if #tracks == 0 then
		tracks = WML.Library:GetPlaylistTracks("official-kalimdor")
		self.playlistId = "official-kalimdor"
	end

	return tracks[1]
end

function Player:GetPlaybackTracks(playlistId)
	local tracks = {}

	if self.queueTrackIds and #self.queueTrackIds > 0 then
		for _, trackId in ipairs(self.queueTrackIds) do
			local track = WML.Library:GetTrack(trackId)
			if track then
				table.insert(tracks, track)
			end
		end

		if #tracks > 0 then
			return tracks
		end
	end

	return WML.Library:GetPlaylistTracks(playlistId)
end

function Player:GetRelativeTrack(delta)
	local playlistId = self.playlistId or WML.db.profile.selectedPlaylistId
	local tracks = self:GetPlaybackTracks(playlistId)

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

	local index = delta > 0 and 0 or (#tracks + 1)
	for i, track in ipairs(tracks) do
		if track.id == self.trackId then
			index = i
			break
		end
	end

	index = index + delta

	if index < 1 then
		index = #tracks
	elseif index > #tracks then
		index = 1
	end

	return tracks[index], playlistId
end
