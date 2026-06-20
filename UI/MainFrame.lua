local WML = SpotiWoW
local UI = WML.UI

local MIN_WIDTH = 960
local MIN_HEIGHT = 560
local MAX_WIDTH = 1200
local MAX_HEIGHT = 800
local MINI_WIDTH = 360
local MINI_HEIGHT = 128
local MINI_COLLAPSED_WIDTH = 314
local MINI_COLLAPSED_HEIGHT = 40

local function AddDropdownOption(options, text, checked, func)
    table.insert(options, {
        text = text,
        checked = checked,
        func = func,
    })
end

local function CreateCloseButton(parent, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    UI:StyleButton(button)
    button:SetSize(22, 22)
    button:SetText("x")
    button:SetScript("OnClick", onClick or function()
        parent:Hide()
    end)
    return button
end

function UI:Initialize()
    self:CreateFrame()
    self:Refresh()
end

function UI:CreateFrame()
    local frame = CreateFrame("Frame", "SpotiWoWFrame", UIParent, "BackdropTemplate")
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

    local closeButton = CreateCloseButton(frame)
    closeButton:SetPoint("TOPRIGHT", -8, -8)

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
    title:SetText("SpotiWoW")

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
    self:CreateMiniPlayer()
end

function UI:CreateSidebar()
    self.officialSidebarButtons = self.officialSidebarButtons or {}
    self.userSidebarButtons = self.userSidebarButtons or {}

    local header = self.sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", 12, -12)
    header:SetText("Browse")
    self.officialHeader = header

    local officialScroll = CreateFrame("ScrollFrame", "SpotiWoWOfficialPlaylistScroll", self.sidebar, "UIPanelScrollFrameTemplate")
    self.officialScroll = officialScroll
    officialScroll:SetPoint("TOPLEFT", 12, -36)
    officialScroll:SetPoint("TOPRIGHT", self.sidebar, "TOPRIGHT", -30, -36)
    officialScroll:SetHeight(160)
    self:StyleScrollBar(officialScroll)

    local officialContent = CreateFrame("Frame", nil, officialScroll)
    self.officialContent = officialContent
    officialContent:SetSize(1, 1)
    officialScroll:SetScrollChild(officialContent)

    local userHeader = self.sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    userHeader:SetText("User Playlists")
    userHeader:SetPoint("TOPLEFT", officialScroll, "BOTTOMLEFT", 0, -14)
    self.userHeader = userHeader

    local userScroll = CreateFrame("ScrollFrame", "SpotiWoWUserPlaylistScroll", self.sidebar, "UIPanelScrollFrameTemplate")
    self.userScroll = userScroll
    userScroll:SetPoint("TOPLEFT", 12, -234)
    userScroll:SetPoint("TOPRIGHT", self.sidebar, "TOPRIGHT", -30, -234)
    userScroll:SetHeight(160)
    self:StyleScrollBar(userScroll)

    local userContent = CreateFrame("Frame", nil, userScroll)
    self.userContent = userContent
    userContent:SetSize(1, 1)
    userScroll:SetScrollChild(userContent)

    local newBox = CreateFrame("EditBox", nil, self.sidebar, "InputBoxTemplate")
    self.newBox = newBox
    newBox:SetSize(122, 24)
    newBox:SetAutoFocus(false)
    newBox:SetPoint("BOTTOMLEFT", 12, 46)
    self:StyleEditBox(newBox)

    local newButton = CreateFrame("Button", nil, self.sidebar, "UIPanelButtonTemplate")
    self:StyleButton(newButton)
    newButton:SetSize(54, 24)
    newButton:SetPoint("LEFT", newBox, "RIGHT", 4, 0)
    newButton:SetText("New")
    newButton:SetScript("OnClick", function()
        WML.Library:CreatePlaylist(newBox:GetText())
        newBox:SetText("")
    end)

    local settingsButton = CreateFrame("Button", nil, self.sidebar, "UIPanelButtonTemplate")
    self.settingsButton = settingsButton
    self:StyleButton(settingsButton)
    settingsButton:SetSize(180, 24)
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

    local play = CreateFrame("Button", nil, self.main, "UIPanelButtonTemplate")
    self.playlistPlayButton = play
    self:StyleButton(play)
    play:SetSize(52, 24)
    play:SetPoint("RIGHT", addAll, "LEFT", -6, 0)
    play:SetText("Play")
    play:SetScript("OnClick", function()
        UI:PlayVisibleTrack(false)
    end)

    local search = CreateFrame("EditBox", nil, self.main, "InputBoxTemplate")
    self.searchBox = search
    search:SetSize(430, 28)
    search:SetPoint("TOPLEFT", 14, -46)
    search:SetAutoFocus(false)
    self:StyleEditBox(search)
    search:SetScript("OnTextChanged", function(_, userInput)
        if userInput then
            UI:RefreshTracks()
        end
    end)

    local zoneDropdown = self:CreateDropdown(self.main, 230, function()
        return UI:BuildZoneDropdown()
    end)
    self.zoneDropdown = zoneDropdown
    zoneDropdown:SetPoint("TOPLEFT", self.main, "TOPLEFT", 14, -80)

    local timeDropdown = self:CreateDropdown(self.main, 140, function()
        return UI:BuildTimeDropdown()
    end)
    self.timeDropdown = timeDropdown
    timeDropdown:SetPoint("TOPLEFT", zoneDropdown, "TOPRIGHT", 8, 0)

    local targetLabel = self.main:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.targetLabel = targetLabel
    targetLabel:SetPoint("TOPLEFT", 18, -130)
    targetLabel:SetText("Add to")

    local targetDropdown = self:CreateDropdown(self.main, 240, function()
        return UI:BuildTargetDropdown()
    end)
    self.targetDropdown = targetDropdown
    targetDropdown:SetPoint("TOPLEFT", self.main, "TOPLEFT", 74, -122)

    local nextPage = CreateFrame("Button", nil, self.main, "UIPanelButtonTemplate")
    self.nextPageButton = nextPage
    self:StyleButton(nextPage)
    nextPage:SetSize(54, 24)
    nextPage:SetPoint("TOPRIGHT", self.main, "TOPRIGHT", -14, -124)
    nextPage:SetText("Next")
    nextPage:SetScript("OnClick", function()
        UI:SetTrackPage((UI.trackPage or 1) + 1)
    end)

    local prevPage = CreateFrame("Button", nil, self.main, "UIPanelButtonTemplate")
    self.prevPageButton = prevPage
    self:StyleButton(prevPage)
    prevPage:SetSize(54, 24)
    prevPage:SetPoint("RIGHT", nextPage, "LEFT", -6, 0)
    prevPage:SetText("Prev")
    prevPage:SetScript("OnClick", function()
        UI:SetTrackPage((UI.trackPage or 1) - 1)
    end)

    local pageText = self.main:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    self.pageText = pageText
    pageText:SetPoint("RIGHT", prevPage, "LEFT", -8, 0)
    pageText:SetWidth(150)
    pageText:SetJustifyH("RIGHT")

    local rename = CreateFrame("EditBox", nil, self.main, "InputBoxTemplate")
    self.renameBox = rename
    rename:SetSize(220, 28)
    rename:SetPoint("TOPLEFT", self.main, "TOPLEFT", 14, -80)
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

    local settingsPanel = CreateFrame("Frame", nil, self.main)
    self.settingsPanel = settingsPanel
    settingsPanel:SetPoint("TOPLEFT", self.main, "TOPLEFT", 14, -56)
    settingsPanel:SetPoint("BOTTOMRIGHT", self.main, "BOTTOMRIGHT", -14, 14)

    local audioLabel = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    audioLabel:SetPoint("TOPLEFT", 0, -8)
    audioLabel:SetText("Audio channel")

    local audioDropdown = self:CreateDropdown(settingsPanel, 220, function()
        return UI:BuildAudioChannelDropdown()
    end)
    self.audioChannelDropdown = audioDropdown
    audioDropdown:SetPoint("TOPLEFT", 120, 0)

    local resetButton = CreateFrame("Button", nil, settingsPanel, "UIPanelButtonTemplate")
    self.resetWindowButton = resetButton
    self:StyleButton(resetButton)
    resetButton:SetSize(150, 26)
    resetButton:SetPoint("TOPLEFT", 120, -42)
    resetButton:SetText("Reset window")
    resetButton:SetScript("OnClick", function()
        UI:ResetPosition()
    end)

    local miniButton = CreateFrame("Button", nil, settingsPanel, "UIPanelButtonTemplate")
    self.openMiniPlayerButton = miniButton
    self:StyleButton(miniButton)
    miniButton:SetSize(150, 26)
    miniButton:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", 0, -8)
    miniButton:SetText("Open mini player")
    miniButton:SetScript("OnClick", function()
        UI:ShowMiniPlayer()
    end)

    local miniOpacityLabel = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    miniOpacityLabel:SetPoint("TOPLEFT", 0, -116)
    miniOpacityLabel:SetText("Mini opacity")

    local miniOpacityDropdown = self:CreateDropdown(settingsPanel, 150, function()
        return UI:BuildMiniOpacityDropdown()
    end)
    self.miniOpacityDropdown = miniOpacityDropdown
    miniOpacityDropdown:SetPoint("TOPLEFT", 120, -108)

    local scroll = CreateFrame("ScrollFrame", "SpotiWoWTrackScroll", self.main, "UIPanelScrollFrameTemplate")
    self.trackScroll = scroll
    scroll:SetPoint("TOPLEFT", 14, -166)
    scroll:SetPoint("BOTTOMRIGHT", -30, 14)
    self:StyleScrollBar(scroll)

    local content = CreateFrame("Frame", nil, scroll)
    self.trackContent = content
    content:SetSize(1, 1)
    scroll:SetScrollChild(content)
end

function UI:CreatePlayerBar()
    local shuffle = CreateFrame("Button", nil, self.bottom, "UIPanelButtonTemplate")
    self.shuffleButton = shuffle
    self:StyleButton(shuffle)
    shuffle:SetSize(58, 28)
    shuffle:SetPoint("LEFT", 14, 0)
    shuffle:SetText("Shuffle")
    shuffle:SetScript("OnClick", function()
        UI:ToggleShuffle()
    end)

    local prev = CreateFrame("Button", nil, self.bottom, "UIPanelButtonTemplate")
    self:StyleButton(prev)
    prev:SetSize(34, 28)
    prev:SetPoint("LEFT", shuffle, "RIGHT", 6, 0)
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

function UI:CreateMiniPlayer()
    local frame = CreateFrame("Frame", "SpotiWoWMiniPlayer", UIParent, "BackdropTemplate")
    self.miniFrame = frame

    WML.db.profile.miniWindow = WML.db.profile.miniWindow or {}

    self:SetBackdrop(frame, self.colors.bg)
    self:ApplyMiniPlayerOpacity()
    frame:SetSize(MINI_WIDTH, MINI_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 180)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetFrameStrata("DIALOG")
    frame:Hide()

    local LibWindow = LibStub("LibWindow-1.1", true)
    if LibWindow then
        LibWindow.RegisterConfig(frame, WML.db.profile.miniWindow)
        LibWindow.RestorePosition(frame)
        LibWindow.MakeDraggable(frame)
    else
        frame:SetMovable(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    end

    local closeButton = CreateCloseButton(frame)
    self.miniCloseButton = closeButton

    local title = CreateFrame("Button", nil, frame)
    self.miniTitleButton = title
    title.text = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title.text:SetAllPoints()
    title.text:SetJustifyH("LEFT")
    title.text:SetText("SpotiWoW")
    title:SetPoint("TOPLEFT", 12, -12)
    title:SetSize(90, 22)
    title:SetScript("OnClick", function()
        UI:ToggleMiniCollapsed()
    end)

    local playlistDropdown = self:CreateDropdown(frame, MINI_WIDTH - 24, function()
        return UI:BuildMiniPlaylistDropdown()
    end)
    self.miniPlaylistDropdown = playlistDropdown
    playlistDropdown:SetPoint("TOPLEFT", 12, -36)

    local prev = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    self.miniPrevButton = prev
    self:StyleButton(prev)
    prev:SetSize(34, 26)
    prev:SetPoint("TOPLEFT", 12, -70)
    prev:SetText("<<")
    prev:SetScript("OnClick", function()
        WML.Player:Previous()
    end)

    local play = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    self.miniPlayButton = play
    self:StyleButton(play)
    play:SetSize(52, 26)
    play:SetPoint("LEFT", prev, "RIGHT", 6, 0)
    play:SetScript("OnClick", function()
        WML.Player:TogglePlay()
    end)

    local stop = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    self.miniStopButton = stop
    self:StyleButton(stop)
    stop:SetSize(44, 26)
    stop:SetPoint("LEFT", play, "RIGHT", 6, 0)
    stop:SetText("Stop")
    stop:SetScript("OnClick", function()
        WML.Player:Stop()
    end)

    local next = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    self.miniNextButton = next
    self:StyleButton(next)
    next:SetSize(34, 26)
    next:SetPoint("LEFT", stop, "RIGHT", 6, 0)
    next:SetText(">>")
    next:SetScript("OnClick", function()
        WML.Player:Next()
    end)

    local shuffle = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    self.miniShuffleButton = shuffle
    self:StyleButton(shuffle)
    shuffle:SetSize(58, 26)
    shuffle:SetPoint("LEFT", next, "RIGHT", 6, 0)
    shuffle:SetText("Shuffle")
    shuffle:SetScript("OnClick", function()
        UI:ToggleShuffle()
    end)

    local nowPlaying = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    self.miniNowPlaying = nowPlaying
    nowPlaying:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -10)
    nowPlaying:SetPoint("RIGHT", -12, 0)
    nowPlaying:SetJustifyH("LEFT")

    self:SetMiniCollapsed(WML.db.profile.miniCollapsed)
end

function UI:ShowMiniPlayer()
    self:SetMiniCollapsed(WML.db.profile.miniCollapsed)
    self.miniFrame:Show()
    self.miniFrame:Raise()
    self:RefreshMiniPlayer()
end

function UI:GetMiniPlayerOpacity()
    return math.min(1, math.max(0.5, tonumber(WML.db.profile.miniBackgroundOpacity) or 1))
end

function UI:ApplyMiniPlayerOpacity()
    if not self.miniFrame then
        return
    end

    local color = self.colors.bg
    self.miniFrame:SetBackdropColor(color[1], color[2], color[3], self:GetMiniPlayerOpacity())
end

function UI:ToggleMiniCollapsed()
    self:SetMiniCollapsed(not WML.db.profile.miniCollapsed)
end

function UI:SetMiniCollapsed(collapsed)
    if not self.miniFrame then
        return
    end

    collapsed = collapsed and true or false
    WML.db.profile.miniCollapsed = collapsed
    self:CloseDropdowns()

    self.miniFrame:SetSize(collapsed and MINI_COLLAPSED_WIDTH or MINI_WIDTH, collapsed and MINI_COLLAPSED_HEIGHT or MINI_HEIGHT)
    self.miniPlaylistDropdown:SetShown(not collapsed)
    self.miniShuffleButton:SetShown(not collapsed)
    self.miniNowPlaying:SetShown(not collapsed)

    self.miniCloseButton:ClearAllPoints()
    self.miniCloseButton:SetPoint("TOPRIGHT", -8, -8)

    self.miniTitleButton:ClearAllPoints()
    self.miniTitleButton:SetPoint("TOPLEFT", collapsed and 10 or 12, collapsed and -9 or -10)
    self.miniTitleButton:SetSize(collapsed and 74 or 110, 22)

    self.miniPrevButton:ClearAllPoints()
    if collapsed then
        self.miniPrevButton:SetPoint("LEFT", self.miniTitleButton, "RIGHT", 6, 0)
    else
        self.miniPrevButton:SetPoint("TOPLEFT", 12, -70)
    end

    self.miniPlayButton:ClearAllPoints()
    self.miniPlayButton:SetPoint("LEFT", self.miniPrevButton, "RIGHT", 6, 0)

    self.miniStopButton:ClearAllPoints()
    self.miniStopButton:SetPoint("LEFT", self.miniPlayButton, "RIGHT", 6, 0)

    self.miniNextButton:ClearAllPoints()
    self.miniNextButton:SetPoint("LEFT", self.miniStopButton, "RIGHT", 6, 0)

    self.miniShuffleButton:ClearAllPoints()
    self.miniShuffleButton:SetPoint("LEFT", self.miniNextButton, "RIGHT", 6, 0)

    self:ApplyMiniPlayerOpacity()
end

function UI:GetMiniPlaylistId()
    if WML.db.profile.selectedPlaylistId ~= WML.settingsPlaylistId then
        return WML.db.profile.selectedPlaylistId
    end

    return WML.Player.playlistId
end

function UI:BuildMiniPlaylistDropdown()
    local options = {}
    local selectedPlaylistId = self:GetMiniPlaylistId()

    for _, playlist in ipairs(WML.Library:GetOfficialPlaylists()) do
        local playlistId = playlist.id
        AddDropdownOption(options, playlist.name, playlistId == selectedPlaylistId, function()
            WML.Player:SetQueue(playlistId)
            WML.Library:SelectPlaylist(playlistId)
        end)
    end

    for _, playlist in ipairs(WML.Library:GetUserPlaylists()) do
        local playlistId = playlist.id
        AddDropdownOption(options, playlist.name, playlistId == selectedPlaylistId, function()
            WML.Player:SetQueue(playlistId)
            WML.Library:SelectPlaylist(playlistId)
        end)
    end

    return options
end

function UI:RefreshMiniPlayer(state)
    if not self.miniFrame then
        return
    end

    state = state or WML.Player:GetState()

    self.miniPlayButton:SetText(state.isPlaying and "Pause" or "Play")
    self:SetButtonActive(self.miniShuffleButton, WML.db.profile.shuffle)

    local playlist = WML.Library:GetPlaylist(self:GetMiniPlaylistId())
    self:SetDropdownText(self.miniPlaylistDropdown, playlist and playlist.name or "Select playlist")

    if state.track then
        self.miniNowPlaying:SetText(state.track.title .. " - " .. state.track.artist)
    else
        self.miniNowPlaying:SetText("No track selected")
    end
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
    local officialY = 0
    local officialIndex = 1

    for _, playlist in ipairs(WML.Library:GetOfficialPlaylists()) do
        local playlistId = playlist.id
        local button = self:GetSidebarButton(officialIndex, self.officialContent, self.officialSidebarButtons)
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", self.officialContent, "TOPLEFT", 0, officialY)
        button:SetPoint("RIGHT", self.officialContent, "RIGHT", 0, 0)
        button.text:SetText(playlist.name)
        self:SetBackdrop(button, playlistId == selectedPlaylistId and self.colors.rowActive or self.colors.row, playlistId == selectedPlaylistId and self.colors.borderBright or self.colors.border)
        button:SetScript("OnClick", function()
            WML.Library:SelectPlaylist(playlistId)
        end)
        button:Show()
        officialY = officialY - 32
        officialIndex = officialIndex + 1
    end

    for i = officialIndex, #self.officialSidebarButtons do
        self.officialSidebarButtons[i]:Hide()
    end

    local officialWidth = self.officialScroll:GetWidth() or 0
    if officialWidth <= 1 then
        officialWidth = 178
    end
    self.officialContent:SetSize(math.max(1, officialWidth - 22), math.max(1, -officialY))

    local userY = 0
    local userIndex = 1

    for _, playlist in ipairs(WML.Library:GetUserPlaylists()) do
        local playlistId = playlist.id
        local button = self:GetSidebarButton(userIndex, self.userContent, self.userSidebarButtons)
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", self.userContent, "TOPLEFT", 0, userY)
        button:SetPoint("RIGHT", self.userContent, "RIGHT", 0, 0)
        button.text:SetText(playlist.name)
        self:SetBackdrop(button, playlistId == selectedPlaylistId and self.colors.rowActive or self.colors.row, playlistId == selectedPlaylistId and self.colors.borderBright or self.colors.border)
        button:SetScript("OnClick", function()
            WML.Library:SelectPlaylist(playlistId)
        end)
        button:Show()
        userY = userY - 32
        userIndex = userIndex + 1
    end

    for i = userIndex, #self.userSidebarButtons do
        self.userSidebarButtons[i]:Hide()
    end

    local userWidth = self.userScroll:GetWidth() or 0
    if userWidth <= 1 then
        userWidth = 178
    end
    self.userContent:SetSize(math.max(1, userWidth - 22), math.max(1, -userY))

    self:SetButtonActive(self.settingsButton, selectedPlaylistId == WML.settingsPlaylistId)
end

function UI:RefreshPlayerBar()
    local state = WML.Player:GetState()

    self.playButton:SetText(state.isPlaying and "Pause" or "Play")
    self:SetButtonActive(self.shuffleButton, WML.db.profile.shuffle)
    self.progress:SetValue(state.isPlaying and 1 or 0)

    if state.track then
        self.nowPlaying:SetText(state.track.title .. " - " .. state.track.artist)
    else
        self.nowPlaying:SetText("No track selected")
    end

    self:RefreshMiniPlayer(state)
end

function UI:Refresh()
    if not self.frame then
        return
    end

    self:RefreshSidebar()
    self:RefreshTracks()
    self:RefreshPlayerBar()
end
