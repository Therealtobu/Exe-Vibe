-- ============================================================
--  UI_NowPlaying.lua  |  Exvibe Music Player  (v8)
--  - Square album art
--  - Frame-based Repeat icon (no broken unicode box)
--  - Semi-transparent ghost pill buttons (not solid black)
--  - Back button = plain "<" text, no background
--  - Control buttons: rounded pill shape, vertically centered
--  - Queue item clicks wired up
--  - Cover fly-to animation support
-- ============================================================

local E   = _G.Exvibe
local C   = E.COLORS
local UI  = E.UI
local UIS = game:GetService("UserInputService")

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

-- Strict square art, constrained by available height
local CONTENT_H = FH - PANEL_Y
local ART_PAD   = 20
-- Space needed below art: title+artist+gap+prog+time+ctrl+vol + margins ≈ 160
local BELOW_ART = 160
local ART_SIZE  = math.min(LEFT_W - ART_PAD, CONTENT_H - 14 - BELOW_ART - 10)
local ART_X     = math.floor((LEFT_W - ART_SIZE) / 2)  -- centered in left panel
local INFO_PAD  = math.max(10, ART_X)                  -- horizontal padding for text

-- Vertical positions (y from LeftPanel top)
local ART_Y    = 12
local TITLE_Y  = ART_Y + ART_SIZE + 14
local ARTIST_Y = TITLE_Y + 20
local PROG_Y   = ARTIST_Y + 19
local TIME_Y   = PROG_Y + 7
local CTRL_Y   = TIME_Y + 18
local VOL_Y    = CTRL_Y + 52

local LEFT_CX = math.floor(LEFT_W / 2)

-- Ghost pill colors
local GHOST_CLR   = Color3.fromRGB(180, 180, 200)
local GHOST_TRANS = 0.80     -- default: barely visible
local GHOST_PRESS = 0.60     -- slightly more opaque when toggled on

-- ============================================================
--  HELPER: Frame-based Repeat icon (circle + arrow)
--  Avoids ↻ rendering as a box in Roblox Gotham
-- ============================================================
local function makeRepeatIcon(parent, sz, color, zIdx)
    sz = sz or 34
    local th = math.max(2, math.floor(sz * 0.10))

    -- Circle ring (UIStroke on transparent rounded frame)
    local ring = Instance.new("Frame", parent)
    ring.Size             = UDim2.new(0, sz, 0, sz)
    ring.Position         = UDim2.new(0.5, -math.floor(sz/2), 0.5, -math.floor(sz/2))
    ring.BackgroundTransparency = 1
    ring.BorderSizePixel  = 0
    ring.ZIndex           = zIdx
    ring.ClipsDescendants = false
    Instance.new("UICorner", ring).CornerRadius = UDim.new(1, 0)
    local stroke = Instance.new("UIStroke", ring)
    stroke.Color     = color
    stroke.Thickness = th
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    -- Arrow head at top-right of circle  (▶ rotated)
    local arr = Instance.new("TextLabel", parent)
    arr.Size              = UDim2.new(0, math.floor(sz*0.38), 0, math.floor(sz*0.38))
    arr.Position          = UDim2.new(0.5, math.floor(sz*0.16), 0.5, -sz)
    arr.BackgroundTransparency = 1
    arr.Text              = "▶"
    arr.Font              = Enum.Font.GothamBold
    arr.TextSize          = math.floor(sz * 0.30)
    arr.TextColor3        = color
    arr.ZIndex            = zIdx + 1

    return ring, arr   -- return so caller can change color
end

-- ============================================================
--  HELPER: Ghost pill button (semi-transparent, not solid black)
-- ============================================================
local function makeGhostPill(parent, x, y, w, h, cornerR)
    local f = Instance.new("Frame", parent)
    f.Size             = UDim2.new(0, w, 0, h)
    f.Position         = UDim2.new(0, x, 0, y)
    f.BackgroundColor3 = GHOST_CLR
    f.BackgroundTransparency = GHOST_TRANS
    f.BorderSizePixel  = 0
    f.ZIndex           = 22
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, cornerR or math.floor(h * 0.45))
    return f
end

-- ============================================================
--  SHEET FRAME
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

-- ============================================================
--  DRAG HANDLE  (pill at top center)
-- ============================================================
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

-- ============================================================
--  VERTICAL DIVIDER
-- ============================================================
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

-- Album art — SQUARE (ART_SIZE x ART_SIZE)
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

-- Title (more space below art)
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

-- Artist
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

-- Progress bar
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

-- Time labels
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
--  PLAYBACK CONTROLS  — pill-shaped, centered, vertically aligned
-- ============================================================
local CTRL_BTN_H  = 42   -- prev/next height
local CTRL_PLAY_H = 50   -- play/pause height
local CTRL_CY     = CTRL_Y + math.floor(CTRL_PLAY_H / 2)  -- common center Y

local function makeCtrlPill(icon, cx, btnW, btnH, tsize)
    local pill = makeGhostPill(
        LeftPanel,
        cx - math.floor(btnW/2),
        CTRL_CY - math.floor(btnH/2),
        btnW, btnH,
        math.floor(btnH * 0.45)
    )

    local b = Instance.new("TextButton", pill)
    b.Size                  = UDim2.new(1,0,1,0)
    b.BackgroundTransparency = 1
    b.AutoButtonColor       = false
    b.Text                  = icon
    b.TextColor3            = C.text
    b.Font                  = Enum.Font.GothamBold
    b.TextSize              = tsize
    b.ZIndex                = 23

    -- Subtle press feedback
    b.MouseButton1Down:Connect(function()
        pill.BackgroundTransparency = GHOST_PRESS - 0.1
    end)
    b.MouseButton1Up:Connect(function()
        pill.BackgroundTransparency = GHOST_TRANS
    end)

    return b
end

local NPBtnPrev = makeCtrlPill("◀◀", LEFT_CX - 58, 46, CTRL_BTN_H,  14)
local NPBtnPlay = makeCtrlPill("▶",  LEFT_CX,       54, CTRL_PLAY_H, 24)
local NPBtnNext = makeCtrlPill("▶▶", LEFT_CX + 58,  46, CTRL_BTN_H,  14)

-- ============================================================
--  VOLUME ROW  ( -  ████░░  + )
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

-- Store refs
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

-- Volume drag
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

-- Back button: plain "<" text, no background, large
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

-- Repeat button: frame-based loop icon inside a ghost pill
local TOGGLE_W = math.floor((RIGHT_W - 44) * 0.49)
local TOGGLE_H = 36
local TOGGLE_CR = 18

-- Repeat pill
local repPill = makeGhostPill(RightPanel,
    44, 0,
    TOGGLE_W, TOGGLE_H, TOGGLE_CR)
repPill.Name = "RepeatPill"

-- Repeat icon drawn inside the pill (frame-based, no broken unicode)
local ICON_SZ = 20
local repRing, repArr = makeRepeatIcon(repPill, ICON_SZ, GHOST_CLR, 23)
-- position the icon inside the pill (centered)
repRing.Position = UDim2.new(0.5, -math.floor(ICON_SZ/2), 0.5, -math.floor(ICON_SZ/2))
repArr.Position  = UDim2.new(0.5, math.floor(ICON_SZ*0.16), 0.5, -ICON_SZ)

local NPRepeatBtn = Instance.new("TextButton", repPill)
NPRepeatBtn.Size              = UDim2.new(1,0,1,0)
NPRepeatBtn.BackgroundTransparency = 1
NPRepeatBtn.AutoButtonColor   = false
NPRepeatBtn.Text              = ""
NPRepeatBtn.ZIndex            = 24

-- Shuffle pill  (⇌ works in Roblox Gotham)
local shuPill = makeGhostPill(RightPanel,
    44 + TOGGLE_W + 6, 0,
    TOGGLE_W, TOGGLE_H, TOGGLE_CR)
shuPill.Name = "ShufflePill"
local shuIcon = Instance.new("TextLabel", shuPill)
shuIcon.Size              = UDim2.new(1,0,1,0)
shuIcon.BackgroundTransparency = 1
shuIcon.Text              = "⇌"
shuIcon.Font              = Enum.Font.GothamBold
shuIcon.TextSize          = 20
shuIcon.TextColor3        = GHOST_CLR
shuIcon.ZIndex            = 23

local NPShuffleBtn = Instance.new("TextButton", shuPill)
NPShuffleBtn.Size              = UDim2.new(1,0,1,0)
NPShuffleBtn.BackgroundTransparency = 1
NPShuffleBtn.AutoButtonColor   = false
NPShuffleBtn.Text              = ""
NPShuffleBtn.ZIndex            = 24

UI.NPRepeatBtn  = NPRepeatBtn
UI.NPShuffleBtn = NPShuffleBtn
UI.repPill      = repPill
UI.repRing      = repRing
UI.repArr       = repArr
UI.shuPill      = shuPill
UI.shuIcon      = shuIcon

-- Toggle state helpers
local function setRepeatVisual(on)
    local clr = on and C.accentBlue or GHOST_CLR
    repPill.BackgroundTransparency = on and GHOST_PRESS or GHOST_TRANS
    repPill.BackgroundColor3       = on and C.accentBlue or GHOST_CLR
    local stroke = repRing:FindFirstChildWhichIsA("UIStroke")
    if stroke then stroke.Color = on and Color3.new(1,1,1) or GHOST_CLR end
    repArr.TextColor3 = on and Color3.new(1,1,1) or GHOST_CLR
end

local function setShuffleVisual(on)
    shuPill.BackgroundTransparency = on and GHOST_PRESS or GHOST_TRANS
    shuPill.BackgroundColor3       = on and C.accentBlue or GHOST_CLR
    shuIcon.TextColor3             = on and Color3.new(1,1,1) or GHOST_CLR
end

setRepeatVisual(false)
setShuffleVisual(false)

-- Wire toggles
NPRepeatBtn.MouseButton1Click:Connect(function()
    E.State.repeatOn = not E.State.repeatOn
    setRepeatVisual(E.State.repeatOn)
end)
NPShuffleBtn.MouseButton1Click:Connect(function()
    E.State.shuffleOn = not E.State.shuffleOn
    setShuffleVisual(E.State.shuffleOn)
end)

-- "Continue Playing" header
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

-- Queue scroll list
local QUEUE_TOP = TOGGLE_H + 50
local QueueScroll = Instance.new("ScrollingFrame", RightPanel)
QueueScroll.Size             = UDim2.new(1,0,1,-QUEUE_TOP-44)
QueueScroll.Position         = UDim2.new(0,0,0,QUEUE_TOP)
QueueScroll.BackgroundTransparency = 1
QueueScroll.BorderSizePixel  = 0
QueueScroll.ScrollBarThickness = 2
QueueScroll.ScrollBarImageColor3 = C.border
QueueScroll.CanvasSize       = UDim2.new(0,0,0,0)
QueueScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
QueueScroll.ZIndex           = 22
UI.QueueScroll = QueueScroll

local QLayout = Instance.new("UIListLayout", QueueScroll)
QLayout.Padding   = UDim.new(0,4)
QLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Queue item builder — click wired up via E.playSong
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

    -- Hover
    item.MouseEnter:Connect(function()
        item.BackgroundColor3 = C.card
        E.tween(item, {BackgroundTransparency = 0.86}, 0.1)
    end)
    item.MouseLeave:Connect(function()
        E.tween(item, {BackgroundTransparency = 1}, 0.1)
    end)

    -- Click → play song + fly animation (NowPlaying already open)
    item.MouseButton1Click:Connect(function()
        if E.playSong then
            -- Capture thumb position before anything changes
            local fromPos = thumb.AbsolutePosition
            local fromSz  = thumb.AbsoluteSize
            E.playSong(song)
            -- Fly from queue thumbnail to album art
            if E.animateCoverFly then
                E.animateCoverFly(fromPos, fromSz, song, true)
            end
        end
    end)

    return item
end

-- Build / rebuild queue
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

-- Bottom action buttons
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
--  OPEN / CLOSE ANIMATIONS
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
    UI.NPBtnPlay.Text = E.State.isPlaying and "▌▌" or "▶"
    E.State.nowPlayingOpen = true
    Sheet.Visible = true
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

-- Back button closes sheet
NPBackBtn.MouseButton1Click:Connect(E.closeNowPlaying)

print("[Exvibe] UI_NowPlaying loaded")
