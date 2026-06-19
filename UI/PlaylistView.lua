local WML = WoWMusicLibrary
local UI = WML.UI

local function AddDropdownButton(text, checked, func)
    local info = UIDropDownMenu_CreateInfo()
    info.text = text
    info.checked = checked
    info.func = func
    UIDropDownMenu_AddButton(info)
end

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
    local playlists = WML.Library:GetUserPlaylists()

    if #playlists == 0 then
        AddDropdownButton("Create My Playlist", false, function()
            local playlist = WML.Library:GetOrCreateDefaultUserPlaylist(false)
            self.selectedTargetPlaylistId = playlist.id
            self:Refresh()
        end)
        return
    end

    for _, playlist in ipairs(playlists) do
        local playlistId = playlist.id
        AddDropdownButton(playlist.name, playlistId == self.selectedTargetPlaylistId, function()
            self.selectedTargetPlaylistId = playlistId
            self:RefreshTargetDropdown()
        end)
    end
end

function UI:RefreshTargetDropdown()
    if not self.targetDropdown then
        return
    end

    local playlist = self:GetSelectedTargetPlaylist()
    UIDropDownMenu_SetText(self.targetDropdown, playlist and playlist.name or "My Playlist (new)")
end

function UI:BuildContinentDropdown()
    local selected = self.filter.continent or "all"

    AddDropdownButton("All continents", selected == "all", function()
        self.filter.continent = "all"
        self.filter.zone = "all"
        self.filter.biome = "all"
        self:RefreshTracks()
    end)

    for _, continent in ipairs(WML.Library:GetContinents()) do
        AddDropdownButton(continent, selected == continent, function()
            self.filter.continent = continent
            self.filter.zone = "all"
            self.filter.biome = "all"
            self:RefreshTracks()
        end)
    end
end

function UI:BuildZoneDropdown()
    local selectedZone = self.filter.zone or "all"
    local selectedBiome = self.filter.biome or "all"

    AddDropdownButton("All zones/biomes", selectedZone == "all" and selectedBiome == "all", function()
        self.filter.zone = "all"
        self.filter.biome = "all"
        self:RefreshTracks()
    end)

    for _, zone in ipairs(WML.Library:GetZones(self.filter.continent)) do
        AddDropdownButton(zone, selectedZone == zone, function()
            self.filter.zone = zone
            self.filter.biome = "all"
            self:RefreshTracks()
        end)
    end

    for _, biome in ipairs(WML.Library:GetBiomes(self.filter.continent)) do
        local text = "Biome: " .. biome
        AddDropdownButton(text, selectedBiome == biome, function()
            self.filter.zone = "all"
            self.filter.biome = biome
            self:RefreshTracks()
        end)
    end
end

function UI:BuildTimeDropdown()
    local selected = self.filter.timeOfDay or "all"

    AddDropdownButton("Any time", selected == "all", function()
        self.filter.timeOfDay = "all"
        self:RefreshTracks()
    end)

    AddDropdownButton("Day", selected == "day", function()
        self.filter.timeOfDay = "day"
        self:RefreshTracks()
    end)

    AddDropdownButton("Night", selected == "night", function()
        self.filter.timeOfDay = "night"
        self:RefreshTracks()
    end)
end

function UI:RefreshFilterDropdowns()
    if not self.continentDropdown then
        return
    end

    self.filter.continent = self.filter.continent or "all"
    self.filter.zone = self.filter.zone or "all"
    self.filter.biome = self.filter.biome or "all"
    self.filter.timeOfDay = self.filter.timeOfDay or "all"

    if self.filter.zone ~= "all" and not ContainsValue(WML.Library:GetZones(self.filter.continent), self.filter.zone) then
        self.filter.zone = "all"
    end

    if self.filter.biome ~= "all" and not ContainsValue(WML.Library:GetBiomes(self.filter.continent), self.filter.biome) then
        self.filter.biome = "all"
    end

    UIDropDownMenu_SetText(
        self.continentDropdown,
        self.filter.continent ~= "all" and self.filter.continent or "All continents"
    )

    if self.filter.zone ~= "all" then
        UIDropDownMenu_SetText(self.zoneDropdown, self.filter.zone)
    elseif self.filter.biome ~= "all" then
        UIDropDownMenu_SetText(self.zoneDropdown, "Biome: " .. self.filter.biome)
    else
        UIDropDownMenu_SetText(self.zoneDropdown, "All zones/biomes")
    end

    if self.filter.timeOfDay == "day" then
        UIDropDownMenu_SetText(self.timeDropdown, "Day")
    elseif self.filter.timeOfDay == "night" then
        UIDropDownMenu_SetText(self.timeDropdown, "Night")
    else
        UIDropDownMenu_SetText(self.timeDropdown, "Any time")
    end
end

function UI:GetRowsForPlaylist(playlist, isOfficial)
    local rows = {}
    local filters = {
        search = self.searchBox:GetText(),
    }

    if isOfficial then
        filters.continent = self.filter.continent
        filters.zone = self.filter.zone
        filters.biome = self.filter.biome
        filters.timeOfDay = self.filter.timeOfDay

        self:AddTrackRows(rows, WML.Library:FilterTracks(WML.Library:GetPlaylistTracks(playlist.id), filters), "add", playlist.id)
        return rows
    end

    local playlistTracks = WML.Library:FilterTracks(WML.Library:GetPlaylistTracks(playlist.id), filters)
    if #playlistTracks > 0 then
        self:AddHeader(rows, "Playlist Tracks")
        self:AddTrackRows(rows, playlistTracks, "remove", playlist.id)
    else
        self:AddHeader(rows, "No tracks yet")
    end

    return rows
end

function UI:PlayVisibleTrack(shuffle)
    local trackIds = self.visibleTrackIds or {}

    if #trackIds == 0 then
        return
    end

    local index = shuffle and math.random(#trackIds) or 1
    WML.Player:PlayTrack(trackIds[index], self.currentPlaylistId)
end

function UI:AddAllVisibleTracks()
    local targetPlaylist = self:GetTargetPlaylistForAdd()

    if not targetPlaylist then
        return
    end

    WML.Library:AddTracksToPlaylist(targetPlaylist.id, self.visibleTrackIds or {})
end

function UI:RefreshPlaylistActions(isOfficial)
    local hasTracks = self.visibleTrackIds and #self.visibleTrackIds > 0

    SetButtonEnabled(self.playlistPlayButton, hasTracks)
    SetButtonEnabled(self.playlistShuffleButton, hasTracks)
    self.playlistAddAllButton:SetShown(isOfficial)
    SetButtonEnabled(self.playlistAddAllButton, isOfficial and hasTracks)
end

function UI:SetBrowseControlsShown(isOfficial)
    self.targetLabel:SetShown(isOfficial)
    self.targetDropdown:SetShown(isOfficial)
    self.continentDropdown:SetShown(isOfficial)
    self.zoneDropdown:SetShown(isOfficial)
    self.timeDropdown:SetShown(isOfficial)
    self.renameBox:SetShown(not isOfficial)
    self.renameButton:SetShown(not isOfficial)
    self.deleteButton:SetShown(not isOfficial)
end

function UI:RefreshTracks()
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
    self:SetBrowseControlsShown(isOfficial)

    if isOfficial then
        self:RefreshTargetDropdown()
        self:RefreshFilterDropdowns()
    else
        self.renameBox:SetText(playlist.name)
    end

    local rows = self:GetRowsForPlaylist(playlist, isOfficial)
    local visibleTrackIds = {}
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

            table.insert(visibleTrackIds, trackId)
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
                WML.Player:PlayTrack(trackId, playlistId)
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

    self.visibleTrackIds = visibleTrackIds
    self.trackContent:SetSize(self.trackScroll:GetWidth() - 22, math.max(1, -y))
    self:RefreshPlaylistActions(isOfficial)
end
