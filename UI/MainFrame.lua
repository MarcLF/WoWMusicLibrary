local WML = WoWMusicLibrary
local UI = WML.UI

local MIN_WIDTH = 960
local MIN_HEIGHT = 430
local MAX_WIDTH = 1200
local MAX_HEIGHT = 800

function UI:Initialize()
    self:CreateFrame()
    self:Refresh()
end

function UI:CreateFrame()
    local frame = CreateFrame("Frame", "WoWMusicLibraryFrame", UIParent, "BackdropTemplate")
    self.frame = frame

    self:SetBackdrop(frame, self.colors.bg)
    frame:SetSize(math.max(WML.db.profile.window.width or MIN_WIDTH, MIN_WIDTH), math.max(WML.db.profile.window.height or 560, MIN_HEIGHT))
    frame:SetPoint("CENTER")
    frame:SetClampedToScreen(true)
    frame:SetResizable(true)
    frame:SetResizeBounds(MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT)
    frame:EnableMouse(true)
    frame:Hide()

    local LibWindow = LibStub("LibWindow-1.1", true)
    if LibWindow then
        LibWindow.RegisterConfig(frame, WML.db.profile.window)
        LibWindow.RestorePosition(frame)
        LibWindow.MakeDraggable(frame)
    else
        frame:SetMovable(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    end

    frame:SetScript("OnSizeChanged", function(resizedFrame)
        UI:SaveSize(resizedFrame)
    end)

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -4, -4)

    local resizeButton = CreateFrame("Button", nil, frame, "PanelResizeButtonTemplate")
    resizeButton:SetPoint("BOTTOMRIGHT", -5, 5)
    if resizeButton.Init then
        resizeButton:Init(frame, MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT)
        resizeButton:SetOnResizeStoppedCallback(function(resizedFrame)
            UI:SaveSize(resizedFrame)
        end)
    else
        resizeButton:SetSize(16, 16)
        resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        resizeButton:SetScript("OnMouseDown", function()
            frame:StartSizing("BOTTOMRIGHT")
        end)
        resizeButton:SetScript("OnMouseUp", function()
            frame:StopMovingOrSizing()
            UI:SaveSize(frame)
        end)
    end

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 18, -16)
    title:SetText("WoW Music Library")

    local sidebar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    self.sidebar = sidebar
    self:SetBackdrop(sidebar, self.colors.panel)
    sidebar:SetPoint("TOPLEFT", 12, -46)
    sidebar:SetPoint("BOTTOMLEFT", 12, 92)
    sidebar:SetWidth(220)

    local main = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    self.main = main
    self:SetBackdrop(main, self.colors.panel)
    main:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 10, 0)
    main:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 92)

    local bottom = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    self.bottom = bottom
    self:SetBackdrop(bottom, self.colors.panel)
    bottom:SetPoint("LEFT", 12, 0)
    bottom:SetPoint("RIGHT", -12, 0)
    bottom:SetPoint("BOTTOM", 0, 12)
    bottom:SetHeight(70)

    self:CreateSidebar()
    self:CreateMain()
    self:CreatePlayerBar()
end

function UI:CreateSidebar()
    local header = self.sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", 12, -12)
    header:SetText("Browse")
    self.officialHeader = header

    local userHeader = self.sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    userHeader:SetText("User Playlists")
    self.userHeader = userHeader

    local newBox = CreateFrame("EditBox", nil, self.sidebar, "InputBoxTemplate")
    self.newBox = newBox
    newBox:SetSize(132, 24)
    newBox:SetAutoFocus(false)
    newBox:SetPoint("BOTTOMLEFT", 12, 46)
    self:StyleEditBox(newBox)

    local newButton = CreateFrame("Button", nil, self.sidebar, "UIPanelButtonTemplate")
    self:StyleButton(newButton)
    newButton:SetSize(54, 24)
    newButton:SetPoint("LEFT", newBox, "RIGHT", 6, 0)
    newButton:SetText("New")
    newButton:SetScript("OnClick", function()
        WML.Library:CreatePlaylist(newBox:GetText())
        newBox:SetText("")
    end)

    local settingsButton = CreateFrame("Button", nil, self.sidebar, "UIPanelButtonTemplate")
    self:StyleButton(settingsButton)
    settingsButton:SetSize(188, 24)
    settingsButton:SetPoint("BOTTOMLEFT", 12, 14)
    settingsButton:SetText("Settings")
    settingsButton:SetScript("OnClick", function()
        WML:OpenOptions()
    end)
end

function UI:CreateMain()
    local playlistTitle = self.main:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.playlistTitle = playlistTitle
    playlistTitle:SetPoint("TOPLEFT", 14, -14)
    playlistTitle:SetPoint("RIGHT", -220, 0)
    playlistTitle:SetJustifyH("LEFT")

    local addAll = CreateFrame("Button", nil, self.main, "UIPanelButtonTemplate")
    self.playlistAddAllButton = addAll
    self:StyleButton(addAll)
    addAll:SetSize(78, 24)
    addAll:SetPoint("TOPRIGHT", -14, -12)
    addAll:SetText("Add all")
    addAll:SetScript("OnClick", function()
        UI:AddAllVisibleTracks()
    end)

    local shuffle = CreateFrame("Button", nil, self.main, "UIPanelButtonTemplate")
    self.playlistShuffleButton = shuffle
    self:StyleButton(shuffle)
    shuffle:SetSize(66, 24)
    shuffle:SetPoint("RIGHT", addAll, "LEFT", -6, 0)
    shuffle:SetText("Shuffle")
    shuffle:SetScript("OnClick", function()
        UI:PlayVisibleTrack(true)
    end)

    local play = CreateFrame("Button", nil, self.main, "UIPanelButtonTemplate")
    self.playlistPlayButton = play
    self:StyleButton(play)
    play:SetSize(52, 24)
    play:SetPoint("RIGHT", shuffle, "LEFT", -6, 0)
    play:SetText("Play")
    play:SetScript("OnClick", function()
        UI:PlayVisibleTrack(false)
    end)

    local search = CreateFrame("EditBox", nil, self.main, "InputBoxTemplate")
    self.searchBox = search
    search:SetSize(200, 24)
    search:SetPoint("TOPLEFT", 14, -46)
    search:SetAutoFocus(false)
    self:StyleEditBox(search)
    search:SetScript("OnTextChanged", function(_, userInput)
        if userInput then
            UI:RefreshTracks()
        end
    end)

    local continentDropdown = CreateFrame("Frame", "WoWMusicLibraryContinentDropdown", self.main, "UIDropDownMenuTemplate")
    self.continentDropdown = continentDropdown
    continentDropdown:SetPoint("LEFT", search, "RIGHT", -4, -2)
    UIDropDownMenu_SetWidth(continentDropdown, 128)
    self:StyleDropdown(continentDropdown)
    UIDropDownMenu_Initialize(continentDropdown, function()
        UI:BuildContinentDropdown()
    end)

    local zoneDropdown = CreateFrame("Frame", "WoWMusicLibraryZoneDropdown", self.main, "UIDropDownMenuTemplate")
    self.zoneDropdown = zoneDropdown
    zoneDropdown:SetPoint("LEFT", continentDropdown, "RIGHT", -14, 0)
    UIDropDownMenu_SetWidth(zoneDropdown, 142)
    self:StyleDropdown(zoneDropdown)
    UIDropDownMenu_Initialize(zoneDropdown, function()
        UI:BuildZoneDropdown()
    end)

    local timeDropdown = CreateFrame("Frame", "WoWMusicLibraryTimeDropdown", self.main, "UIDropDownMenuTemplate")
    self.timeDropdown = timeDropdown
    timeDropdown:SetPoint("LEFT", zoneDropdown, "RIGHT", -14, 0)
    UIDropDownMenu_SetWidth(timeDropdown, 96)
    self:StyleDropdown(timeDropdown)
    UIDropDownMenu_Initialize(timeDropdown, function()
        UI:BuildTimeDropdown()
    end)

    local targetLabel = self.main:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.targetLabel = targetLabel
    targetLabel:SetPoint("TOPLEFT", 18, -78)
    targetLabel:SetText("Add to")

    local targetDropdown = CreateFrame("Frame", "WoWMusicLibraryTargetDropdown", self.main, "UIDropDownMenuTemplate")
    self.targetDropdown = targetDropdown
    targetDropdown:SetPoint("LEFT", targetLabel, "RIGHT", -8, -2)
    UIDropDownMenu_SetWidth(targetDropdown, 170)
    self:StyleDropdown(targetDropdown)
    UIDropDownMenu_Initialize(targetDropdown, function()
        UI:BuildTargetDropdown()
    end)

    local rename = CreateFrame("EditBox", nil, self.main, "InputBoxTemplate")
    self.renameBox = rename
    rename:SetSize(170, 24)
    rename:SetPoint("LEFT", search, "RIGHT", 14, 0)
    rename:SetAutoFocus(false)
    self:StyleEditBox(rename)

    local renameButton = CreateFrame("Button", nil, self.main, "UIPanelButtonTemplate")
    self.renameButton = renameButton
    self:StyleButton(renameButton)
    renameButton:SetSize(70, 24)
    renameButton:SetPoint("LEFT", rename, "RIGHT", 6, 0)
    renameButton:SetText("Rename")
    renameButton:SetScript("OnClick", function()
        WML.Library:RenamePlaylist(WML.db.profile.selectedPlaylistId, rename:GetText())
    end)

    local deleteButton = CreateFrame("Button", nil, self.main, "UIPanelButtonTemplate")
    self.deleteButton = deleteButton
    self:StyleButton(deleteButton)
    deleteButton:SetSize(62, 24)
    deleteButton:SetPoint("LEFT", renameButton, "RIGHT", 6, 0)
    deleteButton:SetText("Delete")
    deleteButton:SetScript("OnClick", function()
        WML.Library:DeletePlaylist(WML.db.profile.selectedPlaylistId)
    end)

    local scroll = CreateFrame("ScrollFrame", nil, self.main, "UIPanelScrollFrameTemplate")
    self.trackScroll = scroll
    scroll:SetPoint("TOPLEFT", 14, -110)
    scroll:SetPoint("BOTTOMRIGHT", -30, 14)

    local content = CreateFrame("Frame", nil, scroll)
    self.trackContent = content
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)
end

function UI:CreatePlayerBar()
    local prev = CreateFrame("Button", nil, self.bottom, "UIPanelButtonTemplate")
    self:StyleButton(prev)
    prev:SetSize(34, 28)
    prev:SetPoint("LEFT", 14, 0)
    prev:SetText("<<")
    prev:SetScript("OnClick", function()
        WML.Player:Previous()
    end)

    local play = CreateFrame("Button", nil, self.bottom, "UIPanelButtonTemplate")
    self.playButton = play
    self:StyleButton(play)
    play:SetSize(52, 28)
    play:SetPoint("LEFT", prev, "RIGHT", 6, 0)
    play:SetScript("OnClick", function()
        WML.Player:TogglePlay()
    end)

    local stop = CreateFrame("Button", nil, self.bottom, "UIPanelButtonTemplate")
    self:StyleButton(stop)
    stop:SetSize(44, 28)
    stop:SetPoint("LEFT", play, "RIGHT", 6, 0)
    stop:SetText("Stop")
    stop:SetScript("OnClick", function()
        WML.Player:Stop()
    end)

    local next = CreateFrame("Button", nil, self.bottom, "UIPanelButtonTemplate")
    self:StyleButton(next)
    next:SetSize(34, 28)
    next:SetPoint("LEFT", stop, "RIGHT", 6, 0)
    next:SetText(">>")
    next:SetScript("OnClick", function()
        WML.Player:Next()
    end)

    local nowPlaying = self.bottom:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    self.nowPlaying = nowPlaying
    nowPlaying:SetPoint("LEFT", next, "RIGHT", 14, 0)
    nowPlaying:SetPoint("RIGHT", -18, 0)
    nowPlaying:SetJustifyH("LEFT")

    local progress = CreateFrame("StatusBar", nil, self.bottom)
    self.progress = progress
    progress:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    progress:SetStatusBarColor(self.colors.accent[1], self.colors.accent[2], self.colors.accent[3], 1)
    progress:SetMinMaxValues(0, 1)
    progress:SetValue(0)
    progress:SetPoint("LEFT", nowPlaying, 0, -22)
    progress:SetPoint("RIGHT", nowPlaying, 0, -22)
    progress:SetHeight(4)
    self:SkinBox(progress, self.colors.input, self.colors.border)
end

function UI:IsShown()
    return self.frame and self.frame:IsShown()
end

function UI:Show()
    self.frame:Show()
    self:Refresh()
end

function UI:Hide()
    self.frame:Hide()
end

function UI:ResetPosition()
    wipe(WML.db.profile.window)
    self.frame:ClearAllPoints()
    self.frame:SetSize(MIN_WIDTH, 560)
    self.frame:SetPoint("CENTER")
    self:SaveSize(self.frame)
end

function UI:RefreshSidebar()
    local selectedPlaylistId = WML.db.profile.selectedPlaylistId
    local y = -36
    local index = 1

    for _, playlist in ipairs(WML.Library:GetOfficialPlaylists()) do
        local playlistId = playlist.id
        local button = self:GetSidebarButton(index)
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", self.sidebar, "TOPLEFT", 12, y)
        button:SetPoint("RIGHT", self.sidebar, "RIGHT", -12, 0)
        button.text:SetText(playlist.name)
        self:SetBackdrop(button, playlistId == selectedPlaylistId and self.colors.rowActive or self.colors.row, playlistId == selectedPlaylistId and self.colors.borderBright or self.colors.border)
        button:SetScript("OnClick", function()
            WML.Library:SelectPlaylist(playlistId)
        end)
        button:Show()
        y = y - 32
        index = index + 1
    end

    self.userHeader:ClearAllPoints()
    self.userHeader:SetPoint("TOPLEFT", self.sidebar, "TOPLEFT", 12, y - 10)
    y = y - 34

    for _, playlist in ipairs(WML.Library:GetUserPlaylists()) do
        local playlistId = playlist.id
        local button = self:GetSidebarButton(index)
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", self.sidebar, "TOPLEFT", 12, y)
        button:SetPoint("RIGHT", self.sidebar, "RIGHT", -12, 0)
        button.text:SetText(playlist.name)
        self:SetBackdrop(button, playlistId == selectedPlaylistId and self.colors.rowActive or self.colors.row, playlistId == selectedPlaylistId and self.colors.borderBright or self.colors.border)
        button:SetScript("OnClick", function()
            WML.Library:SelectPlaylist(playlistId)
        end)
        button:Show()
        y = y - 32
        index = index + 1
    end

    for i = index, #self.sidebarButtons do
        self.sidebarButtons[i]:Hide()
    end
end

function UI:RefreshPlayerBar()
    local state = WML.Player:GetState()

    self.playButton:SetText(state.isPlaying and "Pause" or "Play")
    self.progress:SetValue(state.isPlaying and 1 or 0)

    if state.track then
        self.nowPlaying:SetText(state.track.title .. " - " .. state.track.artist)
    else
        self.nowPlaying:SetText("No track selected")
    end
end

function UI:Refresh()
    if not self.frame then
        return
    end

    self:RefreshSidebar()
    self:RefreshTracks()
    self:RefreshPlayerBar()
end
