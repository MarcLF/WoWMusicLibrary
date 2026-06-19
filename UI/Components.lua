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
    bg = { 0.035, 0.04, 0.045, 0.98 },
    panel = { 0.07, 0.075, 0.085, 0.96 },
    row = { 0.095, 0.10, 0.11, 0.96 },
    rowActive = { 0.08, 0.18, 0.20, 0.98 },
    button = { 0.105, 0.115, 0.125, 1 },
    buttonHover = { 0.13, 0.15, 0.16, 1 },
    buttonPushed = { 0.06, 0.15, 0.17, 1 },
    buttonDisabled = { 0.06, 0.065, 0.07, 0.85 },
    input = { 0.045, 0.05, 0.055, 1 },
    border = { 0, 0, 0, 1 },
    borderBright = { 0.19, 0.33, 0.36, 1 },
    accent = { 0.12, 0.78, 0.82, 1 },
    text = { 0.88, 0.90, 0.90, 1 },
    textDisabled = { 0.45, 0.48, 0.48, 1 },
}

UI.colors = colors

local function SetTextureColor(texture, color)
    texture:SetColorTexture(color[1], color[2], color[3], color[4])
end

local function HideFrameTextures(frame)
    for _, region in ipairs({ frame:GetRegions() }) do
        if region.GetObjectType and region:GetObjectType() == "Texture" then
            region:SetAlpha(0)
        end
    end
end

local function CreateBorder(parent, inset)
    inset = inset or 0

    local border = {
        top = parent:CreateTexture(nil, "BORDER"),
        bottom = parent:CreateTexture(nil, "BORDER"),
        left = parent:CreateTexture(nil, "BORDER"),
        right = parent:CreateTexture(nil, "BORDER"),
    }

    border.top:SetPoint("TOPLEFT", inset, -inset)
    border.top:SetPoint("TOPRIGHT", -inset, -inset)
    border.top:SetHeight(1)
    border.bottom:SetPoint("BOTTOMLEFT", inset, inset)
    border.bottom:SetPoint("BOTTOMRIGHT", -inset, inset)
    border.bottom:SetHeight(1)
    border.left:SetPoint("TOPLEFT", inset, -inset)
    border.left:SetPoint("BOTTOMLEFT", inset, inset)
    border.left:SetWidth(1)
    border.right:SetPoint("TOPRIGHT", -inset, -inset)
    border.right:SetPoint("BOTTOMRIGHT", -inset, inset)
    border.right:SetWidth(1)

    return border
end

function UI:ColorBorder(border, color)
    for _, texture in pairs(border) do
        SetTextureColor(texture, color)
    end
end

function UI:SkinBox(frame, color, borderColor, inset)
    if not frame.wmlBg then
        frame.wmlBg = frame:CreateTexture(nil, "BACKGROUND")
        frame.wmlBg:SetPoint("TOPLEFT", inset or 0, -(inset or 0))
        frame.wmlBg:SetPoint("BOTTOMRIGHT", -(inset or 0), inset or 0)
        frame.wmlBorder = CreateBorder(frame, inset)
    end

    SetTextureColor(frame.wmlBg, color)
    self:ColorBorder(frame.wmlBorder, borderColor or colors.border)
end

function UI:SetBackdrop(frame, color, borderColor)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(color[1], color[2], color[3], color[4])
    borderColor = borderColor or colors.border
    frame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
end

function UI:StyleButton(button)
    if button.wmlStyled then
        return
    end

    button.wmlStyled = true
    HideFrameTextures(button)
    self:SkinBox(button, colors.button, colors.border)
    button:SetNormalFontObject("GameFontNormal")
    button:SetHighlightFontObject("GameFontHighlight")

    local fontString = button:GetFontString()
    if fontString then
        fontString:SetTextColor(colors.text[1], colors.text[2], colors.text[3], colors.text[4])
    end

    button:HookScript("OnEnter", function(control)
        if control:IsEnabled() then
            UI:SkinBox(control, colors.buttonHover, colors.borderBright)
        end
    end)
    button:HookScript("OnLeave", function(control)
        UI:SkinBox(control, control:IsEnabled() and colors.button or colors.buttonDisabled, colors.border)
    end)
    button:HookScript("OnMouseDown", function(control)
        if control:IsEnabled() then
            UI:SkinBox(control, colors.buttonPushed, colors.accent)
        end
    end)
    button:HookScript("OnMouseUp", function(control)
        UI:SkinBox(control, control:IsEnabled() and colors.buttonHover or colors.buttonDisabled, colors.border)
    end)
end

function UI:StyleEditBox(editBox)
    HideFrameTextures(editBox)
    self:SkinBox(editBox, colors.input, colors.border)

    if editBox.SetTextInsets then
        editBox:SetTextInsets(6, 6, 0, 0)
    end

    editBox:SetTextColor(colors.text[1], colors.text[2], colors.text[3], colors.text[4])
end

function UI:StyleDropdown(dropdown)
    HideFrameTextures(dropdown)
    self:SkinBox(dropdown, colors.input, colors.border, 4)

    local name = dropdown:GetName()
    local button = name and _G[name .. "Button"]
    if button then
        HideFrameTextures(button)
    end

    if not dropdown.wmlArrow then
        dropdown.wmlArrow = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        dropdown.wmlArrow:SetPoint("RIGHT", -22, 2)
        dropdown.wmlArrow:SetText("v")
    end
    dropdown.wmlArrow:SetTextColor(colors.text[1], colors.text[2], colors.text[3], colors.text[4])
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
