local WML = SpotiWoW
local Library = {}
WML.Library = Library

local LIKED_PLAYLIST_ID = "liked-songs"

local tracks = WML.Data and WML.Data.Tracks or {}
local officialPlaylists = WML.Data and WML.Data.Playlists or {}
local trackById = {}

local function IsEmptyFilter(value)
    return value == nil or value == "" or value == "all"
end

local function Lower(value)
    return string.lower(tostring(value or ""))
end

local function AddUnique(list, seen, value)
    if value and value ~= "" and not seen[value] then
        seen[value] = true
        table.insert(list, value)
    end
end

local function PlaylistContains(playlist, trackId)
    for _, existingId in ipairs(playlist.tracks or {}) do
        if existingId == trackId then
            return true
        end
    end

    return false
end

local function RemoveTrackId(playlist, trackId)
    for index, existingId in ipairs(playlist.tracks or {}) do
        if existingId == trackId then
            table.remove(playlist.tracks, index)
            return true
        end
    end

    return false
end

function Library:Initialize()
    wipe(trackById)

    for _, track in ipairs(tracks) do
        trackById[track.id] = track
    end
end

function Library:GetAllTracks()
    return tracks
end

function Library:GetTrack(trackId)
    return trackById[trackId]
end

function Library:GetOfficialPlaylists()
    return officialPlaylists
end

function Library:GetUserPlaylists()
    local profile = WML.db.profile
    profile.playlists = profile.playlists or {}
    return profile.playlists
end

function Library:GetPlaylist(playlistId)
    for _, playlist in ipairs(officialPlaylists) do
        if playlist.id == playlistId then
            return playlist, true
        end
    end

    for _, playlist in ipairs(self:GetUserPlaylists()) do
        if playlist.id == playlistId then
            return playlist, false
        end
    end
end

function Library:GetPlaylistTracks(playlistId)
    local playlist = self:GetPlaylist(playlistId)
    local playlistTracks = {}

    if not playlist then
        return playlistTracks
    end

    for _, trackId in ipairs(playlist.tracks or {}) do
        local track = self:GetTrack(trackId)
        if track then
            table.insert(playlistTracks, track)
        end
    end

    return playlistTracks
end

function Library:GetContinents()
    local continents = {}
    local seen = {}

    for _, track in ipairs(tracks) do
        AddUnique(continents, seen, track.continent)
    end

    table.sort(continents)
    return continents
end

function Library:GetZones(continent)
    local zones = {}
    local seen = {}

    for _, track in ipairs(tracks) do
        if IsEmptyFilter(continent) or track.continent == continent then
            AddUnique(zones, seen, track.zone)
        end
    end

    table.sort(zones)
    return zones
end

function Library:GetBiomes(continent)
    local biomes = {}
    local seen = {}

    for _, track in ipairs(tracks) do
        if IsEmptyFilter(continent) or track.continent == continent then
            AddUnique(biomes, seen, track.biome)
        end
    end

    table.sort(biomes)
    return biomes
end

function Library:FilterTracks(sourceTracks, filters)
    if type(filters) == "string" then
        filters = { search = filters }
    end

    filters = filters or {}

    if IsEmptyFilter(filters.search)
        and IsEmptyFilter(filters.continent)
        and IsEmptyFilter(filters.zone)
        and IsEmptyFilter(filters.biome)
        and IsEmptyFilter(filters.timeOfDay) then
        return sourceTracks
    end

    local filtered = {}
    local search = Lower(filters.search)

    for _, track in ipairs(sourceTracks or {}) do
        local matches = true

        if not IsEmptyFilter(filters.continent) and track.continent ~= filters.continent then
            matches = false
        end

        if not IsEmptyFilter(filters.zone) and track.zone ~= filters.zone then
            matches = false
        end

        if not IsEmptyFilter(filters.biome) and track.biome ~= filters.biome then
            matches = false
        end

        if not IsEmptyFilter(filters.timeOfDay) and track.timeOfDay ~= filters.timeOfDay then
            matches = false
        end

        if matches and search ~= "" then
            local haystack = {
                track.title,
                track.artist,
                track.continent,
                track.zone,
                track.biome,
                track.timeOfDay,
            }

            if track.tags then
                for _, tag in ipairs(track.tags) do
                    table.insert(haystack, tag)
                end
            end

            matches = string.find(Lower(table.concat(haystack, " ")), search, 1, true) ~= nil
        end

        if matches then
            table.insert(filtered, track)
        end
    end

    return filtered
end

function Library:CreatePlaylist(name, selectPlaylist)
    local profile = WML.db.profile
    profile.playlistCounter = (profile.playlistCounter or 0) + 1

    local playlist = {
        id = "user-" .. profile.playlistCounter,
        name = name ~= "" and name or ("Playlist " .. profile.playlistCounter),
        tracks = {},
    }

    table.insert(self:GetUserPlaylists(), playlist)

    if selectPlaylist ~= false then
        profile.selectedPlaylistId = playlist.id
    end

    WML:NotifyChanged()
    return playlist
end

function Library:RenamePlaylist(playlistId, name)
    local playlist, isOfficial = self:GetPlaylist(playlistId)

    if not playlist or isOfficial or name == "" then
        return
    end

    playlist.name = name
    WML:NotifyChanged()
end

function Library:DeletePlaylist(playlistId)
    local playlists = self:GetUserPlaylists()

    for index, playlist in ipairs(playlists) do
        if playlist.id == playlistId then
            table.remove(playlists, index)

            if WML.db.profile.selectedPlaylistId == playlistId then
                WML.db.profile.selectedPlaylistId = "official-kalimdor"
            end

            WML:NotifyChanged()
            return true
        end
    end
end

function Library:EnsureSelectedPlaylist()
    if self:GetPlaylist(WML.db.profile.selectedPlaylistId) then
        return
    end

    if officialPlaylists[1] then
        WML.db.profile.selectedPlaylistId = officialPlaylists[1].id
    else
        WML.db.profile.selectedPlaylistId = nil
    end
end

function Library:SelectPlaylist(playlistId)
    if not self:GetPlaylist(playlistId) then
        return
    end

    WML.db.profile.selectedPlaylistId = playlistId
    WML:NotifyChanged()
end

function Library:AddTrackToPlaylist(playlistId, trackId)
    local playlist, isOfficial = self:GetPlaylist(playlistId)

    if not playlist or isOfficial or not trackById[trackId] then
        return
    end

    playlist.tracks = playlist.tracks or {}

    if PlaylistContains(playlist, trackId) then
        return false
    end

    table.insert(playlist.tracks, trackId)
    WML:NotifyChanged()
    return true
end

function Library:AddTracksToPlaylist(playlistId, trackIds)
    local playlist, isOfficial = self:GetPlaylist(playlistId)

    if not playlist or isOfficial then
        return
    end

    playlist.tracks = playlist.tracks or {}

    local changed = false
    for _, trackId in ipairs(trackIds or {}) do
        if trackById[trackId] and not PlaylistContains(playlist, trackId) then
            table.insert(playlist.tracks, trackId)
            changed = true
        end
    end

    if changed then
        WML:NotifyChanged()
    end

    return changed
end

function Library:RemoveTrackFromPlaylist(playlistId, trackId)
    local playlist, isOfficial = self:GetPlaylist(playlistId)

    if not playlist or isOfficial then
        return
    end

    if RemoveTrackId(playlist, trackId) then
        WML:NotifyChanged()
        return true
    end
end

function Library:GetOrCreateDefaultUserPlaylist(selectPlaylist)
    local playlists = self:GetUserPlaylists()

    if #playlists > 0 then
        return playlists[1]
    end

    return self:CreatePlaylist("My Playlist", selectPlaylist)
end

function Library:GetLikedPlaylist()
    for _, playlist in ipairs(self:GetUserPlaylists()) do
        if playlist.id == LIKED_PLAYLIST_ID or playlist.system == "liked" then
            return playlist
        end
    end
end

function Library:GetOrCreateLikedPlaylist()
    local playlist = self:GetLikedPlaylist()

    if playlist then
        return playlist
    end

    playlist = {
        id = LIKED_PLAYLIST_ID,
        name = "Liked Songs",
        tracks = {},
        system = "liked",
    }

    table.insert(self:GetUserPlaylists(), playlist)
    WML:NotifyChanged()
    return playlist
end

function Library:IsTrackLiked(trackId)
    local playlist = self:GetLikedPlaylist()

    if not playlist then
        return false
    end

    return PlaylistContains(playlist, trackId)
end

function Library:ToggleLikedTrack(trackId)
    if not trackById[trackId] then
        return
    end

    local playlist = self:GetOrCreateLikedPlaylist()

    if RemoveTrackId(playlist, trackId) then
        WML:NotifyChanged()
        return false
    end

    table.insert(playlist.tracks, trackId)
    WML:NotifyChanged()
    return true
end
