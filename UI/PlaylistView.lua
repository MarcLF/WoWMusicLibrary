local WML = SpotiWoW
local UI = WML.UI

local function AddDropdownOption(options, text, checked, func)
    table.insert(options, {
        text = text,
        checked = checked,
        func = func,
    })
end

local AUDIO_CHANNELS = {
    { text = "Master", value = "Master" },
    { text = "Music", value = "Music" },
    { text = "Sound Effects", value = "SFX" },
    { text = "Ambience", value = "Ambience" },
    { text = "Dialog", value = "Dialog" },
}

local MINI_OPACITY_VALUES = { 1, 0.9, 0.8, 0.7, 0.6, 0.5 }

local function ContainsValue(list, value)
    for _, entry in ipairs(list) do
        if entry == value then
            return true
        end
    end

    return false
end

local function SetButtonEnabled(button, enabled)
    local fontString = button:GetFontString()

    if enabled then
        button:Enable()
        UI:SkinBox(button, UI.colors.button, UI.colors.border)
        if fontString then
            fontString:SetTextColor(UI.colors.text[1], UI.colors.text[2], UI.colors.text[3], UI.colors.text[4])
        end
    else
        button:Disable()
        UI:SkinBox(button, UI.colors.buttonDisabled, UI.colors.border)
        if fontString then
            fontString:SetTextColor(UI.colors.textDisabled[1], UI.colors.textDisabled[2], UI.colors.textDisabled[3], UI.colors.textDisabled[4])
        end
    end
end

local function TrackMeta(track)
    local parts = {}

    if track.continent then
        table.insert(parts, track.continent)
    end

    if track.zone then
        table.insert(parts, track.zone)
    end

    if track.biome then
        table.insert(parts, track.biome)
    end

    if track.timeOfDay then
        table.insert(parts, track.timeOfDay)
    end

    return table.concat(parts, " - ")
end

local function GetTrackIds(sourceTracks)
    local trackIds = {}

    for _, track in ipairs(sourceTracks or {}) do
        table.insert(trackIds, track.id)
    end

    return trackIds
end

local function GetPageTracks(sourceTracks, page, pageSize)
    local pageTracks = {}
    local firstIndex = ((page - 1) * pageSize) + 1
    local lastIndex = math.min(firstIndex + pageSize - 1, #sourceTracks)

    for index = firstIndex, lastIndex do
        table.insert(pageTracks, sourceTracks[index])
    end

    return pageTracks, firstIndex, lastIndex
end

local function GetTrackValues(sourceTracks, field)
    local values = {}
    local seen = {}

    for _, track in ipairs(sourceTracks or {}) do
        local value = track[field]
        if value and value ~= "" and not seen[value] then
            seen[value] = true
            table.insert(values, value)
        end
    end

    table.sort(values)
    return values
end

local function GetAudioChannelText(value)
    for _, channel in ipairs(AUDIO_CHANNELS) do
        if channel.value == value then
            return channel.text
        end
    end

    return "Master"
end

local function GetMiniOpacityText(value)
    value = tonumber(value) or 1
    return string.format("%d%%", math.floor((value * 100) + 0.5))
end

function UI:GetSelectedTargetPlaylist()
    local playlists = WML.Library:GetUserPlaylists()
    if #playlists == 0 then
        self.selectedTargetPlaylistId = nil
        return nil
    end

    if self.selectedTargetPlaylistId then
        local playlist, isOfficial = WML.Library:GetPlaylist(self.selectedTargetPlaylistId)
        if playlist and not isOfficial then
            return playlist
        end
    end

    self.selectedTargetPlaylistId = playlists[1].id
    return playlists[1]
end

function UI:GetTargetPlaylistForAdd()
    local playlist = self:GetSelectedTargetPlaylist()
    if playlist then
        return playlist
    end

    playlist = WML.Library:GetOrCreateDefaultUserPlaylist(false)
    self.selectedTargetPlaylistId = playlist.id
    return playlist
end

function UI:BuildTargetDropdown()
    local options = {}
    local playlists = WML.Library:GetUserPlaylists()

    if #playlists == 0 then
        AddDropdownOption(options, "Create My Playlist", false, function()
            local playlist = WML.Library:GetOrCreateDefaultUserPlaylist(false)
            self.selectedTargetPlaylistId = playlist.id
            self:Refresh()
        end)
        return options
    end

    for _, playlist in ipairs(playlists) do
        local playlistId = playlist.id
        AddDropdownOption(options, playlist.name, playlistId == self.selectedTargetPlaylistId, function()
            self.selectedTargetPlaylistId = playlistId
            self:RefreshTargetDropdown()
        end)
    end

    return options
end

function UI:RefreshTargetDropdown()
    if not self.targetDropdown then
        return
    end

    local playlist = self:GetSelectedTargetPlaylist()
    self:SetDropdownText(self.targetDropdown, playlist and playlist.name or "My Playlist (new)")
end

function UI:BuildZoneDropdown()
    local options = {}
    local selectedZone = self.filter.zone or "all"
    local selectedBiome = self.filter.biome or "all"
    local tracks = WML.Library:GetPlaylistTracks(self.currentPlaylistId)

    AddDropdownOption(options, "All zones/biomes", selectedZone == "all" and selectedBiome == "all", function()
        self.filter.zone = "all"
        self.filter.biome = "all"
        self:RefreshTracks()
    end)

    for _, zone in ipairs(GetTrackValues(tracks, "zone")) do
        AddDropdownOption(options, zone, selectedZone == zone, function()
            self.filter.zone = zone
            self.filter.biome = "all"
            self:RefreshTracks()
        end)
    end

    for _, biome in ipairs(GetTrackValues(tracks, "biome")) do
        local text = "Biome: " .. biome
        AddDropdownOption(options, text, selectedBiome == biome, function()
            self.filter.zone = "all"
            self.filter.biome = biome
            self:RefreshTracks()
        end)
    end

    return options
end

function UI:BuildAudioChannelDropdown()
    local options = {}
    local selected = WML.db.profile.audioChannel or "Master"

    for _, channel in ipairs(AUDIO_CHANNELS) do
        AddDropdownOption(options, channel.text, selected == channel.value, function()
            WML.db.profile.audioChannel = channel.value
            self:RefreshSettingsControls()
        end)
    end

    return options
end

function UI:BuildMiniOpacityDropdown()
    local options = {}
    local selected = self:GetMiniPlayerOpacity()

    for _, value in ipairs(MINI_OPACITY_VALUES) do
        AddDropdownOption(options, GetMiniOpacityText(value), math.abs(selected - value) < 0.01, function()
            WML.db.profile.miniBackgroundOpacity = value
            self:RefreshSettingsControls()
            self:ApplyMiniPlayerOpacity()
        end)
    end

    return options
end

function UI:BuildTimeDropdown()
    local options = {}
    local selected = self.filter.timeOfDay or "all"

    AddDropdownOption(options, "Any time", selected == "all", function()
        self.filter.timeOfDay = "all"
        self:RefreshTracks()
    end)

    AddDropdownOption(options, "Day", selected == "day", function()
        self.filter.timeOfDay = "day"
        self:RefreshTracks()
    end)

    AddDropdownOption(options, "Night", selected == "night", function()
        self.filter.timeOfDay = "night"
        self:RefreshTracks()
    end)

    return options
end

function UI:RefreshFilterDropdowns()
    if not self.zoneDropdown then
        return
    end

    self.filter.zone = self.filter.zone or "all"
    self.filter.biome = self.filter.biome or "all"
    self.filter.timeOfDay = self.filter.timeOfDay or "all"

    local tracks = WML.Library:GetPlaylistTracks(self.currentPlaylistId)
    if self.filter.zone ~= "all" and not ContainsValue(GetTrackValues(tracks, "zone"), self.filter.zone) then
        self.filter.zone = "all"
    end

    if self.filter.biome ~= "all" and not ContainsValue(GetTrackValues(tracks, "biome"), self.filter.biome) then
        self.filter.biome = "all"
    end

    if self.filter.zone ~= "all" then
        self:SetDropdownText(self.zoneDropdown, self.filter.zone)
    elseif self.filter.biome ~= "all" then
        self:SetDropdownText(self.zoneDropdown, "Biome: " .. self.filter.biome)
    else
        self:SetDropdownText(self.zoneDropdown, "All zones/biomes")
    end

    if self.filter.timeOfDay == "day" then
        self:SetDropdownText(self.timeDropdown, "Day")
    elseif self.filter.timeOfDay == "night" then
        self:SetDropdownText(self.timeDropdown, "Night")
    else
        self:SetDropdownText(self.timeDropdown, "Any time")
    end
end

function UI:RefreshSettingsControls()
    if self.audioChannelDropdown then
        self:SetDropdownText(self.audioChannelDropdown, GetAudioChannelText(WML.db.profile.audioChannel or "Master"))
    end

    if self.miniOpacityDropdown then
        self:SetDropdownText(self.miniOpacityDropdown, GetMiniOpacityText(self:GetMiniPlayerOpacity()))
    end
end

function UI:GetRowsForPlaylist(playlist, isOfficial)
    local rows = {}
    local filters = {
        search = self.searchBox:GetText(),
    }
    local playlistTracks
    local action

    if isOfficial then
        filters.zone = self.filter.zone
        filters.biome = self.filter.biome
        filters.timeOfDay = self.filter.timeOfDay

        playlistTracks = WML.Library:FilterTracks(WML.Library:GetPlaylistTracks(playlist.id), filters)
        action = "add"
    else
        playlistTracks = WML.Library:FilterTracks(WML.Library:GetPlaylistTracks(playlist.id), filters)
        action = "remove"

        if #playlistTracks > 0 then
            self:AddHeader(rows, "Playlist Tracks")
        else
            self:AddHeader(rows, "No tracks yet")
        end
    end

    local pageSize = self.pageSize or 50
    local maxPage = math.max(1, math.ceil(#playlistTracks / pageSize))
    self.trackPage = math.min(math.max(self.trackPage or 1, 1), maxPage)

    local pageTracks, firstIndex, lastIndex = GetPageTracks(playlistTracks, self.trackPage, pageSize)
    self:AddTrackRows(rows, pageTracks, action, playlist.id)

    return rows, GetTrackIds(playlistTracks), #playlistTracks, firstIndex, lastIndex
end

function UI:PlayVisibleTrack(shuffle)
    local trackIds = self.filteredTrackIds or {}

    if #trackIds == 0 then
        return
    end

    local index = shuffle and math.random(#trackIds) or 1
    WML.Player:PlayTrack(trackIds[index], self.currentPlaylistId, trackIds)
end

function UI:ToggleShuffle()
    local enabled = not WML.db.profile.shuffle
    local trackIds = self.filteredTrackIds or {}

    WML.db.profile.shuffle = enabled

    if enabled then
        WML.Player:SetQueue(self.currentPlaylistId, trackIds)

        if not WML.Player.isPlaying and #trackIds > 0 then
            self:PlayVisibleTrack(true)
            return
        end
    end

    WML:NotifyChanged()
end

function UI:AddAllVisibleTracks()
    local targetPlaylist = self:GetTargetPlaylistForAdd()

    if not targetPlaylist then
        return
    end

    WML.Library:AddTracksToPlaylist(targetPlaylist.id, self.filteredTrackIds or {})
end

function UI:RefreshPlaylistActions(isOfficial)
    local hasTracks = self.filteredTrackIds and #self.filteredTrackIds > 0

    SetButtonEnabled(self.playlistPlayButton, hasTracks)
    self.playlistAddAllButton:SetShown(isOfficial)
    SetButtonEnabled(self.playlistAddAllButton, isOfficial and hasTracks)
end

function UI:GetTrackPageKey(playlist, isOfficial)
    local parts = {
        playlist.id,
        self.searchBox:GetText() or "",
    }

    if isOfficial then
        table.insert(parts, self.filter.zone or "all")
        table.insert(parts, self.filter.biome or "all")
        table.insert(parts, self.filter.timeOfDay or "all")
    end

    return table.concat(parts, "\031")
end

function UI:SetTrackPage(page)
    self.trackPage = math.max(1, page or 1)
    self:RefreshTracks()
end

function UI:RefreshPageControls(totalTracks, firstIndex, lastIndex)
    if not self.prevPageButton then
        return
    end

    totalTracks = totalTracks or 0
    local pageSize = self.pageSize or 50
    local maxPage = math.max(1, math.ceil(totalTracks / pageSize))
    local hasPages = totalTracks > pageSize

    self.prevPageButton:SetShown(hasPages)
    self.nextPageButton:SetShown(hasPages)
    self.pageText:SetShown(totalTracks > 0)

    if totalTracks > 0 then
        self.pageText:SetText(string.format("%d-%d of %d", firstIndex or 1, lastIndex or totalTracks, totalTracks))
    else
        self.pageText:SetText("")
    end

    SetButtonEnabled(self.prevPageButton, hasPages and (self.trackPage or 1) > 1)
    SetButtonEnabled(self.nextPageButton, hasPages and (self.trackPage or 1) < maxPage)
end

function UI:SetBrowseControlsShown(isOfficial, isSettings)
    self.searchBox:SetShown(not isSettings)
    self.playlistPlayButton:SetShown(not isSettings)
    self.playlistAddAllButton:SetShown(isOfficial and not isSettings)
    self.targetLabel:SetShown(isOfficial and not isSettings)
    self.targetDropdown:SetShown(isOfficial and not isSettings)
    self.zoneDropdown:SetShown(isOfficial and not isSettings)
    self.timeDropdown:SetShown(isOfficial and not isSettings)
    self.renameBox:SetShown(not isOfficial and not isSettings)
    self.renameButton:SetShown(not isOfficial and not isSettings)
    self.deleteButton:SetShown(not isOfficial and not isSettings)
    self.trackScroll:SetShown(not isSettings)
    self.settingsPanel:SetShown(isSettings)
end

function UI:RefreshTracks()
    self:CloseDropdowns()

    if WML.db.profile.selectedPlaylistId == WML.settingsPlaylistId then
        self.currentPlaylistId = WML.settingsPlaylistId
        self.filteredTrackIds = {}
        self.playlistTitle:SetText("Settings")
        self:SetBrowseControlsShown(false, true)
        self:RefreshSettingsControls()
        self:RefreshPageControls(0)
        self:RefreshPlaylistActions(false)
        for i = 1, #self.trackRows do
            self.trackRows[i]:Hide()
        end
        return
    end

    local playlist, isOfficial = WML.Library:GetPlaylist(WML.db.profile.selectedPlaylistId)
    if not playlist then
        WML.Library:EnsureSelectedPlaylist()
        playlist, isOfficial = WML.Library:GetPlaylist(WML.db.profile.selectedPlaylistId)
    end

    if not playlist then
        return
    end

    self.currentPlaylistId = playlist.id
    self.playlistTitle:SetText(playlist.name)
    self:SetBrowseControlsShown(isOfficial, false)

    if isOfficial then
        self:RefreshTargetDropdown()
        self:RefreshFilterDropdowns()
    else
        self.renameBox:SetText(playlist.name)
    end

    local pageKey = self:GetTrackPageKey(playlist, isOfficial)
    local previousPage = self.trackPage or 1
    local resetScroll = false

    if pageKey ~= self.trackPageKey then
        self.trackPageKey = pageKey
        self.trackPage = 1
        resetScroll = true
    end

    local rows, filteredTrackIds, totalTracks, firstIndex, lastIndex = self:GetRowsForPlaylist(playlist, isOfficial)
    if self.trackPage ~= previousPage then
        resetScroll = true
    end

    local y = 0

    for index, rowData in ipairs(rows) do
        local row = self:GetTrackRow(index)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", self.trackContent, "TOPLEFT", 0, y)
        row:SetPoint("RIGHT", self.trackScroll, "RIGHT", -2, 0)

        if rowData.kind == "header" then
            self:SetBackdrop(row, self.colors.panel)
            row:SetHeight(26)
            row.play:Hide()
            row.like:Hide()
            row.action:Hide()
            row.title:ClearAllPoints()
            row.title:SetPoint("LEFT", 8, 0)
            row.title:SetPoint("RIGHT", -8, 0)
            row.title:SetText(rowData.text)
            row.meta:ClearAllPoints()
            row.meta:SetText("")
            row:Show()
            y = y - 30
        else
            local track = rowData.track
            local action = rowData.action
            local trackId = track.id
            local playlistId = rowData.playlistId
            local rowIsOfficial = isOfficial

            self:SetBackdrop(row, trackId == WML.Player.trackId and self.colors.rowActive or self.colors.row, trackId == WML.Player.trackId and self.colors.borderBright or self.colors.border)
            row:SetHeight(38)
            row.title:ClearAllPoints()
            row.title:SetPoint("LEFT", 104, 7)
            row.title:SetPoint("RIGHT", -98, 7)
            row.title:SetText(track.title)
            row.meta:ClearAllPoints()
            row.meta:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -2)
            row.meta:SetPoint("RIGHT", row.title, "RIGHT", 0, 0)
            row.meta:SetText(TrackMeta(track))
            row.play:Show()
            row.play:SetScript("OnClick", function()
                WML.Player:PlayTrack(trackId, playlistId, UI.filteredTrackIds)
            end)
            row.like:Show()
            row.like:SetText(WML.Library:IsTrackLiked(trackId) and "Liked" or "Like")
            row.like:SetScript("OnClick", function()
                WML.Library:ToggleLikedTrack(trackId)
            end)
            row.action:Show()
            if action == "remove" then
                row.action:SetText("Remove")
                row.action:SetScript("OnClick", function()
                    WML.Library:RemoveTrackFromPlaylist(playlistId, trackId)
                end)
            else
                row.action:SetText("Add")
                row.action:SetScript("OnClick", function()
                    local targetPlaylistId = playlistId
                    if rowIsOfficial then
                        targetPlaylistId = UI:GetTargetPlaylistForAdd().id
                    end
                    WML.Library:AddTrackToPlaylist(targetPlaylistId, trackId)
                end)
            end
            row:Show()
            y = y - 42
        end
    end

    for i = #rows + 1, #self.trackRows do
        self.trackRows[i]:Hide()
    end

    self.filteredTrackIds = filteredTrackIds
    self.trackContent:SetSize(self.trackScroll:GetWidth() - 22, math.max(1, -y))
    self:RefreshPageControls(totalTracks, firstIndex, lastIndex)
    self:RefreshPlaylistActions(isOfficial)

    if resetScroll then
        self.trackScroll:SetVerticalScroll(0)
    end
end
