local WML = WoWMusicLibrary

local UI = WML.UI or {
    sidebarButtons = {},
    trackRows = {},
    selectedTargetPlaylistId = nil,
    filter = {
        continent = "all",
        zone = "all",
        biome = "all",
        timeOfDay = "all",
    },
}

WML.UI = UI

local colors = {
    bg = { 0.04, 0.04, 0.05, 0.98 },
    panel = { 0.08, 0.08, 0.09, 0.95 },
    row = { 0.12, 0.12, 0.13, 0.95 },
    rowActive = { 0.18, 0.28, 0.20, 0.95 },
    border = { 0.18, 0.18, 0.20, 1 },
    accent = { 0.32, 0.78, 0.45, 1 },
}

UI.colors = colors

function UI:SetBackdrop(frame, color)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(color[1], color[2], color[3], color[4])
    frame:SetBackdropBorderColor(colors.border[1], colors.border[2], colors.border[3], colors.border[4])
end

function UI:StyleButton(button)
    button:SetNormalFontObject("GameFontNormal")
    button:SetHighlightFontObject("GameFontHighlight")
end

function UI:SaveSize(frame)
    if not WML.db then
        return
    end

    WML.db.profile.window.width = frame:GetWidth()
    WML.db.profile.window.height = frame:GetHeight()
end

function UI:GetSidebarButton(index)
    local button = self.sidebarButtons[index]
    if button then
        return button
    end

    button = CreateFrame("Button", nil, self.sidebar, "BackdropTemplate")
    self.sidebarButtons[index] = button
    self:SetBackdrop(button, colors.row)
    button:SetHeight(28)
    button:SetPoint("LEFT", 12, 0)
    button:SetPoint("RIGHT", -12, 0)
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.text:SetPoint("LEFT", 8, 0)
    button.text:SetPoint("RIGHT", -8, 0)
    button.text:SetJustifyH("LEFT")

    return button
end

function UI:GetTrackRow(index)
    local row = self.trackRows[index]
    if row then
        return row
    end

    row = CreateFrame("Frame", nil, self.trackContent, "BackdropTemplate")
    self.trackRows[index] = row
    self:SetBackdrop(row, colors.row)
    row:SetHeight(38)

    row.play = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    self:StyleButton(row.play)
    row.play:SetSize(30, 22)
    row.play:SetPoint("LEFT", 8, 0)
    row.play:SetText(">")

    row.like = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    self:StyleButton(row.like)
    row.like:SetSize(52, 22)
    row.like:SetPoint("LEFT", row.play, "RIGHT", 6, 0)

    row.title = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.title:SetPoint("LEFT", 104, 7)
    row.title:SetPoint("RIGHT", -98, 7)
    row.title:SetJustifyH("LEFT")

    row.meta = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.meta:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -2)
    row.meta:SetPoint("RIGHT", row.title, "RIGHT", 0, 0)
    row.meta:SetJustifyH("LEFT")

    row.action = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    self:StyleButton(row.action)
    row.action:SetSize(72, 22)
    row.action:SetPoint("RIGHT", -8, 0)

    return row
end

function UI:AddHeader(rows, text)
    rows[#rows + 1] = { kind = "header", text = text }
end

function UI:AddTrackRows(rows, sourceTracks, action, playlistId)
    for _, track in ipairs(sourceTracks) do
        rows[#rows + 1] = {
            kind = "track",
            track = track,
            action = action,
            playlistId = playlistId,
        }
    end
end
