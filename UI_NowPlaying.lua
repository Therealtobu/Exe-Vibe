-- ============================================================
--  UI_NowPlaying.lua  |  Exvibe Music Player  (v8.2)
--  Changes:
--  - No blur/ghost pill behind Prev/Play/Next buttons
--  - All 5 icons replaced with Roblox asset IDs
--  - Repeat/Shuffle toggle: more opaque when on, NOT blue
--  - openNowPlaying guards against re-slide when already open
--    → fixes animation stutter + enables smooth bg transition
--  - BELOW_ART increased to prevent bottom overflow
-- ============================================================

local E   = _G.Exvibe
local C   = E.COLORS
local UI  = E.UI
local UIS = game:GetService("UserInputService")

-- ============================================================
--  ASSET IDs
-- ============================================================
local ASSET_PAUSE   = "rbxassetid://72396954315758"
local ASSET_PLAY    = "rbxassetid://81905914153409"
local ASSET_PREV    = "rbxassetid://72693785960426"
local ASSET_NEXT    = "rbxassetid://111765560089071"
local ASSET_SHUFFLE = "rbxassetid://74222790776317"
local ASSET_REPEAT  = "rbxassetid://71635659455113"

-- ============================================================
--  DYNAMIC SIZING
-- ============================================================
local FW = E.FRAME_W or 760
local FH = E.FRAME_H or 470

local LEFT_X    = 20
local LEFT_W    = math.floor(FW * 0.43)
local PANEL_Y   = 22
local DIVIDER_X = LEFT_X + LEFT_W + 12
local RIGHT_X   = DIVIDER_X + 10
local RIGHT_W   = FW - RIGHT_X - 16

local CONTENT_H = FH - PANEL_Y
local ART_PAD   = 20
local BELOW_ART = 200   -- increased buffer to prevent bottom clip
local ART_SIZE  = math.min(LEFT_W - ART_PAD, CONTENT_H - 14 - BELOW_ART - 10)
local ART_X     = math.floor((LEFT_W - ART_SIZE) / 2)
local INFO_PAD  = math.max(10, ART_X)

local ART_Y    = 12
local TITLE_Y  = ART_Y + ART_SIZE + 14
local ARTIST_Y = TITLE_Y + 20
local PROG_Y   = ARTIST_Y + 19
local TIME_Y   = PROG_Y + 7
local CTRL_Y   = TIME_Y + 18
local VOL_Y    = CTRL_Y + 52

local LEFT_CX = math.floor(LEFT_W / 2)

-- Toggle opacity (no color change)
local TOGGLE_CLR       = Color3.fromRGB(180, 180, 200)
local TOGGLE_TRANS_OFF = 0.50   -- was 0.82 (too transparent, pills invisible)
local TOGGLE_TRANS_ON  = 0.28

-- ============================================================
--  SHEET
-- ============================================================
local Sheet = Instance.new("Frame", UI.MainFrame)
Sheet.Name             = "NowPlayingSheet"
Sheet.Size             = UDim2.new(1,0,1,0)
Sheet.Position         = UDim2.new(0,0,1,0)
Sheet.BackgroundColor3 = C.nowPlayBg
Sheet.BorderSizePixel  = 0
Sheet.ClipsDescendants = true
Sheet.Visible          = false
Sheet.ZIndex           = 20
Instance.new("UICorner", Sheet).CornerRadius = UDim.new(0,18)
UI.NowPlaying = Sheet

local DragHandle = Instance.new("Frame", Sheet)
DragHandle.Size             = UDim2.new(0,44,0,5)
DragHandle.Position         = UDim2.new(0.5,-22,0,8)
DragHandle.BackgroundColor3 = C.pill
DragHandle.BorderSizePixel  = 0
DragHandle.ZIndex           = 21
Instance.new("UICorner", DragHandle).CornerRadius = UDim.new(1,0)

local DragHit = Instance.new("TextButton", Sheet)
DragHit.Size             = UDim2.new(1,0,0,24)
DragHit.Position         = UDim2.new(0,0,0,0)
DragHit.BackgroundTransparency = 1
DragHit.Text             = ""
DragHit.ZIndex           = 22

local Divider = Instance.new("Frame", Sheet)
Divider.Size             = UDim2.new(0,1,1,-48)
Divider.Position         = UDim2.new(0,DIVIDER_X,0,24)
Divider.BackgroundColor3 = C.border
Divider.BorderSizePixel  = 0
Divider.ZIndex           = 21

-- ============================================================
--  LEFT PANEL
-- ============================================================
local LeftPanel = Instance.new("Frame", Sheet)
LeftPanel.Size             = UDim2.new(0,LEFT_W,1,-PANEL_Y)
LeftPanel.Position         = UDim2.new(0,LEFT_X,0,PANEL_Y)
LeftPanel.BackgroundTransparency = 1
LeftPanel.ZIndex           = 21

local NPArt = Instance.new("ImageLabel", LeftPanel)
NPArt.Name             = "NPArt"
NPArt.Size             = UDim2.new(0, ART_SIZE, 0, ART_SIZE)
NPArt.Position         = UDim2.new(0, ART_X, 0, ART_Y)
NPArt.BackgroundColor3 = C.card
NPArt.BorderSizePixel  = 0
NPArt.ScaleType        = Enum.ScaleType.Crop
NPArt.ZIndex           = 22
Instance.new("UICorner", NPArt).CornerRadius = UDim.new(0,14)
local ArtStroke = Instance.new("UIStroke", NPArt)
ArtStroke.Color     = C.border
ArtStroke.Thickness = 1.5
ArtStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local NPTitle = Instance.new("TextLabel", LeftPanel)
NPTitle.Size             = UDim2.new(1,-INFO_PAD*2,0,20)
NPTitle.Position         = UDim2.new(0,INFO_PAD,0,TITLE_Y)
NPTitle.BackgroundTransparency = 1
NPTitle.Text             = "Not Playing"
NPTitle.TextColor3       = C.text
NPTitle.Font             = Enum.Font.GothamBold
NPTitle.TextSize         = 16
NPTitle.TextXAlignment   = Enum.TextXAlignment.Left
NPTitle.TextTruncate     = Enum.TextTruncate.AtEnd
NPTitle.ZIndex           = 22

local NPArtist = Instance.new("TextLabel", LeftPanel)
NPArtist.Size             = UDim2.new(1,-INFO_PAD*2,0,14)
NPArtist.Position         = UDim2.new(0,INFO_PAD,0,ARTIST_Y)
NPArtist.BackgroundTransparency = 1
NPArtist.Text             = "-"
NPArtist.TextColor3       = C.subText
NPArtist.Font             = Enum.Font.Gotham
NPArtist.TextSize         = 12
NPArtist.TextXAlignment   = Enum.TextXAlignment.Left
NPArtist.ZIndex           = 22

local NPProgBg = Instance.new("Frame", LeftPanel)
NPProgBg.Size             = UDim2.new(1,-INFO_PAD*2,0,4)
NPProgBg.Position         = UDim2.new(0,INFO_PAD,0,PROG_Y)
NPProgBg.BackgroundColor3 = Color3.fromRGB(70,70,84)
NPProgBg.BorderSizePixel  = 0
NPProgBg.ZIndex           = 22
Instance.new("UICorner", NPProgBg).CornerRadius = UDim.new(1,0)

local NPProgFill = Instance.new("Frame", NPProgBg)
NPProgFill.Size             = UDim2.new(0,0,1,0)
NPProgFill.BackgroundColor3 = C.accent
NPProgFill.BorderSizePixel  = 0
NPProgFill.ZIndex           = 23
Instance.new("UICorner", NPProgFill).CornerRadius = UDim.new(1,0)

local NPProgDot = Instance.new("Frame", NPProgBg)
NPProgDot.Size             = UDim2.new(0,12,0,12)
NPProgDot.Position         = UDim2.new(0,-6,0.5,-6)
NPProgDot.BackgroundColor3 = Color3.new(1,1,1)
NPProgDot.BorderSizePixel  = 0
NPProgDot.ZIndex           = 24
Instance.new("UICorner", NPProgDot).CornerRadius = UDim.new(1,0)

local NPTimeCurrent = Instance.new("TextLabel", LeftPanel)
NPTimeCurrent.Size             = UDim2.new(0,44,0,13)
NPTimeCurrent.Position         = UDim2.new(0,INFO_PAD,0,TIME_Y)
NPTimeCurrent.BackgroundTransparency = 1
NPTimeCurrent.Text             = "0:00"
NPTimeCurrent.TextColor3       = C.subText
NPTimeCurrent.Font             = Enum.Font.Gotham
NPTimeCurrent.TextSize         = 11
NPTimeCurrent.TextXAlignment   = Enum.TextXAlignment.Left
NPTimeCurrent.ZIndex           = 22

local NPTimeTotal = Instance.new("TextLabel", LeftPanel)
NPTimeTotal.Size             = UDim2.new(0,44,0,13)
NPTimeTotal.Position         = UDim2.new(1,-INFO_PAD-44,0,TIME_Y)
NPTimeTotal.BackgroundTransparency = 1
NPTimeTotal.Text             = "0:00"
NPTimeTotal.TextColor3       = C.subText
NPTimeTotal.Font             = Enum.Font.Gotham
NPTimeTotal.TextSize         = 11
NPTimeTotal.TextXAlignment   = Enum.TextXAlignment.Right
NPTimeTotal.ZIndex           = 22

-- ============================================================
--  PLAYBACK CONTROLS — asset image buttons, NO ghost pill
-- ============================================================
local CTRL_BTN_H  = 42
local CTRL_PLAY_H = 50
local CTRL_CY     = CTRL_Y + math.floor(CTRL_PLAY_H / 2)

local function makeCtrlImgBtn(assetId, cx, btnW, btnH)
    local hit = Instance.new("TextButton", LeftPanel)
    hit.Size                   = UDim2.new(0, btnW, 0, btnH)
    hit.Position               = UDim2.new(0, cx - math.floor(btnW/2), 0, CTRL_CY - math.floor(btnH/2))
    hit.BackgroundTransparency = 1
    hit.Text                   = ""
    hit.AutoButtonColor        = false
    hit.ZIndex                 = 22

    local img = Instance.new("ImageLabel", hit)
    img.Name                   = "Icon"
    img.Size                   = UDim2.new(1,0,1,0)
    img.BackgroundTransparency = 1
    img.Image                  = assetId
    img.ImageColor3            = C.text
    img.ZIndex                 = 23

    hit.MouseButton1Down:Connect(function()
        E.tween(img, {ImageTransparency = 0.45}, 0.07)
    end)
    hit.MouseButton1Up:Connect(function()
        E.tween(img, {ImageTransparency = 0}, 0.12)
    end)

    return hit, img
end

local NPBtnPrev, _prevImg     = makeCtrlImgBtn(ASSET_PREV,  LEFT_CX - 58, 46, CTRL_BTN_H)
local NPBtnPlay, NPBtnPlayImg = makeCtrlImgBtn(ASSET_PAUSE, LEFT_CX,      54, CTRL_PLAY_H)
local NPBtnNext, _nextImg     = makeCtrlImgBtn(ASSET_NEXT,  LEFT_CX + 58, 46, CTRL_BTN_H)

-- Text fallback: shows when asset image hasn't loaded (image child renders on top when loaded)
NPBtnPrev.Text       = "◀◀"
NPBtnPrev.Font       = Enum.Font.GothamBold
NPBtnPrev.TextSize   = 14
NPBtnPrev.TextColor3 = C.text
NPBtnNext.Text       = "▶▶"
NPBtnNext.Font       = Enum.Font.GothamBold
NPBtnNext.TextSize   = 14
NPBtnNext.TextColor3 = C.text

-- Play/pause state:
--   Playing  → pause image visible,  text = ""
--   Paused   → play image visible,   text = ""
NPBtnPlay.Font       = Enum.Font.GothamBold
NPBtnPlay.TextSize   = 22
NPBtnPlay.TextColor3 = C.text
NPBtnPlayImg.Visible = false   -- default: not playing (pause icon hidden)
NPBtnPlay.Text       = ""

-- Play/resume image (shown when paused)
local NPBtnPlayResumeImg = Instance.new("ImageLabel", NPBtnPlay)
NPBtnPlayResumeImg.Name                   = "ResumeIcon"
NPBtnPlayResumeImg.Size                   = UDim2.new(1,0,1,0)
NPBtnPlayResumeImg.BackgroundTransparency = 1
NPBtnPlayResumeImg.Image                  = ASSET_PLAY
NPBtnPlayResumeImg.ImageColor3            = C.text
NPBtnPlayResumeImg.ZIndex                 = 24
NPBtnPlayResumeImg.Visible                = true   -- default: show play icon
UI.NPBtnPlayResumeImg = NPBtnPlayResumeImg

UI.NPBtnPlayImg = NPBtnPlayImg   -- Controls.lua uses this

-- ============================================================
--  VOLUME ROW
-- ============================================================
local NPVolLow = Instance.new("TextLabel", LeftPanel)
NPVolLow.Size             = UDim2.new(0,18,0,18)
NPVolLow.Position         = UDim2.new(0,INFO_PAD-2,0,VOL_Y)
NPVolLow.BackgroundTransparency = 1
NPVolLow.Text             = "-"
NPVolLow.TextSize         = 18
NPVolLow.Font             = Enum.Font.GothamBold
NPVolLow.TextColor3       = C.subText
NPVolLow.ZIndex           = 22

local NPVolBg = Instance.new("Frame", LeftPanel)
NPVolBg.Size             = UDim2.new(1,-INFO_PAD*2-42,0,4)
NPVolBg.Position         = UDim2.new(0,INFO_PAD+22,0,VOL_Y+7)
NPVolBg.BackgroundColor3 = Color3.fromRGB(70,70,84)
NPVolBg.BorderSizePixel  = 0
NPVolBg.ZIndex           = 22
Instance.new("UICorner", NPVolBg).CornerRadius = UDim.new(1,0)

local NPVolFill = Instance.new("Frame", NPVolBg)
NPVolFill.Size             = UDim2.new(E.State.volume or 0.8, 0, 1, 0)
NPVolFill.BackgroundColor3 = C.accent
NPVolFill.BorderSizePixel  = 0
NPVolFill.ZIndex           = 23
Instance.new("UICorner", NPVolFill).CornerRadius = UDim.new(1,0)

local NPVolHigh = Instance.new("TextLabel", LeftPanel)
NPVolHigh.Size             = UDim2.new(0,18,0,18)
NPVolHigh.Position         = UDim2.new(1,-INFO_PAD-16,0,VOL_Y)
NPVolHigh.BackgroundTransparency = 1
NPVolHigh.Text             = "+"
NPVolHigh.TextSize         = 18
NPVolHigh.Font             = Enum.Font.GothamBold
NPVolHigh.TextColor3       = C.subText
NPVolHigh.ZIndex           = 22

UI.NPArt         = NPArt
UI.NPTitle       = NPTitle
UI.NPArtist      = NPArtist
UI.NPProgFill    = NPProgFill
UI.NPProgBg      = NPProgBg
UI.NPProgDot     = NPProgDot
UI.NPTimeCurrent = NPTimeCurrent
UI.NPTimeTotal   = NPTimeTotal
UI.NPBtnPrev     = NPBtnPrev
UI.NPBtnPlay     = NPBtnPlay
UI.NPBtnNext     = NPBtnNext
UI.NPVolFill     = NPVolFill
UI.NPVolBg       = NPVolBg

local npVolDrag = false
NPVolBg.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then npVolDrag = true end
end)
UIS.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then npVolDrag = false end
end)
UIS.InputChanged:Connect(function(inp)
    if not npVolDrag then return end
    if inp.UserInputType == Enum.UserInputType.MouseMovement then
        local mx   = UIS:GetMouseLocation().X
        local bx   = NPVolBg.AbsolutePosition.X
        local bw   = NPVolBg.AbsoluteSize.X
        local frac = math.clamp((mx - bx) / bw, 0, 1)
        E.Engine:setVolume(frac)
        NPVolFill.Size = UDim2.new(frac, 0, 1, 0)
    end
end)

-- ============================================================
--  RIGHT PANEL
-- ============================================================
local RightPanel = Instance.new("Frame", Sheet)
RightPanel.Size             = UDim2.new(0,RIGHT_W,1,-PANEL_Y)
RightPanel.Position         = UDim2.new(0,RIGHT_X,0,PANEL_Y)
RightPanel.BackgroundTransparency = 1
RightPanel.ZIndex           = 21

local NPBackBtn = Instance.new("TextButton", RightPanel)
NPBackBtn.Size              = UDim2.new(0,36,0,36)
NPBackBtn.Position          = UDim2.new(0,0,0,0)
NPBackBtn.BackgroundTransparency = 1
NPBackBtn.AutoButtonColor   = false
NPBackBtn.Text              = "<"
NPBackBtn.TextColor3        = C.text
NPBackBtn.Font              = Enum.Font.GothamBold
NPBackBtn.TextSize          = 26
NPBackBtn.ZIndex            = 22

-- ============================================================
--  REPEAT / SHUFFLE PILLS — image asset, opacity-only toggle
-- ============================================================
local TOGGLE_W  = math.floor((RIGHT_W - 44) * 0.49)
local TOGGLE_H  = 36
local TOGGLE_CR = 18

local function makeTogglePill(assetId, xOff)
    local pill = Instance.new("Frame", RightPanel)
    pill.Size                   = UDim2.new(0, TOGGLE_W, 0, TOGGLE_H)
    pill.Position               = UDim2.new(0, 44 + xOff, 0, 0)
    pill.BackgroundColor3       = TOGGLE_CLR
    pill.BackgroundTransparency = TOGGLE_TRANS_OFF
    pill.BorderSizePixel        = 0
    pill.ZIndex                 = 22
    Instance.new("UICorner", pill).CornerRadius = UDim.new(0, TOGGLE_CR)

    local icon = Instance.new("ImageLabel", pill)
    icon.Size                   = UDim2.new(0, 28, 0, 28)
    icon.AnchorPoint            = Vector2.new(0.5, 0.5)
    icon.Position               = UDim2.new(0.5, 0, 0.5, 0)
    icon.BackgroundTransparency = 1
    icon.Image                  = assetId
    icon.ImageColor3            = C.text
    icon.ZIndex                 = 23

    local btn = Instance.new("TextButton", pill)
    btn.Size                    = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency  = 1
    btn.AutoButtonColor         = false
    btn.Text                    = ""
    btn.ZIndex                  = 24

    return pill, btn
end

local repPill, NPRepeatBtn  = makeTogglePill(ASSET_REPEAT,  0)
local shuPill, NPShuffleBtn = makeTogglePill(ASSET_SHUFFLE, TOGGLE_W + 6)
repPill.Name = "RepeatPill"
shuPill.Name = "ShufflePill"

UI.NPRepeatBtn  = NPRepeatBtn
UI.NPShuffleBtn = NPShuffleBtn
UI.repPill      = repPill
UI.shuPill      = shuPill

local function setRepeatVisual(on)
    repPill.BackgroundTransparency = on and TOGGLE_TRANS_ON or TOGGLE_TRANS_OFF
end
local function setShuffleVisual(on)
    shuPill.BackgroundTransparency = on and TOGGLE_TRANS_ON or TOGGLE_TRANS_OFF
end

setRepeatVisual(false)
setShuffleVisual(false)

NPRepeatBtn.MouseButton1Click:Connect(function()
    E.State.repeatOn = not E.State.repeatOn
    setRepeatVisual(E.State.repeatOn)
end)
NPShuffleBtn.MouseButton1Click:Connect(function()
    E.State.shuffleOn = not E.State.shuffleOn
    setShuffleVisual(E.State.shuffleOn)
end)

local CPHeader = Instance.new("TextLabel", RightPanel)
CPHeader.Size             = UDim2.new(1,0,0,18)
CPHeader.Position         = UDim2.new(0,0,0,TOGGLE_H+12)
CPHeader.BackgroundTransparency = 1
CPHeader.Text             = "Continue Playing"
CPHeader.TextColor3       = C.text
CPHeader.Font             = Enum.Font.GothamBold
CPHeader.TextSize         = 15
CPHeader.TextXAlignment   = Enum.TextXAlignment.Left
CPHeader.ZIndex           = 22

local CPSub = Instance.new("TextLabel", RightPanel)
CPSub.Size             = UDim2.new(1,0,0,13)
CPSub.Position         = UDim2.new(0,0,0,TOGGLE_H+32)
CPSub.BackgroundTransparency = 1
CPSub.Text             = "From Library"
CPSub.TextColor3       = C.subText
CPSub.Font             = Enum.Font.Gotham
CPSub.TextSize         = 11
CPSub.TextXAlignment   = Enum.TextXAlignment.Left
CPSub.ZIndex           = 22

local QUEUE_TOP = TOGGLE_H + 50
local QueueScroll = Instance.new("ScrollingFrame", RightPanel)
QueueScroll.Size             = UDim2.new(1,0,1,-QUEUE_TOP-44)
QueueScroll.Position         = UDim2.new(0,0,0,QUEUE_TOP)
QueueScroll.BackgroundTransparency = 1
QueueScroll.BorderSizePixel  = 0
QueueScroll.ScrollBarThickness = 2
QueueScroll.ScrollBarImageColor3 = C.border
QueueScroll.CanvasSize       = UDim2.new(0,0,0,0)
pcall(function() QueueScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y end)
QueueScroll.ZIndex           = 22
UI.QueueScroll = QueueScroll

local QLayout = Instance.new("UIListLayout", QueueScroll)
QLayout.Padding   = UDim.new(0,4)
QLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function makeQueueItem(song, order)
    local item = Instance.new("TextButton", QueueScroll)
    item.Size             = UDim2.new(1,-4,0,52)
    item.LayoutOrder      = order
    item.BackgroundTransparency = 1
    item.Text             = ""
    item.BorderSizePixel  = 0
    item.ZIndex           = 23

    local thumb = Instance.new("ImageLabel", item)
    thumb.Name             = "Thumb"
    thumb.Size             = UDim2.new(0,42,0,42)
    thumb.Position         = UDim2.new(0,0,0.5,-21)
    thumb.BackgroundColor3 = C.card
    thumb.BorderSizePixel  = 0
    thumb.Image            = song.cover or ""
    thumb.ScaleType        = Enum.ScaleType.Crop
    thumb.ZIndex           = 24
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(0,8)

    local tLbl = Instance.new("TextLabel", item)
    tLbl.Size             = UDim2.new(1,-56,0,17)
    tLbl.Position         = UDim2.new(0,50,0,8)
    tLbl.BackgroundTransparency = 1
    tLbl.Text             = song.title
    tLbl.TextColor3       = C.text
    tLbl.Font             = Enum.Font.GothamSemibold
    tLbl.TextSize         = 13
    tLbl.TextXAlignment   = Enum.TextXAlignment.Left
    tLbl.TextTruncate     = Enum.TextTruncate.AtEnd
    tLbl.ZIndex           = 24

    local aLbl = Instance.new("TextLabel", item)
    aLbl.Size             = UDim2.new(1,-56,0,13)
    aLbl.Position         = UDim2.new(0,50,0,27)
    aLbl.BackgroundTransparency = 1
    aLbl.Text             = song.artist
    aLbl.TextColor3       = C.subText
    aLbl.Font             = Enum.Font.Gotham
    aLbl.TextSize         = 11
    aLbl.TextXAlignment   = Enum.TextXAlignment.Left
    aLbl.ZIndex           = 24

    item.MouseEnter:Connect(function()
        item.BackgroundColor3 = C.card
        E.tween(item, {BackgroundTransparency = 0.86}, 0.1)
    end)
    item.MouseLeave:Connect(function()
        E.tween(item, {BackgroundTransparency = 1}, 0.1)
    end)

    item.MouseButton1Click:Connect(function()
        if E.playSong then
            local fromPos = thumb.AbsolutePosition
            local fromSz  = thumb.AbsoluteSize
            E.playSong(song)
            if E.animateCoverFly then
                E.animateCoverFly(fromPos, fromSz, song, true)
            end
        end
    end)

    return item
end

function E.buildQueue()
    for _, ch in ipairs(QueueScroll:GetChildren()) do
        if ch:IsA("GuiObject") then ch:Destroy() end
    end
    local startIdx = 1
    if E.State.currentSong then
        for i, s in ipairs(E.MusicDatabase) do
            if s.id == E.State.currentSong.id then startIdx = i + 1 break end
        end
    end
    local order = 1
    for i = startIdx, #E.MusicDatabase do
        makeQueueItem(E.MusicDatabase[i], order) ; order = order + 1
    end
    for i = 1, startIdx - 2 do
        makeQueueItem(E.MusicDatabase[i], order) ; order = order + 1
    end
end

E.buildQueue()

local function makeActionBtn(icon, xOff)
    local b = Instance.new("TextButton", RightPanel)
    b.Size             = UDim2.new(0,38,0,38)
    b.Position         = UDim2.new(0,xOff,1,-42)
    b.BackgroundTransparency = 1
    b.Text             = icon
    b.TextColor3       = C.subText
    b.Font             = Enum.Font.GothamBold
    b.TextSize         = 16
    b.ZIndex           = 22
    return b
end
makeActionBtn(">_",   0)
makeActionBtn("=+",  50)
makeActionBtn("...", 100)

-- ============================================================
--  OPEN / CLOSE
--  KEY FIX: if sheet already open, only update content (no re-slide).
--  This prevents animation stutter and enables smooth bg transition.
-- ============================================================
function E.openNowPlaying(song)
    if song then
        UI.NPArt.Image        = song.cover or ""
        UI.NPTitle.Text       = song.title
        UI.NPArtist.Text      = song.artist
        UI.NPTimeTotal.Text   = E.formatTime(song.duration)
        UI.NPTimeCurrent.Text = "0:00"
        UI.NPProgFill.Size    = UDim2.new(0,0,1,0)
        if UI.NPProgDot then
            UI.NPProgDot.Position = UDim2.new(0,-6,0.5,-6)
        end
        E.buildQueue()
    end

    -- Sync play/pause button
    local isPlaying = E.State.isPlaying
    UI.NPBtnPlayImg.Visible = isPlaying
    UI.NPBtnPlay.Text       = ""
    if UI.NPBtnPlayResumeImg then
        UI.NPBtnPlayResumeImg.Visible = not isPlaying
    end

    -- Already open → content updated, skip re-slide animation
    if E.State.nowPlayingOpen then return end

    E.State.nowPlayingOpen = true
    Sheet.Visible  = true
    Sheet.Position = UDim2.new(0,0,1,0)
    E.tween(Sheet, {Position = UDim2.new(0,0,0,0)}, 0.40, Enum.EasingStyle.Quint)
end

function E.closeNowPlaying()
    E.State.nowPlayingOpen = false
    local t = E.tween(Sheet, {Position = UDim2.new(0,0,1,0)}, 0.32, Enum.EasingStyle.Quint)
    t.Completed:Connect(function() Sheet.Visible = false end)
end

-- ============================================================
--  DRAG-DOWN TO DISMISS
-- ============================================================
local dragging, dragStartY = false, 0

DragHit.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = true ; dragStartY = inp.Position.Y
    end
end)
UIS.InputEnded:Connect(function(inp)
    if not dragging then return end
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = false
        if Sheet.Position.Y.Offset > 70 then
            E.closeNowPlaying()
        else
            E.tween(Sheet, {Position = UDim2.new(0,0,0,0)}, 0.22)
        end
    end
end)
UIS.InputChanged:Connect(function(inp)
    if not dragging then return end
    if inp.UserInputType == Enum.UserInputType.MouseMovement
    or inp.UserInputType == Enum.UserInputType.Touch then
        local delta = inp.Position.Y - dragStartY
        if delta > 0 then Sheet.Position = UDim2.new(0,0,0,delta) end
    end
end)

NPBackBtn.MouseButton1Click:Connect(E.closeNowPlaying)

print("[Exvibe] UI_NowPlaying loaded")
