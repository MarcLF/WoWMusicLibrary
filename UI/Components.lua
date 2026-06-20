local WML = SpotiWoW

local UI = WML.UI or {
    sidebarButtons = {},
    trackRows = {},
    dropdowns = {},
    selectedTargetPlaylistId = nil,
    trackPage = 1,
    pageSize = 50,
    filter = {
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
            UI:SkinBox(control, control.wmlActive and colors.rowActive or colors.buttonHover, colors.borderBright)
        end
    end)
    button:HookScript("OnLeave", function(control)
        if control.wmlActive then
            UI:SkinBox(control, colors.rowActive, colors.accent)
        else
            UI:SkinBox(control, control:IsEnabled() and colors.button or colors.buttonDisabled, colors.border)
        end
    end)
    button:HookScript("OnMouseDown", function(control)
        if control:IsEnabled() then
            UI:SkinBox(control, colors.buttonPushed, colors.accent)
        end
    end)
    button:HookScript("OnMouseUp", function(control)
        if control.wmlActive then
            UI:SkinBox(control, colors.rowActive, colors.accent)
        else
            UI:SkinBox(control, control:IsEnabled() and colors.buttonHover or colors.buttonDisabled, colors.border)
        end
    end)
end

function UI:SetButtonActive(button, active)
    if not button then
        return
    end

    button.wmlActive = active and true or false
    self:SkinBox(button, button.wmlActive and colors.rowActive or colors.button, button.wmlActive and colors.accent or colors.border)
end

function UI:StyleEditBox(editBox)
    HideFrameTextures(editBox)
    self:SkinBox(editBox, colors.input, colors.border)

    if editBox.SetTextInsets then
        editBox:SetTextInsets(6, 6, 0, 0)
    end

    editBox:SetTextColor(colors.text[1], colors.text[2], colors.text[3], colors.text[4])
end

function UI:SetDropdownText(dropdown, text)
    if dropdown and dropdown.text then
        dropdown.text:SetText(text)
    end
end

function UI:CloseDropdowns(except)
    for _, dropdown in ipairs(self.dropdowns) do
        if dropdown ~= except and dropdown.menu then
            dropdown.menu:Hide()
        end
    end
end

function UI:CreateDropdown(parent, width, getOptions)
    local dropdown = CreateFrame("Button", nil, parent, "BackdropTemplate")
    table.insert(self.dropdowns, dropdown)

    dropdown:SetSize(width, 28)
    dropdown.getOptions = getOptions
    self:SkinBox(dropdown, colors.input, colors.border)

    dropdown.text = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dropdown.text:SetPoint("LEFT", 10, 1)
    dropdown.text:SetPoint("RIGHT", -28, 1)
    dropdown.text:SetJustifyH("CENTER")
    dropdown.text:SetTextColor(colors.text[1], colors.text[2], colors.text[3], colors.text[4])

    dropdown.arrow = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dropdown.arrow:SetPoint("RIGHT", -12, 1)
    dropdown.arrow:SetText("v")
    dropdown.arrow:SetTextColor(colors.text[1], colors.text[2], colors.text[3], colors.text[4])

    dropdown:SetScript("OnClick", function(control)
        UI:ToggleDropdown(control)
    end)

    return dropdown
end

function UI:ToggleDropdown(dropdown)
    if not dropdown.menu then
        local menu = CreateFrame("Frame", nil, dropdown:GetParent() or UIParent, "BackdropTemplate")
        dropdown.menu = menu
        menu:SetFrameStrata("DIALOG")
        menu:SetClampedToScreen(true)
        menu:EnableMouse(true)
        self:SetBackdrop(menu, colors.panel, colors.borderBright)

        local scroll = CreateFrame("ScrollFrame", nil, menu, "UIPanelScrollFrameTemplate")
        dropdown.scroll = scroll
        scroll:SetPoint("TOPLEFT", 2, -2)
        scroll:SetPoint("BOTTOMRIGHT", -22, 2)
        self:StyleScrollBar(scroll)

        local content = CreateFrame("Frame", nil, scroll)
        dropdown.content = content
        scroll:SetScrollChild(content)

        menu:SetScript("OnMouseWheel", function(_, delta)
            local current = scroll:GetVerticalScroll()
            scroll:SetVerticalScroll(math.max(0, current - (delta * 72)))
        end)
    end

    if dropdown.menu:IsShown() then
        dropdown.menu:Hide()
        return
    end

    self:CloseDropdowns(dropdown)

    local options = dropdown.getOptions() or {}
    local rowHeight = 24
    local visibleRows = math.min(#options, 20)
    local hasScroll = #options > 20
    local width = dropdown:GetWidth()
    local height = math.max(1, visibleRows * rowHeight) + 4

    dropdown.menu:ClearAllPoints()
    dropdown.menu:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
    dropdown.menu:SetSize(width, height)
    dropdown.scroll:ClearAllPoints()
    dropdown.scroll:SetPoint("TOPLEFT", 2, -2)
    dropdown.scroll:SetPoint("BOTTOMRIGHT", hasScroll and -22 or -2, 2)
    dropdown.content:SetSize(width - (hasScroll and 24 or 4), math.max(1, #options * rowHeight))
    dropdown.scroll:SetVerticalScroll(0)

    for index, option in ipairs(options) do
        local row = dropdown.rows and dropdown.rows[index]
        if not row then
            dropdown.rows = dropdown.rows or {}
            row = CreateFrame("Button", nil, dropdown.content, "BackdropTemplate")
            dropdown.rows[index] = row
            row:SetHeight(rowHeight)
            row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            row.text:SetPoint("LEFT", 8, 0)
            row.text:SetPoint("RIGHT", -8, 0)
            row.text:SetJustifyH("LEFT")
        end

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", dropdown.content, "TOPLEFT", 0, -((index - 1) * rowHeight))
        row:SetPoint("RIGHT", dropdown.content, "RIGHT", 0, 0)
        row.text:SetText(option.text)
        row.text:SetTextColor(colors.text[1], colors.text[2], colors.text[3], colors.text[4])
        self:SetBackdrop(row, option.checked and colors.rowActive or colors.row, option.checked and colors.accent or colors.border)
        row:SetScript("OnClick", function()
            dropdown.menu:Hide()
            option.func()
        end)
        row:Show()
    end

    for index = #options + 1, #(dropdown.rows or {}) do
        dropdown.rows[index]:Hide()
    end

    local scrollBar = dropdown.scroll.ScrollBar
    if scrollBar then
        scrollBar:SetShown(hasScroll)
    end

    dropdown.menu:Show()
end

function UI:StyleScrollButton(button, text)
    if not button then
        return
    end

    HideFrameTextures(button)
    self:SkinBox(button, colors.button, colors.border)

    if not button.wmlText then
        button.wmlText = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        button.wmlText:SetPoint("CENTER", 0, 0)
    end

    button.wmlText:SetText(text)
    button.wmlText:SetTextColor(colors.text[1], colors.text[2], colors.text[3], colors.text[4])
end

function UI:StyleScrollBar(scroll)
    local name = scroll:GetName()
    local bar = scroll.ScrollBar or (name and _G[name .. "ScrollBar"])

    if not bar then
        return
    end

    HideFrameTextures(bar)
    self:SkinBox(bar, colors.input, colors.border)
    bar:SetWidth(18)

    local barName = bar.GetName and bar:GetName()
    local up = bar.ScrollUpButton or (barName and _G[barName .. "ScrollUpButton"])
    local down = bar.ScrollDownButton or (barName and _G[barName .. "ScrollDownButton"])
    self:StyleScrollButton(up, "")
    self:StyleScrollButton(down, "")

    local thumb = bar.ThumbTexture or (barName and _G[barName .. "ThumbTexture"])
    if thumb then
        thumb:SetTexture("Interface\\Buttons\\WHITE8x8")
        thumb:SetVertexColor(colors.accent[1], colors.accent[2], colors.accent[3], 0.85)
    end
end

function UI:SaveSize(frame)
    if not WML.db then
        return
    end

    WML.db.profile.window.width = frame:GetWidth()
    WML.db.profile.window.height = frame:GetHeight()
end

function UI:GetSidebarButton(index, parent, buttons)
    buttons = buttons or self.sidebarButtons
    parent = parent or self.sidebar

    local button = buttons[index]
    if button then
        return button
    end

    button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    buttons[index] = button
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
